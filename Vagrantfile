# -*- mode: ruby -*-
# vi: set ft=ruby :

VAULT_VERSION = ENV['VAULT_VERSION'] || "$VAULT_VERSION"
VAULT_LICENSE = ENV['VAULT_LICENSE'] || "$VAULT_LICENSE"
CONSUL_VERSION = ENV['CONSUL_VERSION'] || "$CONSUL_VERSION"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure("2") do |config|
#ssh goodness
#config.ssh.insert_key = false
#config.ssh.private_key_path = ["~/.ssh/id_rsa" "'~/.vagrant.d/insecure_private_key"]
config.ssh.forward_agent = true

# Install Consul on all 4 VMs
  config.vm.box = "debian/stretch64"

# Vault server VMs                        
  config.vm.define "vault_primary" do |vault_primary|
      vault_primary.vm.hostname = "vault-primary"
      vault_primary.vm.network "private_network", ip: "172.20.20.10"
      vault_primary.vm.provision "shell", 
          path: "vault-replication-shamir/scripts/vault_setup.sh",
          env: {"VAULT_VERSION" => VAULT_VERSION,
                "VAULT_LICENSE" => VAULT_LICENSE,
                 "CONSUL_VERSION" => CONSUL_VERSION,
                 "CONSUL_NODE" => "primary_consul_client",
                 "VAULT_ADDR" => "http://0.0.0.0:8200"}
  
  end

  config.vm.define "vault_secondary" do |vault_secondary|
      vault_secondary.vm.hostname = "vault-secondary"
      vault_secondary.vm.network "private_network", ip: "172.20.20.11"
      vault_secondary.vm.provision "shell", 
          path: "vault-replication-shamir/scripts/vault_secondary_setup.sh",
          env: {"VAULT_VERSION" => VAULT_VERSION,
                "VAULT_LICENSE" => VAULT_LICENSE,
                "CONSUL_VERSION" => CONSUL_VERSION,
                "CONSUL_NODE" => "secondary_consul_client",
                "VAULT_ADDR" => "http://0.0.0.0:8200"}
 
  end

# Consul server VMs
  config.vm.define "consul_server_primary" do |consul_server_primary|
      consul_server_primary.vm.hostname = "consul-server-primary"
      consul_server_primary.vm.network "private_network", ip: "172.20.20.12"
      consul_server_primary.vm.provision "shell",
          path: "vault-replication-shamir/scripts/consul_setup.sh",
          env: {"CONSUL_VERSION" => CONSUL_VERSION, 
                "CONSUL_NODE" => "primary_consul_server"}
 
  end

    config.vm.define "consul_server_secondary" do |consul_server_secondary|
      consul_server_secondary.vm.hostname = "consul-server-secondary"
      consul_server_secondary.vm.network "private_network", ip: "172.20.20.13"
      consul_server_secondary.vm.provision "shell",
          path: "vault-replication-shamir/scripts/consul_setup.sh",
          env: {"CONSUL_VERSION" => CONSUL_VERSION,
                "CONSUL_NODE" => "secondary_consul_server"}

  end

end
 

