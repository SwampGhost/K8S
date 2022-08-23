#!/bin/bash 

################### NOTES ##############################
# warno: Hostname and IP var fill are not best practice, they are temp until overall install script solution is known
# This will install a non-cis compatible Docker registry 
# Created by: SwampGhost 
# Date Created: 13 JUL 22
# Updated By: 
# Updated Date: 
########################################################

# Variable Loading
echo "Creating and loading variables."
VDIR="/var/lib/rancher"
UDIR="/usr/lib/rke2"
CTR="ctr -a /run/k3s/containerd/containerd.sock -n k8s.io"
S1IP=$(hostname -i)

# make directories for Certs and Repositories
echo "Creating required directories if they do not already exist"
mkdir -p ${VDIR}/hostPaths/registry/certs/
mkdir -p ${UDIR}/certs/

# Import the registry image 
echo "Importing the registry.tar using ctr commandlet"
${CTR} image import ${UBIN}/registry/registry.tar
#${CTR} image tag docker.io/library/registry:2 <HOSTNAME>:30500/library/registry:2

# create the config file for the certificates in usr/lib
echo "Creating the certification configuration file."
cat>>${UDIR}/certs/server.ext<<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = NC
L = Kyvia
O = Unknown
OU = Unknown
CN = Unknown

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = ${S1IP}
#IP.2 = 192.168.1.1
#IP.3 = 192.168.1.2
#IP.4 = 192.168.1.3
#IP.5 = 192.168.1.4

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

# Create the certificates in the /usr/lib
echo "Creating the certificates for ca.pem, ca.key, server.crt, server.key"
BDIR="${UDIR}/certs/"

CA_SUB_INP=${HOSTNAME:-"/C=US/ST=NC/L=Kyvia/O=Unknown/OU=Unknown/CN=registry"}
REG_SUB_INP=${S1IP:-"/C=US/ST=NC/L=Kyvia/O=Unknown/OU=Unknown/CN=registry"}

openssl genrsa -out ${BDIR}/ca.key 2048
openssl req -x509 -new -nodes -key ${BDIR}/ca.key -sha256 -days 1095 -out ${BDIR}/ca.pem -subj $CA_SUB_INP
openssl genrsa -out ${BDIR}/server.key 2048
openssl req -new -key ${BDIR}/server.key -out ${BDIR}/server.csr -subj $REG_SUB_INP
openssl x509 -req -in ${BDIR}/server.csr -CA ${BDIR}/ca.pem -CAkey ${BDIR}/ca.key -CAcreateserial -out ${BDIR}/server.crt -days 1095 -sha256 -extfile ${BDIR}/server.ext

# move the certs to the var/lib/..... 
cp ${BDIR}/ca.key ${VDIR}/hostPaths/registry/certs/
cp ${BDIR}/ca.pem ${VDIR}/hostPaths/registry/certs/
cp ${BDIR}/server.crt ${VDIR}/hostPaths/registry/certs/
cp ${BDIR}/server.key ${VDIR}/hostPaths/registry/certs/

# move the ca.pem and update the update-ca-trust 
cp ${BDIR}/ca.pem /etc/ssl/certs/ca.crt
update-ca-trust

# K appy the yaml install 
# creates: namespace, crd (local-storage), pv (local-storage), pvc (Local-storage), deployment, service
kubectl apply -f ${UBIN}/manifest/server/install-registry-localstore-noCIS.yaml -n registry

# create the sercret for the registry
k create secret generic -n registry registry-certificates --from-file=cert=${VDIR}/hostPaths/registry/certs/server.crt --from-file=key=${VDIR}/hostPaths/registry/certs/server.key --from-file=ca=${VDIR}/hostPaths/registry/certs/ca.pem

# Clearing out variables: 
echo "Nulling variables."
${VDIR} = ""
${UDIR} = ""
${CTR} = ""
${BDIR} = ""
${CA_SUB_INP} = ""
${REG_SUB_INP} = ""
${S1IP} = ""

