#!/bin/bash

WORKER_IP="$1"

# Join cluster
bash /vagrant/join.sh
REGEX_WORKER_IP="$(echo ${WORKER_IP} | sed 's/\./\\\./g')"
sed -i "/KUBELET_KUBEADM_ARGS/ s/\"$/ \-\-node\-ip\=${REGEX_WORKER_IP}\"/" /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet
mkdir $HOME/.kube
cp -p /vagrant/admin.conf $HOME/.kube/config
