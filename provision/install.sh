#!/bin/bash

KUBERNETES_VERSION="$1"

# OS kernel modules
modprobe overlay
modprobe br_netfilter

# OS networking
cat <<EOF >> /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Install containerd'
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
cat <<EOF > /etc/apt/sources.list.d/docker.list
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF
apt-get update
apt-get install -y containerd.io
apt-mark hold containerd.io
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/' /etc/containerd/config.toml
systemctl restart containerd

# Install kubelet and kubeadm
KUBERNETES_VERSION_MINOR="$(echo "${KUBERNETES_VERSION}" | awk -F'.' '{print $1"."$2}')"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION_MINOR}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION_MINOR}/deb/ /
EOF
chmod 644 /etc/apt/sources.list.d/kubernetes.list
apt-get update
KUBELET_VERSION="$(apt-cache madison kubelet | grep ${KUBERNETES_VERSION:1} | head -1 | awk '{print $3}')"
KUBEADM_VERSION="$(apt-cache madison kubeadm | grep ${KUBERNETES_VERSION:1} | head -1 | awk '{print $3}')"
apt-get install -y kubelet=${KUBELET_VERSION} kubeadm=${KUBEADM_VERSION}
apt-mark hold kubelet kubeadm

# Sync containerd sandbox image from kubeadm images list
SANDBOX_IMAGE='registry.k8s.io/pause'
CTR_SANDBOX="$(grep "${SANDBOX_IMAGE}" /etc/containerd/config.toml | awk -F'"' '{print $2}')"
K8S_SANDBOX="$(kubeadm config images list | grep ${SANDBOX_IMAGE})"
CTR_SANDBOX_2="$(echo ${CTR_SANDBOX} | sed -e 's/\//\\\//g' -e 's/\./\\\./g')"
K8S_SANDBOX_2="$(echo ${K8S_SANDBOX} | sed -e 's/\//\\\//g' -e 's/\./\\\./g')"
sed -i -e "s/${CTR_SANDBOX_2}/${K8S_SANDBOX_2}/g" /etc/containerd/config.toml
systemctl restart containerd

# Add alias k for kubectl
echo '' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
