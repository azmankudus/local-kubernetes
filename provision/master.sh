#!/bin/bash

MASTER_IP="$1"

# Install etcdctl
LATEST_VERSION="$(curl -sL https://api.github.com/repos/etcd-io/etcd/releases/latest | grep '"tag_name"' | awk -F'"' '{print $4}')"
RELEASE_NAME="etcd-${LATEST_VERSION}-linux-amd64"
curl -sL "https://github.com/etcd-io/etcd/releases/download/${LATEST_VERSION}/${RELEASE_NAME}.tar.gz" -o ${RELEASE_NAME}.tar.gz
tar -xzf ${RELEASE_NAME}.tar.gz --strip-components=1 -C /usr/bin/ ${RELEASE_NAME}/etcdctl
rm -f ${RELEASE_NAME}.tar.gz
chown root:root /usr/bin/etcdctl
chmod 755 /usr/bin/etcdctl
echo "alias e=etcdctl" >> /root/.bashrc
echo "alias e=etcdctl" >> /home/vagrant/.bashrc

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
mkdir /home/vagrant/.kube
cp -p /vagrant/cluster/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Setup networking
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Generate join script
kubeadm token create --print-join-command > /vagrant/cluster/join.sh
