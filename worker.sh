#!/bin/bash

# Join cluster
bash /vagrant/join.sh
sed -i '/KUBELET_KUBEADM_ARGS/ s/"$/ \-\-node\-ip\=192\.168\.8\.11"/' /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet
mkdir $HOME/.kube
cp -p /vagrant/admin.conf $HOME/.kube/config
sed -i -e "/master/d" -e "/worker/d" /etc/hosts
cat <<EOF >> /etc/hosts

192.168.8.10 master
192.168.8.11 worker
EOF
