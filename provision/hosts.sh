#!/bin/bash

# Add all nodes into host file
echo '' >> /etc/hosts
echo '# Kubernetes nodes' >> /etc/hosts

rm -f /root/.ssh/config
ARGS=("$@")
for ((i=0; i<${#ARGS[@]}; i++)); do
  IP=${ARGS[i]}
  NAME=${ARGS[++i]:-none}

  # update hosts entries
  sed -i "/${NAME}/d" /etc/hosts
  printf "%-15s %s \n" ${IP} ${NAME} >> /etc/hosts

  # create ssh config
  cat <<EOF >> /root/.ssh/config
Host ${NAME}
  Hostname ${NAME}
  User root
  PubKeyAuthentication yes
  IdentityFile /root/.ssh/id_ed25519
  StrictHostKeyChecking no

EOF
done

chmod 600 /root/.ssh/config

# Auto login to root
echo '' >> /home/vagrant/.bash_profile
echo 'sudo -i' >> /home/vagrant/.bash_profile
