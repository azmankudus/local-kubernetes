# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'net/http'

KUBERNETES_VERSION = "v1.30.0"

IP_ADDRESSES = [ "192.168.8.10", "192.168.8.20", "192.168.8.30" ]

r = Net::HTTP.get_response(URI("https://api.github.com/repos/kubernetes/kubernetes/releases/tags/#{KUBERNETES_VERSION}"))
if r.code.to_i != 200 then
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
    m.vm.network "private_network", ip: IP_ADDRESSES[0]
    m.vm.provider "virtualbox" do |v|
      v.cpus = 2
      v.memory = 2048
    end
    m.vm.provision "shell", path: "install.sh", :args => [ KUBERNETES_VERSION ]
    m.vm.provision "shell", path: "master.sh", :args => [ IP_ADDRESSES[0] ]
  end

  # Worker
  (1..IP_ADDRESSES.length - 1).each do |i|
    c.vm.define "worker#{i}" do |w|
      w.vm.hostname = "worker#{i}"
      w.vm.network "private_network", ip: IP_ADDRESSES[i]
      w.vm.provider "virtualbox" do |v|
        v.cpus = 2
        v.memory = 2048
      end
      w.vm.provision "shell", path: "install.sh", :args => [ KUBERNETES_VERSION ]
      w.vm.provision "shell", path: "worker.sh", :args => [ IP_ADDRESSES[i] ]
    end
  end
end
