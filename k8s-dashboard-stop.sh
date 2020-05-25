# This shell script undeploys K8s Dashboard and stops background process
# that handled the port-forwarding
kill_pid=$(ps -aux|grep kubernetes-dashboard|grep 32000:443|awk '{print "kill " $2}')
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml
eval "$kill_pid"
echo "----------------------------------------------------------------"
echo "Removed kubernetes-dashboard and killed background process(es)"
echo $kill_pid
echo "----------------------------------------------------------------"
ps -aux|grep kubernetes-dashboard|grep 32000:443
