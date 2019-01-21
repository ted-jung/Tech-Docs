NAMESPACE="ted-namespace"
LIST=("5-es-data-svc.yaml" "5-es-data-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl delete -f $i -n $NAMESPACE
done
