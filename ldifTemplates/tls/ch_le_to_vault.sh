cat /etc/ldap/certs/vault/ldapkey.key > /etc/ldap/ssl/ldapkey.key
cat /etc/ldap/certs/vault/cert.crt > /etc/ldap/ssl/cert.crt
cat /etc/ldap/certs/vault/cacert.crt > /etc/ldap/ssl/cacert.crt
systemctl restart slapd
systemctl restart keepalived
