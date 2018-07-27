# =============================================================================
# while this is not a help forum (use google groups or gitter for that), i've
# pasted an example working ES 6.1 nomad job file below
#
# It includes
# 3 master nodes (backed by rexray/ebs for persistent data)
# one in each AWS AZ in our region
# any number of data/search nodes
# fully dynamic ports
# both for rest and transport
# discovery through static files, maintained by template{}
# kibana configured to join the clusters
# proper prod required settings for ES 6 to run (requires nomad 0.7.1)
# proper shutdown signals, and proper timeouts for shutting down allocations
# xpack enabled
# =============================================================================

# =============================================================================
# Need to define variables
# NOMAD_REGION = the name of Region (i.g, DC1)
# NOMAD_JOB_NAME = the name of Job (i.g, ted)
# NOMAD_META_ES_CLUSTER_NAME = the name of cluster (ted-cluster)
# NOMAD_PORT_rest = container port (9200)
# NOMAD_HOST_PORT_rest = host port (9200)
# NOMAD_IP_rest = host IP
# NOMAD_GROUP_NAME = the name of node
# NOMAD_HOST_PORT_transport = host port(tcp) (9300)
# NOMAD_PORT_transport = container port(tcp) (9300)
# need to check constraint of each role (master, data, kibana)
# write priviledge on the volume, which be mounted into container
# =============================================================================

# =============================================================================
# Linux Environment
#    1. /etc/sysctl.config
#       vm.max_map_count=262144
#    2. sudo swapoff -a
#    3. volume ownership
# =============================================================================

job "es-cluster-job" {
  type        = "service"
  datacenters = ["akl_uat","mmh-uat"]

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

  # two kibana nodes  (1 per DC)
  group "es-cluster-kibana" {
    count = 2

    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "10m"
    }

    task "es-cluster-kibana" {
      driver       = "docker"
      kill_timeout = "60s"
      kill_signal  = "SIGTERM"

      config {
        image   = "artifactory.aa.com:5000/kibana:6.3.0"
        command = "kibana"

        # https://www.elastic.co/guide/en/kibana/current/settings.html
        # https://www.elastic.co/guide/en/kibana/current/settings-xpack-kb.html
        args = [
          "--elasticsearch.url=http://${NOMAD_JOB_NAME}.service.consul:80",
          "--server.host=0.0.0.0",
          "--server.name=${NOMAD_JOB_NAME}.service.consul",
          "--server.port=${NOMAD_PORT_http}",
          "--path.data=/alloc/data",
          "--elasticsearch.preserveHost=false",
          "--xpack.apm.ui.enabled=false",
          "--xpack.graph.enabled=false",
          "--xpack.ml.enabled=false",
        ]

        ulimit {
          memlock = "-1"
          nofile  = "65536"
          nproc   = "8192"
        }
      }

      service {
        name = "${NOMAD_JOB_NAME}-kibana"
        port = "http"
        tags = ["elastic-kibana1"]

        check {
          name     = "http-tcp"
          port     = "http"
          type     = "tcp"
          interval = "5s"
          timeout  = "4s"
        }

        check {
          name     = "http-http"
          type     = "http"
          port     = "http"
          path     = "/"
          interval = "5s"
          timeout  = "4s"
        }
      }

      resources {
        cpu    = 500
        memory = 4096
        network {
          mbits = 50
          port "http" {}
        }
      }
    }
  }
}