#!/bin/bash
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
