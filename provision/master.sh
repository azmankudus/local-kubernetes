#!/bin/bash

MASTER_IP="$1"

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
