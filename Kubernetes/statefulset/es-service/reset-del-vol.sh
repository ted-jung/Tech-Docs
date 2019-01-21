for i in $(kubectl get pvc -n ted-namespace | awk 'NR>1 {print$1}')
do
  kubectl delete pvc $i -n ted-namespace
done

for i in {1..15}
do
  kubectl delete pv vol$i -n ted-namespace
done
