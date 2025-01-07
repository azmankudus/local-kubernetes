# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'net/http'
require 'json'

WORKER_NODES       = 2
START_IP_ADDRESS   = "192.168.8.10" # only /24
KUBERNETES_VERSION = ""

MASTER_NAME          = "master"
WORKER_PREFIX        = "worker"
WORKER_NUMBER_LENGTH = 2

VM_PROVIDER = "virtualbox" # do not change

segment_ip = START_IP_ADDRESS.split(".")
start_ip = segment_ip[3].to_i
segment_ip.delete_at(3)

if start_ip < 1 then
  STDERR.puts "ERROR! Invalid start IP address \"#{START_IP_ADDRESS}\"."
  exit(1)
elsif start_ip + WORKER_NODES > 254 then
  STDERR.puts "ERROR! Invalid start IP address \"#{START_IP_ADDRESS}\" for #{WORKER_NODES + 1} nodes."
  exit(1)
end

ip_host_list = []
ip_host_list << segment_ip.join(".") + "." + start_ip.to_s
ip_host_list << MASTER_NAME

worker_name_format = WORKER_PREFIX + "%0#{WORKER_NUMBER_LENGTH}d"
(1..WORKER_NODES).each do |i|
  ip_host_list << segment_ip.join(".") + "." + (start_ip + i).to_s
  ip_host_list << worker_name_format % i
end

if !File.exist?(".vagrant/machines/#{MASTER_NAME}/#{VM_PROVIDER}/action_provision")
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
end

Vagrant.configure(2) do |c|
  c.vm.box = "debian/bookworm64"
  c.vm.box_check_update = false
  c.vm.box_download_insecure = true
  c.ssh.insert_key = false

  # Master
  master_name = ip_host_list[1]
  c.vm.define master_name do |m|
    m.vm.hostname = master_name
    m.vm.network "private_network", ip: ip_host_list[0]
    m.vm.provider VM_PROVIDER do |v|
      v.cpus = 2
      v.memory = 2048
    end
    m.vm.provision "shell", path: "provision/install.sh", :args => [ KUBERNETES_VERSION ]
    m.vm.provision "shell", path: "provision/master.sh", :args => [ ip_host_list[0] ]
    m.vm.provision "shell", path: "provision/hosts.sh", :args => ip_host_list
  end

  # Worker
  (1..WORKER_NODES).each do |i|
    worker_name = ip_host_list[i * 2 + 1]
    c.vm.define worker_name do |w|
      w.vm.hostname = worker_name
      w.vm.network "private_network", ip: ip_host_list[i * 2]
      w.vm.provider VM_PROVIDER do |v|
        v.cpus = 2
        v.memory = 2048
      end
      w.vm.provision "shell", path: "provision/install.sh", :args => [ KUBERNETES_VERSION ]
      w.vm.provision "shell", path: "provision/worker.sh", :args => [ ip_host_list[i * 2] ]
      w.vm.provision "shell", path: "provision/hosts.sh", :args => ip_host_list
    end
  end
end
