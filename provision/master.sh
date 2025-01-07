#!/bin/bash

MASTER_IP="$1"

# Install etcdutl
LATEST_VERSION="$(curl -sL https://api.github.com/repos/etcd-io/etcd/releases/latest | grep '"tag_name"' | awk -F'"' '{print $4}')"
RELEASE_NAME="etcd-${LATEST_VERSION}-linux-amd64"
curl -sL "https://github.com/etcd-io/etcd/releases/download/${LATEST_VERSION}/${RELEASE_NAME}.tar.gz" -o ${RELEASE_NAME}.tar.gz
tar -xzf ${RELEASE_NAME}.tar.gz --strip-components=1 -C /usr/bin/ ${RELEASE_NAME}/etcdutl
rm -f ${RELEASE_NAME}.tar.gz
chown root:root /usr/bin/etcdutl
chmod 755 /usr/bin/etcdutl
echo "alias e=etcdutl" >> /root/.bashrc

# Sync containerd sandbox image from kubeadm images list
SANDBOX_IMAGE='registry.k8s.io/pause'
CTR_SANDBOX="$(grep "${SANDBOX_IMAGE}" /etc/containerd/config.toml | awk -F'"' '{print $2}')"
K8S_SANDBOX="$(kubeadm config images list | grep ${SANDBOX_IMAGE})"
CTR_SANDBOX_2="$(echo ${CTR_SANDBOX} | sed -e 's/\//\\\//g' -e 's/\./\\\./g')"
K8S_SANDBOX_2="$(echo ${K8S_SANDBOX} | sed -e 's/\//\\\//g' -e 's/\./\\\./g')"
sed -i -e "s/${CTR_SANDBOX_2}/${K8S_SANDBOX_2}/g" /etc/containerd/config.toml
systemctl restart containerd

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

# Setup networking
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Generate join script
kubeadm token create --print-join-command > /vagrant/cluster/join.sh
