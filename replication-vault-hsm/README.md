## What is this?

<sub>This is my (sanitized) version of the `vault_test_environment` vagrant sandbox passed down to me from benz0, who had it passed down to him from someone else. I have removed some things and added other stuff in an effort to make this more current and useful. I plan to add more to this (I use this all the time for Vault support) so check in from time to time if you're interested in the changes. I've removed all proprietary information from here so I'm comfortable flipping the repo over to public, but PLEASE let me know if you find something here that should not be. </sub>

---

## **You MUST have a valid Vault Enterprise license to use this vagrant environment**

This Vagrantfile will spin up four "debian/stretch64" VMs with softHSM and auto-unseal: 

* 2 Vault+prem servers (with Consul client)
* 2 Consul servers

The Vault+prem servers each use a Consul storage backend. The goal is to simulate a basic 2-cluster replication setup of Vault (1 Vault server & 1 Consul server per cluster).

Vagrant will spin up the VMs, provision them, and start up both Vault and Consul. It will also join the client nodes to their respective Consul server. 

For logs:

* Vault: /var/log/vault.log
* Consul: /var/log/consul.log

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

```
export VAULT_ADDR="http://:8200"
vault operator init -key-shares=1 -key-threshold=1 -format=json > keys.txt
cat keys.txt
```

Then follow https://www.vaultproject.io/guides/replication.html to set up replication.
