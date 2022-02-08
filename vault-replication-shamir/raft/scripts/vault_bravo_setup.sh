#!/bin/bash

# This script installs & sets up basic configuration for Vault+prem with Consul client 
echo "Installing AWS dependencies ..."
sudo apt-get update
sudo apt-get install -y awscli unzip curl jq net-tools vim libcap2-bin apt-file tmux screen

# Install Vault+prem
echo "Installing Vault ${VAULT_VERSION}+prem . . ."

# Figure out if version is in new S3 paths or old ones
#function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

#if [ $(version $VAULT_VERSION) -ge $(version "0.9.0") ]; then
#	aws s3 csleep 10p s3://hc-enterprise-binaries/vault/prem/${VAULT_VERSION}/vault-enterprise_${VAULT_VERSION}+prem_linux_amd64.zip .
	
#	sudo unzip -d /usr/local/bin vault-enterprise_${VAULT_VERSION}+prem_linux_amd64.zip 
# For 0.8.3 and less:
#else
#	aws s3 cp s3://hc-enterprise-binaries/vault-enterprise/${VAULT_VERSION}/vault-enterprise_${VAULT_VERSION}_linux_amd64.zip .
#	sleep 10
#	sudo unzip -d /usr/local/bin vault-enterprise_${VAULT_VERSION}_linux_amd64.zip
#fi 

# Install Vault+ent from releases.hashicorp.com
echo "Fetching Vault version ${VAULT_VERSION}+ent ..."
curl -sO https://releases.hashicorp.com/vault/${VAULT_VERSION}+ent/vault_${VAULT_VERSION}+ent_linux_amd64.zip
echo "Installing Vault version ${VAULT_VERSION}+ent ..."
sleep 20
sudo unzip -d /usr/local/bin/ vault_${VAULT_VERSION}+ent_linux_amd64.zip

# Check version
vault --version

# Write Vault configuration file 
echo "Writing Vault configuration file"

sudo mkdir /etc/vault 

#make the license happen
if [[ ${VAULT_LICENSE} == "CHANGEME" ]]
	then echo "You did not specify a value for VAULT_LICENSE in the Vagrantfile. You now MUST manually add the license to /etc/vault/vault.hclic on this host or vault will not start. You will have to manually kill vault and start it again as well since there is no daemon file. I suggest using a screen session. This is why you really should set the VAULT_LICENSE variable."
	else echo ${VAULT_LICENSE} > /etc/vault/vault.hclic

# make the raft directory
mkdir /tmp/raft-node

cat <<- EOF > /etc/vault/vault.hcl
license_path = "/etc/vault/vault.hclic"
disable_mlock = true
ui = true
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "raft" {
path = "/tmp/raft-node/"
node_id = "vault-bravo-alpn"
}
cluster_addr="http://172.20.20.11:8201"
api_addr="http://172.20.20.11:8200"
cluster_name="vault-westylab-local"
log_level = "TRACE"
EOF

echo "172.20.20.10 vault-alpha.westylab.local" >> /etc/hosts
echo "172.20.20.11 vault-bravo.westylab.local" >> /etc/hosts
echo "172.20.20.12 vault-charlie.westylab.local" >> /etc/hosts
echo "172.20.20.13 vault-delta.westylab.local" >> /etc/hosts
echo "172.20.20.14 vault-echo.westylab.local" >> /etc/hosts
echo "172.20.20.100 vault.westylab.local" >> /etc/hosts

# Start Vault server on Vault nodes
export VAULT_ADDR="http://127.0.0.1"
echo "Starting Vault server ..."
vault server -log-level=debug -config=/etc/vault/vault.hcl &> /var/log/vault.log &
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /home/vagrant/.bashrc
