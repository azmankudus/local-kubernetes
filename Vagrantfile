# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'net/http'

KUBERNETES_VERSION = "v1.30.0"

uri = URI("https://api.github.com/repos/kubernetes/kubernetes/releases/tags/#{KUBERNETES_VERSION}")
res = Net::HTTP.get_response(uri)
if res.code.to_i != 200 then
  STDERR.puts "ERROR! Invalid Kubernetes version \"#{KUBERNETES_VERSION}\"."
end

Vagrant.configure(2) do |c|
  c.vm.box = "debian/bookworm64"
  c.vm.box_check_update = false
  c.vm.box_download_insecure = true
  c.ssh.insert_key = false

  # Master
  c.vm.define "master" do |m|
    m.vm.hostname = "master"
    m.vm.network "private_network", ip: "192.168.8.10"
    m.vm.provider "virtualbox" do |v|
      v.cpus = 2
      v.memory = 2048
    end
    m.vm.provision "shell", path: "install.sh", :args => [ KUBERNETES_VERSION ]
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
    w.vm.provision "shell", path: "install.sh", :args => [ KUBERNETES_VERSION ]
    w.vm.provision "shell", path: "worker.sh"
  end
end
