#!/bin/bash
NAMESPACE="ted-namespace"
LIST=("4-es-coor-svc.yaml" "4-es-coor-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl delete -f $i -n $NAMESPACE
done
