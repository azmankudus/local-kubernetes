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

cat <<EOF > /root/.ssh/config
Host master
  Hostname master
  User root
  PubKeyAuthentication yes
  IdentityFile /root/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

chmod 600 /root/.ssh/*
chmod 700 /root/.ssh
cp -rp /root/.ssh /vagrant/