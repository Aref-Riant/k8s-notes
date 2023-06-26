# Purpose:
Accessing root shell to non-root containers on kubernetes is way harder that just running "kubectl exec"

# How it works:
it uses containerd containerID and runc to directly attach to container shell

# How to use:
```
wget https://github.com/Aref-Riant/k8s-notes/raw/main/shell/rootShell/rootShell.sh
chmod +x rootShell.sh
rootShell.sh podname namespace
```
