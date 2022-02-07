#!/bin/bash

# This is for the Consul servers 

echo "Installing dependencies ..."
sudo apt-get update
sudo apt-get install -y unzip curl jq 

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

# Write Consul Configuration
echo "Writing Consul server configuration"
cat <<- EOF > /etc/consul.d/client.json
{
  "data_dir": "/tmp/consul",
  "log_level": "INFO",
  "server": true,
  "bind_addr": "0.0.0.0"
}
EOF

# Run Consul servers 

if [ ${CONSUL_NODE} = "primary_consul_server" ]; then
  echo "Starting Consul client agent for ${CONSUL_NODE}..."
  consul agent -server -bootstrap-expect=1 -node=primary-server -bind=172.20.20.12 -config-dir=/etc/consul.d &> /var/log/consul.log &

elif [ ${CONSUL_NODE} = "secondary_consul_server" ]; then
  echo "Starting Consul client agent for ${CONSUL_NODE}..."
  consul agent -server -bootstrap-expect=1 -node=secondary-server -bind=172.20.20.13 -config-dir=/etc/consul.d &> /var/log/consul.log &
fi 