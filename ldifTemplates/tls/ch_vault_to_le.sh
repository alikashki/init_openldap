cat /etc/ldap/certs/lete/privateKey.pem > /etc/ldap/ssl/ldapkey.key
cat /etc/ldap/certs/lete/certificate.crt > /etc/ldap/ssl/cert.crt
cat /etc/ldap/certs/lete/lecacert.crt > /etc/ldap/ssl/cacert.crt
systemctl restart slapd
systemctl restart keepalived
