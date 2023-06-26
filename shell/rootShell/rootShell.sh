#usage: rootShell.sh podname namespace

echo ""
nodename=`kubectl get pod $1 -n $2 -o jsonpath="{.spec.nodeName}"`
containerid=`kubectl get pod $1 -n $2 -o jsonpath="{.status.containerStatuses[].containerID}" | sed 's,.*//,,'`

echo "Node Name: $nodename"
echo "Container ID: $containerid"
echo ""
echo "Run command below on $nodename:"
echo "runc --root /run/containerd/runc/k8s.io/ exec -t -u 0 $containerid"
