#!/bin/bash

# delete every services=============================================
NAMESPACE="ted-namespace"
LIST=("es-data-svc.yaml" "es-data-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl delete -f $i -n $NAMESPACE
done

LIST=("es-master-svc.yaml" "es-master-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl delete -f $i -n $NAMESPACE
done

LIST=("es-coor-svc.yaml" "es-coor-stt.yaml")

for i in "${LIST[@]}"
do
  kubectl delete -f $i -n $NAMESPACE
done

# delete pvc, pv ===================================================
for i in $(kubectl get pvc -n ted-namespace | awk 'NR>1 {print$1}')
do
  kubectl delete pvc $i -n $NAMESPACE
done

for i in {1..15}
do
  kubectl delete pv vol$i -n $NAMESPACE
done
