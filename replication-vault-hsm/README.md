## What is this?

This Vagrantfile will spin up four Debian VMs: 

* 2 Vault+prem.hsm servers (with Consul client)
* 2 Consul servers

The Vault+prem.hsm servers each have SoftHSM installed and configured and use a Consul storage backend. The goal is to simulate a basic 2-cluster replication setup using the HSM version of Vault (1 Vault server & 1 Consul server per cluster).

Vagrant will:
* Spin up the VMs and provision them
* Configure SoftHSM on Vault servers and initialize a token in the Slot that Vault will use (based off of internal KB: https://docs.google.com/document/d/1kq_siaXErnQvrr7PvkPZtQRrtH2HzBsyS5zNRiZr9QM/edit#heading=h.olw2mlxyowjt)
* Start up both Vault and Consul
* Join the client nodes to their respective Consul server

For logs:

* Vault: /var/log/vault.log
* Consul: /var/log/consul.log

## Pre-req

On host machine, make sure you have set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables that allow you to download Vault+prem.hsm binaries. Or [use envchain](https://github.com/sorah/envchain) with an environment that has those variables (i.e. `envchain myenv vagrant up`).

To specify Consul and Vault versions, set the `CONSUL_VERSION` AND `VAULT_VERSION` environment variables on the host before running `vagrant up`. The defaults are in the Vagrantfile. 

## Spin up VMs

Run `vagrant up` and then ssh into the `vault_primary` and `vault_secondary` to initialize Vault and then set up replication.

Easy to initialize with `vault operator init -recovery-shares=1 -recovery-threshold=1 ` and follow https://www.vaultproject.io/guides/replication.html to set up replication.

## Coming soon...

Hope to merge this with the Shamir-based, and make the seal type a toggle 
