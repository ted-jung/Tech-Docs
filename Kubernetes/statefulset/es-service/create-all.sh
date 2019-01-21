NAMESPACE="ted-namespace"
LIST=("es-master-svc.yaml" "es-master-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl create -f $i -n $NAMESPACE
done

LIST=("es-coor-svc.yaml" "es-coor-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl create -f $i -n $NAMESPACE
done

LIST=("es-data-svc.yaml" "es-data-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl create -f $i -n $NAMESPACE
done
