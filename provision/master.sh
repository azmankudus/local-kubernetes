#!/bin/bash

MASTER_IP="$1"

# Install kubectl
KUBERNETES_VERSION="$(kubeadm version | awk -F'"' '{print $6}')"
KUBECTL_VERSION="$(apt-cache madison kubectl | grep ${KUBERNETES_VERSION:1} | head -1 | awk '{print $3}')"
apt-get install -y kubectl=${KUBECTL_VERSION}
apt-mark hold kubectl

# Install etcdctl/etcdutl
ETCD_VERSION="v$(kubeadm config images list | grep 'registry.k8s.io/etcd' | awk -F':' '{print $2}' | awk -F'-' '{print $1}')"
RELEASE_NAME="etcd-${ETCD_VERSION}-linux-amd64"
curl -sL "https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/${RELEASE_NAME}.tar.gz" -o ${RELEASE_NAME}.tar.gz
tar -xzf ${RELEASE_NAME}.tar.gz --strip-components=1 -C /usr/bin/ ${RELEASE_NAME}/etcdctl ${RELEASE_NAME}/etcdutl
rm -f ${RELEASE_NAME}.tar.gz
chown root:root /usr/bin/etcdctl
chmod 755 /usr/bin/etcdctl
chown root:root /usr/bin/etcdutl
chmod 755 /usr/bin/etcdutl
echo "alias e=etcdutl" >> /root/.bashrc

# Install Helm
curl -sL https://baltocdn.com/helm/signing.asc | gpg --dearmor > /usr/share/keyrings/helm.gpg
apt-get install -y apt-transport-https
cat <<EOF > /etc/apt/sources.list.d/helm-stable-debian.list
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main
EOF
apt-get update
apt-get install -y helm

# Download images
kubeadm config images pull

# Initialize master node
kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=${MASTER_IP}
mkdir -p /vagrant/cluster
cp -p /etc/kubernetes/admin.conf /vagrant/cluster/admin.conf

# Update node IP
REGEX_MASTER_IP="$(echo ${MASTER_IP} | sed 's/\./\\\./g')"
sed -i "/KUBELET_KUBEADM_ARGS/ s/\"$/ \-\-node\-ip\=${REGEX_MASTER_IP}\"/" /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet

# Update user config
mkdir /root/.kube
cp -p /vagrant/cluster/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# Setup calico networking
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Setup local-path storage class
LATEST_VERSION="$(curl -sL https://api.github.com/repos/rancher/local-path-provisioner/releases/latest | grep '"tag_name"' | awk -F'"' '{print $4}')"
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/${LATEST_VERSION}/deploy/local-path-storage.yaml

# Generate join script
kubeadm token create --print-join-command > /vagrant/cluster/join.sh

# Generate ssh key
rm -rf /root/.ssh
mkdir /root/.ssh
ssh-keygen -t ed25519 -C 'kubernetes' -f /root/.ssh/id_ed25519 -P ''
cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys

chmod 600 /root/.ssh/*
chmod 700 /root/.ssh
cp -rp /root/.ssh /vagrant/
