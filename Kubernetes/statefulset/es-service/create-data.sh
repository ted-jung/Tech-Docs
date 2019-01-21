#!/bin/bash
NAMESPACE="ted-namespace"
LIST=("es-data-svc.yaml" "es-data-stt.yaml")
for i in "${LIST[@]}"
do
  kubectl create -f $i -n $NAMESPACE
done
