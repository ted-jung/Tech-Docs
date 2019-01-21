NAMESPACE="ted-namespace"
LIST=("es-master-svc.yaml" "es-master-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl create -f $i -n $NAMESPACE
done
