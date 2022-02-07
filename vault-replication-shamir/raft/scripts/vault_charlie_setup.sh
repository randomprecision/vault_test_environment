#!/bin/bash

# This script installs & sets up basic configuration for Vault+prem with Consul client 
echo "Installing AWS dependencies ..."
sudo apt-get update
sudo apt-get install -y awscli unzip curl jq net-tools vim libcap2-bin apt-file tmux screen

# Install Vault+prem
echo "Installing Vault ${VAULT_VERSION}+prem . . ."

# Install Vault+ent from releases.hashicorp.com instead of AWS
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

#the more modern way with the file 
sudo echo "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJ5KFE2SNKRRXUTKHKV2FURCNGVHUGMBTJYZE43CMKRKTKTL2MN2FS3KRGNHEORJRJVWVKMK2K5ETASLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJF5E23KWNNGUIVJSJV4TAMSONVITCTCXIUZFSVCBORMXURJUJZUTA6SOIRFGUT2EJV5FS3KNGBHEORLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SFORGUIY3UJVVGYVKNKRKTMTKUJE3E2RDLOVGUISJQJVVFCMCPKRUGCSLJO5UWGM2SNBRW4UTGMRDWY5C2KNETMSLKJF3U22SFORGUIY3UJVVGYVKNIRATMTKEIE3E2RCCMFEWS53JLJMGQ53BLBFGQZCHNR3GE3BZGBQVOMLMJFVG62KNNJAXSTLZGB3U46JQPFHVMULXJVCG652NIRXXOTKGN5UUYQ2KGBNFQSTUMFLTK2DEI5WHMYTMHEYGCVZRNREWU33JJVVEC6KNPEYHOTTZGB4U6VSRO5GUI33XJVCG652NIZXWSTCDJJ3WG3JZNNSFOTRQJFVG62LENVDDCYSIKFUUYQ2KNVREORTOMN4USNTFPFFHIYRSKIYWER2WPJEWU4DCJFWTCMLCJBJHATCXKJVEYWCONJMVO6DMJFUXO2K2GI4TEWSYJJ2VSVZVNJNFGMLXMIZHQ4CZGNVWSTCDJJUFUSC2NBRG2TTMLJBTC22ZLBJGQTCYIJ4WEM2SNRMTGUTQMIZDI2KYLAYTSLRVINAUWL2OJZGGQ6DXNBRTA6TSOFDEWNCEKQYSWMTTIMZEOQTWKZZWGZRZIJBC6T2EJ5SXEVSXPEYDKVKGJ5KC6NCWJYVU6NSMJBGUYRBQKZXXS43VF5BUCMTMNNCHUTDKHB4TGQRVGFSEC23DME2GIVRQGMZTQUDXNVLGYYLWJJIDI4CKPBEUSOKEGZKUMTCVMFLFA2TLK5FHIY2EGZYGC3BWN5HWMR3OJMZHUUCLJJJG2R2IKYZWKWTXOFDGKK3PG5VS64ZLIFKE42CQLJTVGL2LKZMWOL2LFNWEOUDXJQ3WUQTYJE3UOT3BNM3FKYLJMFEG6ZLLGBJFI3ZXGJCFCPJ5" > /etc/vault/vault.hclic

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
node_id = "vault-charlie-alpn"
}
cluster_addr="http://172.20.20.12:8201"
api_addr="http://172.20.20.12:8200"
cluster_name="vault-westylab-local"
log_level = "TRACE"
EOF

echo "172.20.20.10 vault-alpha.westylab.local" >> /etc/hosts
echo "172.20.20.11 vault-bravo.westylab.local" >> /etc/hosts
echo "172.20.20.12 vault-charlie.westylab.local" >> /etc/hosts
echo "172.20.20.13 vault-delta.westylab.local" >> /etc/hosts
echo "172.20.20.14 vault-echo.westylab.local" >> /etc/hosts
echo "172.20.20.100 vault.westylab.local" >> /etc/hosts

export VAULT_ADDR="http://127.0.0.1"
echo "Starting Vault server ..."
vault server -log-level=trace -config=/etc/vault/vault.hcl &> /var/log/vault.log &
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /home/vagrant/.bashrc
