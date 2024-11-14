# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |c|
  c.vm.box = "debian/bookworm64"
  c.vm.box_check_update = false
  c.vm.box_download_insecure = true

  # Master
  c.vm.define "master" do |m|
    m.vm.hostname = "master"
    m.vm.network "private_network", ip: "192.168.8.10"
    m.vm.provider "virtualbox" do |v|
      v.cpus = 2
      v.memory = 2048
    end
    m.vm.provision "shell", path: "install.sh"
    m.vm.provision "shell", path: "master.sh"
  end

  # Worker
  c.vm.define "worker" do |w|
    w.vm.hostname = "worker"
    w.vm.network "private_network", ip: "192.168.8.11"
    w.vm.provider "virtualbox" do |v|
      v.cpus = 2
      v.memory = 2048
    end
    w.vm.provision "shell", path: "install.sh"
    w.vm.provision "shell", path: "worker.sh"
  end
end
