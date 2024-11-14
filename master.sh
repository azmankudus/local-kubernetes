#!/bin/bash

# Initialize master node
kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=192.168.8.10
cp -p /etc/kubernetes/admin.conf /vagrant/admin.conf
sed -i '/KUBELET_KUBEADM_ARGS/ s/"$/ \-\-node\-ip\=192\.168\.8\.10"/' /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet
mkdir $HOME/.kube
cp -p /vagrant/admin.conf $HOME/.kube/config
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubeadm token create --print-join-command > /vagrant/join.sh
sed -i -e "/master/d" -e "/worker/d" /etc/hosts
cat <<EOF >> /etc/hosts

192.168.8.10 master
192.168.8.11 worker
EOF
