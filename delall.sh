apt purge -y slapd ldap-utils ldap-account-manager ldap-account-manager-lamdaemon
rm -rf /etc/ldap
apt autoremove -y
