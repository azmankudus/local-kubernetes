#!/bin/bash

MASTER_IP="$1"

# Initialize master node
kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=${MASTER_IP}
cp -p /etc/kubernetes/admin.conf /vagrant/admin.conf

REGEX_MASTER_IP="$(echo ${MASTER_IP} | sed 's/\./\\\./g')"
sed -i "/KUBELET_KUBEADM_ARGS/ s/\"$/ \-\-node\-ip\=${REGEX_MASTER_IP}\"/" /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet
mkdir $HOME/.kube
cp -p /vagrant/admin.conf $HOME/.kube/config
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubeadm token create --print-join-command > /vagrant/join.sh
