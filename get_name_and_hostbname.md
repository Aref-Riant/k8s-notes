## get name and hostname of all nodes in cluster
kubectl get nodes -o custom-columns=HOSTNAME:.metadata.name,INTERNAL-IP:.status.addresses[0].address
