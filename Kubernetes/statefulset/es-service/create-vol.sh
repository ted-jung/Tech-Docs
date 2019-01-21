for i in {1}
do
  kubectl create -f pv-vol.yaml -n ted-namespace
done
