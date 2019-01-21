NAMESPACE="ted-namespace"
LIST=("3-es-master-svc.yaml" "3-es-master-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl delete -f $i -n $NAMESPACE
done
