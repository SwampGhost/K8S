#!/bin/bash

################### NOTES ##############################
# warno: THis assumes the local-store install was completed previous and Rook-Ceph is operaitonal
# This will install a non-cis compatible Docker registry 
# Created by: SwampGhost 
# Date Created: 13 JUL 22
# Updated By: 
# Updated Date: 
########################################################

########################################################
#####  FUNCTIONS #######################################
########################################################

# ## Function to copy from server 1 /var/lib/rancher/hostPaths/registry/db/ to the pod's PVC 
function copy_reg_data {
  echo "First line of the function"
  for pod in $(kubectl get pods -n registry | awk 'NR>1{print $1}'); do  # Find the Pod in the registry namesapce
    if [[ "$pod" == "$1" ]]; then    # If the pod var is empty, fail, else, run the command 
      echo "No pod found: ${pod}"
    fi
      # Copy from the previous hostpath to the PVC within the identified pod
      #echo "Command to run: kubectl cp /var/lib/rancher/hostPaths/registry/db/docker ${pod}:/var/lib/registry/ -n registry"
      kubectl cp /var/lib/rancher/hostPaths/registry/db/docker ${pod}:/var/lib/registry/ -n registry
  done
}

########################################################
#### Main Body #########################################
########################################################

# delete components of current registry 
kubectl -n registry delete deployment.apps/registry
kubectl -n registry delete service/registry-svc
kubectl -n registry delete persistentvolumeclaim/registry-data-pvc
kubectl -n registry delete persistentvolume/registry-data-pv

# Apply the registry definition for ceph-block 
kubectl apply -f /usr/lib/rke2/manifests/server/registry-cephblock-noCIS.yaml -n registry

# echo "starting script" 
copy_reg_data

# Message to console that work is finished. 
echo "The copy to ${pod} is complete "

