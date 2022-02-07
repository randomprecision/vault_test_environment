apt install -y update 
apt install -y nginx net-tools screen jq openssl vim
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
tee /etc/nginx/nginx.conf -<<EOF
# This upstream is used to load balance between two Vault instances

stream {
  upstream vault_backend {
  server vault-alpha.westylab.local:8200;
  server vault-bravo.westylab.local:8200;
  server vault-charlie.westylab.local:8200;
  server vault-delta.westylab.local:8200;
  server vault-echo.westylab.local:8200
  }
server {
  listen        443;
  server_name   vault.westylab.local;
  proxy_pass	vault_backend;
  proxy_timeout 3s; 
  proxy_connect_timeout 1s; 
  }

  # This location is used to handle redirects send by HA Vault Cluster
  location @handle_vault_standby {
    set $saved_vault_endpoint '$upstream_http_location';
    proxy_pass $saved_vault_endpoint;
  }

  # This location is a failover loadbalancer for all vault instances
  location ~* ^/(.+)$ {
    proxy_pass "https://vault_backend/$1";
    proxy_next_upstream     error timeout invalid_header http_500 http_429 http_503;
    proxy_connect_timeout   2;
    proxy_set_header        Host                $host;
    proxy_set_header        X-Real-IP           $remote_addr;
    proxy_set_header        X-Forwarded-For     $proxy_add_x_forwarded_for;
    proxy_intercept_errors on;
    error_page 301 302 307 = @handle_vault_standby;
  }
}
EOF
systemctl restart nginx

echo "172.20.20.10 vault-alpha.westylab.local" >> /etc/hosts
echo "172.20.20.11 vault-bravo.westylab.local" >> /etc/hosts
echo "172.20.20.12 vault-charlie.westylab.local" >> /etc/hosts
echo "172.20.20.13 vault-delta.westylab.local" >> /etc/hosts
echo "172.20.20.14 vault-echo.westylab.local" >> /etc/hosts
echo "172.20.20.100 vault.westylab.local" >> /etc/hosts
