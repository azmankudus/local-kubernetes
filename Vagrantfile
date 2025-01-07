# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'net/http'
require 'json'

KUBERNETES_VERSION = ""

MASTER_NAME = "master"
WORKERS_NAME = "worker%02d"

IP_ADDRESSES = [
  "192.168.8.10",
  "192.168.8.11", 
  "192.168.8.12"
]

if defined?(KUBERNETES_VERSION) || my_variable.to_s.strip.empty? then
  r = Net::HTTP.get_response(URI("https://api.github.com/repos/kubernetes/kubernetes/releases/latest"))
  latest_version = JSON.parse(r.body)
  KUBERNETES_VERSION = latest_version["tag_name"]
else
  r = Net::HTTP.get_response(URI("https://api.github.com/repos/kubernetes/kubernetes/releases/tags/#{KUBERNETES_VERSION}"))
  if r.code.to_i != 200 then
    STDERR.puts "ERROR! Invalid Kubernetes version \"#{KUBERNETES_VERSION}\"."
    exit(1)
  end
end

puts "##### Kubernetes #{KUBERNETES_VERSION} #####"

IPS_NODES = []
IPS_NODES << IP_ADDRESSES[0]
IPS_NODES << MASTER_NAME

(1..IP_ADDRESSES.length - 1).each do |i|
  IPS_NODES << IP_ADDRESSES[i]
  IPS_NODES << WORKERS_NAME % i
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
    m.vm.provision "shell", path: "provision/install.sh", :args => [ KUBERNETES_VERSION ]
    m.vm.provision "shell", path: "provision/master.sh", :args => [ IP_ADDRESSES[0] ]
    m.vm.provision "shell", path: "provision/hosts.sh", :args => IPS_NODES
  end

  # Worker
  (1..IP_ADDRESSES.length - 1).each do |i|
    worker_name = WORKERS_NAME % i
    c.vm.define worker_name do |w|
      w.vm.hostname = worker_name
      w.vm.network "private_network", ip: IP_ADDRESSES[i]
      w.vm.provider "virtualbox" do |v|
        v.cpus = 2
        v.memory = 2048
      end
      w.vm.provision "shell", path: "provision/install.sh", :args => [ KUBERNETES_VERSION ]
      w.vm.provision "shell", path: "provision/worker.sh", :args => [ IP_ADDRESSES[i] ]
      w.vm.provision "shell", path: "provision/hosts.sh", :args => IPS_NODES
    end
  end
end
