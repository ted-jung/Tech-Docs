#!/bin/bash
NAMESPACE="ted-namespace"
LIST=("es-coor-svc.yaml" "es-coor-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl create -f $i -n $NAMESPACE
done
