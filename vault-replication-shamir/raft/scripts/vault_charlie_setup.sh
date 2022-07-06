#!/bin/bash

# This script installs & sets up basic configuration for Vault+prem with Consul client 
echo "Installing dependencies ..."
sudo apt-get update
sudo apt-get install -y awscli unzip curl jq net-tools vim libcap2-bin apt-file screen


# Install Vault+prem
echo "Installing Vault ${VAULT_VERSION}+prem . . ."

# Install Vault+ent from releases.hashicorp.com
echo "Fetching Vault version ${VAULT_VERSION}+ent ..."
curl -sO https://releases.hashicorp.com/vault/${VAULT_VERSION}+ent/vault_${VAULT_VERSION}+ent_linux_amd64.zip
echo "Installing Vault version ${VAULT_VERSION}+ent ..."
sleep 10
sudo unzip -d /usr/local/bin/ vault_${VAULT_VERSION}+ent_linux_amd64.zip
# Check version
vault --version

# Write Vault configuration file 
echo "Writing Vault configuration file"

sudo mkdir /etc/vault 

#make the license happen
if [[ ${VAULT_LICENSE} == "" ]]
	then echo "You did not specify a value for the VAULT_LICENSE environment variable prior to running vagrant up. You now MUST manually add the license to /etc/vault/vault.hclic on this host or vault will not start. You will have to manually kill vault and start it again as well since there is no daemon file. I suggest using a screen session. This is why you really should set the VAULT_LICENSE variable."
	else echo ${VAULT_LICENSE} > /etc/vault/vault.hclic
fi

# make the raft storage directory
mkdir -p /opt/vault/data

# make the vault config
cat <<- EOF > /etc/vault/vault.hcl
disable_mlock = true
ui = true
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "raft" {
path = "/opt/vault/data"
node_id = "vault-charlie"
}
cluster_addr="http://172.20.20.12:8201"
api_addr="http://172.20.20.12:8200"
cluster_name="vault-westylab-local"

license_path = "/etc/vault/vault.hclic"
log_level = "TRACE"
# uncomment the below and add the token to enable transit unseal
#seal "transit" {
#  address = "https://fletch.westylab.info:8200"
#  disable_renewal = "false"
#  key_name = "autounseal"
#  mount_path = "transit/"
#  tls_skip_verify = "false"
#  token = ""
#}
EOF

# make entries to the host file for nodes. This is handy for SSL implementation down the road
echo "172.20.20.10 vault-alpha.westylab.local" >> /etc/hosts
echo "172.20.20.11 vault-bravo.westylab.local" >> /etc/hosts
echo "172.20.20.12 vault-charlie.westylab.local" >> /etc/hosts

# create the vault service unit file so we don't have to resort to screen sessions anymore
echo "Installing unit file and starting Vault ..."
cat <<- EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://www.vault.io/
[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536
LogsDirectory=/var/log/vault
[Install]
WantedBy=multi-user.target 
EOF

systemctl daemon-reload
systemctl enable vault.service
systemctl start vault.service

echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /home/vagrant/.bashrc
echo "complete -o nospace -C /usr/local/bin/vault vault" >> /home/vagrant/.bashrc
