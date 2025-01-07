#!/bin/bash

WORKER_IP="$1"

# Join cluster
bash /vagrant/cluster/join.sh

# Update node IP
REGEX_WORKER_IP="$(echo ${WORKER_IP} | sed 's/\./\\\./g')"
sed -i "/KUBELET_KUBEADM_ARGS/ s/\"$/ \-\-node\-ip\=${REGEX_WORKER_IP}\"/" /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet

# Update user config
mkdir /root/.kube
cp -p /vagrant/cluster/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# copy ssh keys
rm -rf /root/.ssh
cp -rp /vagrant/.ssh /root/
chown -R root:root /root/.ssh
chmod 600 /root/.ssh/*
chmod 700 /root/.ssh
