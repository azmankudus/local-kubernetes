#!/bin/bash

# Add all nodes into host file
echo '' >> /etc/hosts
echo '# Kubernetes nodes' >> /etc/hosts

ARGS=("$@")
for ((i=0; i<${#ARGS[@]}; i++)); do
  IP=${ARGS[i]}
  NAME=${ARGS[++i]:-none}
  sed -i "/${NAME}/d" /etc/hosts
  printf "%-16s %s \n" ${IP} ${NAME} >> /etc/hosts
done

# Auto login to root
echo '' >> /home/vagrant/.bash_profile
echo 'sudo -i' >> /home/vagrant/.bash_profile
