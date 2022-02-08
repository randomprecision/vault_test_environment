#!/bin/bash

# This script installs & sets up basic configuration for Vault+prem with Consul client 
echo "Installing dependencies ..."
sudo apt-get update
sudo apt-get install -y unzip curl jq net-tools vim libcap2-bin apt-file screen

# Install Consul 
echo "Fetching Consul version ${CONSUL_VERSION} ..."
cd /tmp/
curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
echo "Installing Consul version ${CONSUL_VERSION} ..."
unzip consul.zip
sudo chmod +x consul
sudo mv consul /usr/bin/consul
sudo mkdir /etc/consul.d
sudo chmod a+w /etc/consul.d


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
if [[ ${VAULT_LICENSE} == "CHANGEME" ]]
	then echo "You did not specify a value for VAULT_LICENSE in the Vagrantfile. You now MUST manually add the license to /etc/vault/vault.hclic on this host or vault will not start. You will have to manually kill vault and start it again as well since there is no daemon file. I suggest using a screen session. This is why you really should set the VAULT_LICENSE variable."
	else echo ${VAULT_LICENSE} > /etc/vault/vault.hclic
fi
cat <<- EOF > /etc/vault/vault.hcl
disable_mlock = true
ui = true
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "consul" {
  address = "0.0.0.0:8500"
  path = "vault"
}
license_path = "/etc/vault/vault.hclic"
log_level = "TRACE"
EOF

# Write Consul Configuration
echo "Writing Consul client configuration"
cat <<- EOF > /etc/consul.d/client.json
{
	"data_dir": "/tmp/consul",
	"log_level": "INFO",
	"server": false,
	"bind_addr": "0.0.0.0"
}
EOF

# Run

if [ ${CONSUL_NODE} = "primary_consul_client" ]; then
	echo "Starting Consul client agent for ${CONSUL_NODE}..."
	consul agent -node=primary-client -advertise=172.20.20.10 -retry-join=172.20.20.12 -config-dir=/etc/consul.d &> /var/log/consul.log &
	sleep 10
elif [ ${CONSUL_NODE} = "secondary_consul_client" ]; then
	echo "Starting Consul client agent for ${CONSUL_NODE}..."
	consul agent -node=secondary-client -advertise=172.20.20.11 -retry-join=172.20.20.13 -config-dir=/etc/consul.d &> /var/log/consul.log &
	sleep 10
fi


# Add envar for VAULT_ADDR and start Vault server on Vault nodes
echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> /etc/profile.d/vaultvars.sh
echo "Starting Vault server ..."
vault server -log-level=debug -config=/etc/vault/vault.hcl &> /var/log/vault.log &