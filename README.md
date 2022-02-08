## What is this?

This is my (sanitized) version of the `vault_test_environment` vagrant sandbox passed down to me from benz0, who had it passed down to him from someone else. I have removed some stuff and added other stuff in an effort to make this more current and useful. I plan to add more stuff to this (I use this all the time for Vault support) so check in from time to time if you're interested in the changes. I've removed all proprietary information from here so I'm comfortable flipping the repo over to public, but please let me know if you find something here that should not be. 

---

This Vagrantfile will spin up four "debian/stretch64" VMs: 

* 2 Vault+prem servers (with Consul client)
* 2 Consul servers

The Vault+prem servers each use a Consul storage backend. The goal is to simulate a basic 2-cluster replication setup of Vault (1 Vault server & 1 Consul server per cluster).

Vagrant will spin up the VMs, provision them, and start up both Vault and Consul. It will also join the client nodes to their respective Consul server. 

For logs:

* Vault: /var/log/vault.log
* Consul: /var/log/consul.log

## Directory Contents

`vault-replication-shamir` - sets up two consul and two vault nodes using shamir seal
subdirectories:
  `raft` - EXPERIMENTAL - sets up a 5 node raft cluster 
  `nginx` - EXPERIMENTAL - nginx load balancer VM with basic config. This probably won't work for you without some changes. 

`replication-vault-hsm` - sets up two consul nodes and two vault nodes using softHSM and autounseal 


## Upcoming features 

- integrated self-signed SSL certs w/ trust
- getting `vault_init.py` script to work properly and integrate it into the vagrants
- getting `nginx` working and complete integrating it into the `raft` vagrant 

## Pre-req

**You MUST have a vault license defined in the Vagrant file in the `VAULT_LICENSE` variable.**

To specify Consul and Vault versions, set the `CONSUL_VERSION` AND `VAULT_VERSION` environment variables on the host before running `vagrant up`. The defaults are in the Vagrantfile. 

## Spin up VMs

You want to spin up the consul VMs first: 

`vagrant up consul_server_primary consul_server_secondary` 
then once those have finished coming up 
`vagrant up vault_primary vault_secondary` 

Then ssh into the `vault_primary` and `vault_secondary` to initialize Vault and then set up replication. 

Easy to initialize with:

export VAULT_ADDR="http://127.0.0.1:8200"
vault operator init -key-shares=1 -key-threshold=1 > keys.txt
cat keys.txt

Then follow https://www.vaultproject.io/guides/replication.html to set up replication.
