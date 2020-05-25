# This launches Kubernetes dashboard on port 32000
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml
kubectl wait --for=condition=available --timeout=180s deployment/kubernetes-dashboard -n kubernetes-dashboard
kubectl port-forward --address 0.0.0.0 -n kubernetes-dashboard service/kubernetes-dashboard 32000:443 &
echo "----------------------------------------------------------------"
echo "Running in background mode. Feel free to press [Ctrl]+[C] to"
echo "leave foreground and return to prompt, dashboard will continue"
echo "to run. Use this token to authenticate in kubernetes-dashboard:"
kubectl describe $(kubectl -n kubernetes-dashboard get secret -o name|grep kubernetes-dashboard-token) -n kubernetes-dashboard|grep token:
echo "Processes (PID) are"
ps aux|grep kubernetes-dashboard|grep 32000:443|awk '{print $2}'
echo "----------------------------------------------------------------"
