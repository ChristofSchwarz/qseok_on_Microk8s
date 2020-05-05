
kubectl get configmap coredns -n kube-system -o yaml >tmp.yaml
# insert the Azure DNS server as the first forward IP 
sed -i 's/forward . /forward . 168.63.129.16 /g' tmp.yaml
# in case this script is run twice, remove a duplicate entry of that IP address
sed -i 's/forward . 168.63.129.16 168.63.129.16 /forward . 168.63.129.16 /g' tmp.yaml
kubectl apply -f tmp.yaml
# Restart the coredns pod to pick up the change
kubectl delete pod -n kube-system -l k8s-app=kube-dns
# Show the new configmap after the change
kubectl describe cm -n kube-system -l k8s-app=kube-dns
