#!/bin/bash

# This script installs & sets up basic configuration for Vault+prem.hsm with Consul client and Soft HSM
echo "Installing SoftHSM and dependencies ..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y unzip curl jq libltdl-dev libsofthsm2 softhsm2 opensc net-tools vim libcap2-bin apt-file tmux screen

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
mkdir /etc/vault

# Install Vault+prem.hsm where needed
echo "Installing Vault ${VAULT_VERSION}+prem.hsm . . ."

echo "Fetching Vault version ${VAULT_VERSION}+ent ..."
curl -sO https://releases.hashicorp.com/vault/${VAULT_VERSION}+ent.hsm/vault_${VAULT_VERSION}+ent.hsm_linux_amd64.zip
echo "Installing Vault version ${VAULT_VERSION}+ent.hsm ..."
sleep 10
sudo unzip -d /usr/local/bin/ vault_${VAULT_VERSION}+ent.hsm_linux_amd64.zip

# Check version 
vault --version

# Configure SoftHSM where needed 
echo "Configuring SoftHSM ..."
cd /home/vagrant
mkdir -p ./softhsm/tokens

sudo cat <<- EOF > /etc/softhsm/softhsm2.conf
# SoftHSM v2 configuration file
directories.tokendir = /home/vagrant/softhsm/tokens/
objectstore.backend = file
# ERROR, WARNING, INFO, DEBUG
log.level = INFO
# If CKF_REMOVABLE_DEVICE flag should be set
slots.removable = false
EOF

echo "Initializing ..."
softhsm2-util \
   --init-token \
   --slot 0 \
   --label hsm_example \
   --pin 1234 \
   --so-pin 0000

export VAULT_HSM_SLOT=$(sudo softhsm2-util --show-slots | grep -m 1 Slot | cut -c6-)

# Write Vault configuration file where needed
echo "Writing Vault configuration file"

# make the license happen 
#if [[ ${VAULT_LICENSE} == "CHANGEME" ]]
#	then echo "You did not specify a value for VAULT_LICENSE in the Vagrantfile. You now MUST manually add the license to /etc/vault/vault.hclic on this host or vault will not start. You will have to manually kill vault and start it again as well since there is no daemon file. I suggest using a screen session. This is why you really should set the VAULT_LICENSE variable."
#	else echo ${VAULT_LICENSE} > /etc/vault/vault.hclic
#fi

echo ${VAULT_LICENSE} > /etc/vault/vault.hclic

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

seal "pkcs11" {
  lib = "/usr/lib/softhsm/libsofthsm2.so"
  pin = "1234"
  key_label = "key"
  hmac_key_label = "aaa-key"
  generate_key = "true"
}

license_path = "/etc/vault/vault.hclic"
log_level="TRACE"
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
elif [ ${CONSUL_NODE} = "secondary_consul_client" ]; then
  echo "Starting Consul client agent for ${CONSUL_NODE}..."
  consul agent -node=secondary-client -advertise=172.20.20.11 -retry-join=172.20.20.13 -config-dir=/etc/consul.d &> /var/log/consul.log &
fi

sleep 10

# Set Vault environment vars
echo "Setting Vault address"
echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> /etc/profile.d/vaultvars.sh
echo "export VAULT_HSM_SLOT='$(sudo softhsm2-util --show-slots | grep -m 1 Slot | cut -c6-)'" >> /etc/profile.d/vaultvars.sh

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
