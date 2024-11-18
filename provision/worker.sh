#!/bin/bash

WORKER_IP="$1"

# Join cluster
bash /vagrant/cluster/join.sh

# Update node IP
REGEX_WORKER_IP="$(echo ${WORKER_IP} | sed 's/\./\\\./g')"
sed -i "/KUBELET_KUBEADM_ARGS/ s/\"$/ \-\-node\-ip\=${REGEX_WORKER_IP}\"/" /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet

# Update user config
mkdir $HOME/.kube
cp -p /vagrant/cluster/admin.conf $HOME/.kube/config
