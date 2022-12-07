# Backing up data from TopoLVM volume with rsync and restoring it back

## Scenario:

```
k get po
NAME                                                           READY   STATUS      RESTARTS       AGE
postgres-0                                                     1/1     Running     0              8m
```

I have a postgres-0 pod which is connected to data-postgres-0 PVC on topolvm:  
```
k get pvc
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
data-postgres-0   Bound    pvc-4a7e1471-65a8-4e1a-97d2-54b7c58cbcbf   1Gi        RWO            topolvm-provisioner   11m
```

PV name is:  
pvc-4a7e1471-65a8-4e1a-97d2-54b7c58cbcbf  
we will need it later  

# Backup  
first of all, i stop the pod by scaling down the STS controlling the pod:  
```
kubectl scale sts postgres --replicas=0
```

then, i need a pod the keep the volume mounted without changing it:  
vim pvc-reserve-pod.yaml  
```
apiVersion: v1
kind: Pod
metadata:
  name: pvc-reserve
spec:
  containers:
    - name: mypvcreserve
      image: "registry.k8s.io/busybox"
      volumeMounts:
      - mountPath: "/mnt/mypvc"
        name: mypvc
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: data-postgres-0

```

then:  
```
k create -f pvc-reserve-pod.yaml
```

now i need to find on which node is my pod placed:  
```
k get po -o wide
NAME                                                           READY   STATUS      RESTARTS       AGE   IP               NODE                        NOMINATED NODE   READINESS GATES
pvc-reserve                                                     1/1     Running     0              18m   10.10.10.4   k8s-w4   <none>           <none>
```

well, k8s-w4 it is  
on k8s-w4, run the command below to find where the colume is mounted:
```
lsblk | grep pvc-4a7e1471-65a8-4e1a-97d2-54b7c58cbcbf

└─topolvm-ca569c85--2d07--408b--a497--07d0a9e5ac5f 253:19   0    1G  0 lvm  /var/lib/kubelet/pods/077c38ac-f656-44ec-888b-3a5ba52173ae/volumes/kubernetes.io~csi/pvc-4a7e1471-65a8-4e1a-97d2-54b7c58cbcbf/mount

```  

/var/lib/kubelet/pods/077c38ac-f656-44ec-888b-3a5ba52173ae/volumes/kubernetes.io~csi/pvc-4a7e1471-65a8-4e1a-97d2-54b7c58cbcbf/mount  :  
this is the path we need to backup:

```
mkdir my-bk
rsync -avz /var/lib/kubelet/pods/077c38ac-f656-44ec-888b-3a5ba52173ae/volumes/kubernetes.io~csi/pvc-4a7e1471-65a8-4e1a-97d2-54b7c58cbcbf/mount/ my-bk/
```

(trailing slash is important in rsync)  

when the backup finished, i can delete the pod a created to mount the pvc:  

```
k delete pod pvc-reserve
```

## Restore:  
for testing the restore procedure I delete the pvc:  
```
k delete pvc data-postgres-0
```

now we need to create the pvc again,
it depends alot on how the pvc has been created, here is my manifest:  

vim mypvc.yaml  
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-postgres-0
  labels:
    app.kubernetes.io/instance: aref
    app.kubernetes.io/name: postgresql
    role: primary
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  volumeMode: Filesystem
```

then i create the reserve pod again:  
```
k create -f pvc-reserve-pod.yaml
```

you need to find again where the pvc is mounted, then use rsync:
```
rsync -avz my-bk/ /var/lib/kubelet/pods/591976ac-05eb-492c-a8c2-59abc208f43d/volumes/kubernetes.io~csi/pvc-4a7e1471-65a8-4e1a-97d2-54b7c58cbcbf/mount/
```

after rsync completed, you can delete the pod:

```
k delete pod pvc-reserve
```

now our files are restored, we can scale up our sts to have the pod created:  
```
kubectl scale sts postgres --replicas=1
```





