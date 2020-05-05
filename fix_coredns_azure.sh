# Fix for CoreDNS running on an Azure Linux VM by Christof Schwarz
# the "forward" attribute in Corefile (configmap "coredns") cannot route
# entries like *.internal.cloudapp.net ... if such addresses are sent to 
# Google DNS servers like 8.8.8.8 or 8.8.4.4 they are not found.
# Solution: put Microsofts DNS in first place 168.63.129.16 ...
# https://docs.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16
kubectl get configmap coredns -n kube-system -o yaml >tmp_coredns.yaml
# insert the Azure DNS server as the first forward IP 
sed -i 's/forward . /forward . 168.63.129.16 /g' tmp_coredns.yaml
# in case this script is run twice, remove a duplicate entry of that IP address
sed -i 's/forward . 168.63.129.16 168.63.129.16 /forward . 168.63.129.16 /g' tmp_coredns.yaml
kubectl apply -f tmp_coredns.yaml
rm tmp_coredns.yaml
# Restart the coredns pod to pick up the change
kubectl delete pod -n kube-system -l k8s-app=kube-dns
# Show the new configmap after the change
kubectl describe cm -n kube-system -l k8s-app=kube-dns
