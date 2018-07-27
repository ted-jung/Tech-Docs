# =============================================================================
# DC: NSH
# Containers:
#     container#1 (master/data)
# Volumes (four volumes)
#     :data_vol, log_vol, cert_vol, snapshot_vol
# =============================================================================


job "nsh_es_cluster" {
  datacenters = ["nsh-uat"]
  type        = "service"

  constraint {
    operator = "distinct_hosts"
    value = "true"
  }

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "180s"
    healthy_deadline = "5m"
  }

  # Cluster Name (NOMAD_META_ES_CLUSTER_NAME)
  meta {
    ES_CLUSTER_NAME = "HA_CLUSTER"
  }

  # set master/data=true to make it in a single VM
  group "nsh_es_cluster_md" {
    count = 2
    restart {
      attempts = 2
      delay    = "10s"
      interval = "5m"
      mode     = "fail"
    }

    # best effort to move the existing elastic search data
    # the 5gig disk matches the volume.
    ephemeral_disk {
      size    = "5000"
      sticky  = true
      migrate = false
    }

    # user docker (configure data directory to have ownership)
    task "nsh_es_cluster-md" {
      driver = "docker"

      # the container will automatically drop permissions before starting elastic search
      # if this user not works cause some priviledge then replace to root for testing
      # but, have to fix the issue by infra team.
      user = "docker"           # root? or docker?

      # allow elastic search 5min to gracefully shut down
      # use SIGTERM to shut down elastic search
      kill_timeout = "300s"
      kill_signal = "SIGTERM"

      constraint {
         attribute = "${node.unique.name}"
      }

      # env for master/data container
      env {
        ZEN_HOSTS="[10.0.0.1,10.0.0.2,10.0.0.3]"
        MIN_MASTER="2"
        HOST_IP="10.100.0.54"
        ELASTIC_PASSWORD="h!e@a#l$t%h^"
        ELASTIC_WATCHER_EMAIL="ES-Watcher <NO_REPLY@aa.com>"
        HA_SMTP_HOST="app-smtp.aa.com"
        HA_SMTP_PORT="25"
        CERTS_DIR="/usr/share/elasticsearch"
      }

      # Interpolation: https://www.nomadproject.io/docs/runtime/interpolation.html
      # ENV start with NOMAD be interpolated by Consul&Nomad
      # ENV not start with NOMAD be declared above by operator
      config {
        dns_search_domains = ["service.akl-uat.consul","service.mmh-uat.consul"]
        dns_options = []
        interactive = true

        image   = "artifactory.aa.com:5000/elasticsearch:6.3.0"
        command = "elasticsearch"
        args = [
          "-Ebootstrap.memory_lock=true",                             # lock all JVM memory on startup
          "-Ecluster.name=${NOMAD_META_ES_CLUSTER_NAME}",             # name of the cluster - this must match between master and data nodes
          "-Ediscovery.zen.hosts_provider=${ZEN_HOSTS}",              # use a 'static' file if you are familiar with
          "-Ediscovery.zen.minimum_master_nodes=${MIN_MASTER}",       # min master nodes are required to form a healthy cluster
          "-Ehttp.port=${NOMAD_PORT_rest}",                           # HTTP port (originally port 9200) to listen on inside the container
          "-Ehttp.publish_port=${NOMAD_HOST_PORT_rest}",              # HTTP port (originally port 9200) on the host instance
          "-Enetwork.host=0.0.0.0",                                   # IP to listen on for all traffic
          "-Enetwork.publish_host=${HOST_IP}",                        # IP to broadcast to other elastic search nodes (this is a host IP, not container)
          "-Enode.data=true",                                         # node is allowed to store data
          "-Enode.master=true",                                       # node is allowed to be elected master
          "-Enode.max_local_storage_nodes=1",                         # to prevent more than one node from sharing the same data path
          "-Enode.name=${NOMAD_GROUP_NAME}[${NOMAD_ALLOC_INDEX}]",    # node name is defaulted to the allocation name
          "-Etransport.publish_port=${NOMAD_HOST_PORT_transport}",    # Transport port (originally port 9300) on the host instance
          "-Etransport.tcp.port=${NOMAD_PORT_transport}",             # Transport port (originally port 9300) inside the container
          "-Expack.license.self_generated.type=basic",                # use x-packs basic license (free)
          "-EELASTIC_PASSWORD=${ELASTIC_PASSWORD}",
          "-Expack.security.enabled=true",
          "-Expack.security.audit.enabled=true",
          "-Expack.security.audit.outputs=index",
          "-Expack.security.audit.index.settings.index.number_of_shards=1",
          "-Expack.security.audit.index.settings.index.number_of_replicas=1",
          "-Expack.security.http.ssl.enabled=true",
          "-Expack.security.transport.ssl.enabled=true",
          "-Expack.security.transport.ssl.verification_mode=certificate",
          "-Expack.ssl.certificate_authorities=${CERTS_DIR}/ca.crt",
          "-Expack.ssl.certificate=${CERTS_DIR}/es01.crt",
          "-Expack.ssl.key=${CERTS_DIR}/es01.key",
          "-Expack.notification.email.account.prod.profile=standard",
          "-Expack.notification.email.account.prod.email_defaults.from=${ELASTIC_WATCHER_EMAIL}",
          "-Expack.notification.email.account.prod.smtp.host=${HA_SMTP_HOST}",
          "-Expack.notification.email.account.prod.smtp.port=${HA_SMTP_PORT}",
          "-Expack.monitoring.collection.enabled=true",
          "-Expack.monitoring.enabled=true",
          "-Expack.monitoring.collection.enabled=true"
        ]

        ulimit {
          memlock = "-1"
          nofile  = "65536"
          nproc   = "8192"
        }

        # persistent data configuration
        volume_driver = "local"
        # these volumes are provisioned by infra team
        # separate disks for data/log each to distribute IO (if you have enough device)
        # snapshot should be shared location by all elstic nodes (nfs, S3, etc)
        volumes = [
          "/elastic/data/:/usr/share/elasticsearch/data",
          "/elastic/logs/:/usr/share/elasticsearch/logs",
          "/elastic/cert/:/usr/share/certs",
          "/elastic/snapshot/:/usr/share/shapshot"
        ]
      }

      # consul-template writing out the unicast hosts elastic search uses to discover its cluster peers
      template {
        # this path will automatically be symlinked to the right place in the container
        # elastic search automatically reload the file on change, so no signales needed
        # specifies the location where the resulting template should be rendered, relative to the task directory
        change_mode = "noop"
        data = <<EOF
{{- range service (printf "%s-discovery|passing" (env "NOMAD_JOB_NAME")) }}
{{ .Address }}:{{ .Port }}{{ end }}
EOF

        destination = "/local/unicast_hosts.txt"
      }

      # this consul service is used to discover unicast hosts (see above template{})
      service {
        name = "${NOMAD_JOB_NAME}-discovery"
        port = "transport"

        check {
          name     = "transport-tcp"
          port     = "transport"
          type     = "tcp"
          interval = "5s"
          timeout  = "4s"
        }
      }

      service {
        name = "${NOMAD_JOB_NAME}"
        port = "rest"
        tags = ["dd-elastic"]

        check {
          name     = "rest-tcp"
          port     = "rest"
          type     = "tcp"
          interval = "5s"
          timeout  = "4s"
        }

        check {
          name     = "rest-http"
          type     = "http"
          port     = "rest"
          path     = "/"
          interval = "5s"
          timeout  = "4s"
        }
      }

      # set bigger size if it is required
      # cpu - 500 (0.5 GHz)
      # heap mem - 16GB
      # network(master/data) - 1Gbit (1/10 of 10G)
      resources {
        cpu    = 1024
        memory = 16384
        network {
          mbits = 1000
          port "rest" {
            static = 9200
          }
          port "transport" {
            static = 9300
          }
        }
      }
    }
  }
}