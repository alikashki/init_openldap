#!/bin/bash

#=====================================================================
#||  filename             :openLDAP_initializer.sh                  ||
#||  description          :for Initializing openLDAP Tree           ||
#||  author               :Ali Kashki                               ||
#||  email                :ali.kashki@yahoo.com                     ||
#||  date                 :09-18-2023                               ||
#||  version              :1.0.0                                    ||
#||  usage                :./openLDAP_initializer.sh                ||
#||  notes                :please read Doc(s) befor using Script    ||
#=====================================================================

# Phase-01 => chack requirements
# 1- check OS
# 2- check that script runner must be a sudoer user
# 3- rebuild /etc/hosts
# 4- check internet Connectivity
# 5- check apt Repo
# 6- apt update/upgrade
# 7- check NTP
# 8- check some packages existance
#   openssh-server / 


# export DEBIAN_FRONTEND='non-interactive'

# echo -e "slapd slapd/root_password password 123" |debconf-set-selections
# echo -e "slapd slapd/root_password_again password 123" |debconf-set-selections

# echo -e "slapd slapd/no_configuration boolean false" |debconf-set-selections
# echo -e "slapd slapd/domain string part.local" |debconf-set-selections
# echo -e "slapd shared/organization string part.local" |debconf-set-selections
# echo -e "slapd slapd/root_password password 123" |debconf-set-selections
# echo -e "slapd slapd/root_password_again password 123" |debconf-set-selections
# echo -e "slapd slapd/purge_database boolean true" |debconf-set-selections
# echo -e "slapd slapd/move_old_database boolean true" |debconf-set-selections


check_distro() { # Check that Distro is debian or not
    cat /etc/os-release | grep ID=debian
    if [ $? != '0' ];then
        echo "Sorry but This Script writen for debian distro... :("
        return 1
    else
        echo "Function "check_distro"... => Done."
        return 0
    fi
}

check_sudoer() { # Check that user is sudoer or not
    if [ `whoami` != 'root' ];then
        echo "please Run the Script as root or sudoer"
        return 1
    else
        echo "Function "check_sudoer"... => Done."
        return 0
    fi
}

# Be sure about resolving hostnames to IPs
hosts() {
    read -p "Enter HostName of machine : " host_name
    hostnamectl set-hostname $host_name
    nic=$(ls /sys/class/net/ | cut -f '1' -d ' ' | sed '1q;d')
    ip=$(ip -br a | grep $nic | awk '{print $3}' | awk -F "/" '{print $1}')
    cat /etc/hosts > /etc/hosts
    echo "
127.0.0.1	localhost
127.0.1.1	$hostname $($hostname | awk -F "." '{print $1}')

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

$ip        $host_name $($hostname | awk -F "." '{print $1}')
" > /etc/hosts
}

# Is it Possible to download Needed packages?
check_internet() {
    echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Online"
        return 0
    else
        echo "Offline"
        return 1
    fi
}

# CHeck repo to be sure for downloading Clean Packages.
check_repo() {
    return 0
}

# Upgrade the Machine for useing latest version of features.
apt_update_upgrade() {
    apt update
    apt upgrade
    return 0
}

# It's so important to sync Time between servers
check_ntp() {
    return 0
}

# Install Needed packages.
check_packages() {
    packages=("openssh-server" "slapd" "debconf-utils")
    for pkg in ${packages[@]}; do
        echo $pkg
        dpkg -s $pkg
        if [ $? -eq 0 ]; then
            echo "package : $pkg has been installed.!"
            return 0
        else
            apt install $pkg -y
            if [ $? -eq 0 ]; then
                echo "package $pkg installation done."
            fi    
        fi          
    done
    return 0
}

# Phase-02 => Install slapd and something related
# 1- Install slapd and reconfigure it / install ldap-utils
# 2- Install Ldap-Account-Manager(LAM)
# 3- /var/cache/debconf/config.dat

# Inatall the main service => slapd
install_slapd() {
    # export DEBIAN_FRONTEND='non-interactive'
    export DEBIAN_FRONTEND='noninteractive'

    echo -e "slapd slapd/root_password password 123" |debconf-set-selections
    echo -e "slapd slapd/root_password_again password 123" |debconf-set-selections

    echo -e "slapd slapd/no_configuration boolean false" |debconf-set-selections
    echo -e "slapd slapd/domain string part.local" |debconf-set-selections
    echo -e "slapd shared/organization string part.local" |debconf-set-selections
    echo -e "slapd slapd/root_password password 123" |debconf-set-selections
    echo -e "slapd slapd/root_password_again password 123" |debconf-set-selections
    echo -e "slapd slapd/purge_database boolean true" |debconf-set-selections
    echo -e "slapd slapd/move_old_database boolean true" |debconf-set-selections
    
    # apt install -y slapd &> /dev/null
    apt install -y slapd &> /dev/null
    echo "============================slapd Installed=========================="
    # dpkg-reconfigure slapd &> /dev/null
    dpkg-reconfigure slapd &> /dev/null

    touch /tmp/changeadminpass.ldif
    echo "
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: 123
" > /tmp/changeadminpass.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/changeadminpass.ldif &> /dev/null
rm /tmp/changeadminpass.ldif

    systemctl start slapd &> /dev/null
    /lib/systemd/systemd-sysv-install enable slapd
    systemctl restart slapd &> /dev/null
    apt install -y ldap-utils &> /dev/null

    echo "Function "install_slapd"... => Done."
}

# Install Ldap Account Manager (LAM)
install_lam() {
    echo "Installing LAM..."
    apt install -y ldap-account-manager ldap-account-manager-lamdaemon &> /dev/null
    echo "Function "install_lam"... => Done."
}

# Configure memberof_overlay
memberOf_overlay() {
    memberof_path=$(find / -iname memberof.la) &> /dev/null
    refint_path=$(find / -iname refint.la) &> /dev/null
    touch /tmp/update_module.ldif
    touch /tmp/load_memberof_module.ldif
    touch /tmp/add_memberof_overlay.ldif
    touch /tmp/add_refint.ldif

    echo "
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: memberof.la
" > /tmp/update_module.ldif

    echo "
dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
olcModulePath: $memberof_path
olcModuleLoad: memberof.la
" > /tmp/load_memberof_module.ldif

    echo "
dn: olcOverlay=memberof,olcDatabase={1}mdb,cn=config
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: olcConfig
objectClass: top
olcOverlay: memberof 
olcMemberOfRefInt: TRUE
olcMemberOfDangling: ignore
olcMemberOfGroupOC: groupOfNames
olcMemberOfMemberAD: member
olcMemberOfMemberOfAD: memberOf
" > /tmp/add_memberof_overlay.ldif

    echo "
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: refint.la
" > /tmp/add_refint.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/update_module.ldif &> /dev/null
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/load_memberof_module.ldif &> /dev/null
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/add_memberof_overlay.ldif &> /dev/null
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/add_refint.ldif &> /dev/null

rm /tmp/update_module.ldif
rm /tmp/load_memberof_module.ldif
rm /tmp/add_memberof_overlay.ldif
rm /tmp/add_refint.ldif
# Check => ldapsearch -LLL -Y EXTERNAL -H ldapi:/// -b cn=config -LLL | grep -i module

echo "Function "memberof_overlay"... => Done."
}

# Configure ppolicy_overlay
ppolicy_overlay() {
    # be sure that ppolicy.ldif file is exist in /etc/ldap/schema.!!
    # cp ppolicy.* /etc/ldap/schema

    if ! [ -f /etc/ldap/schema/ppolicy.ldif ]; then
        cp ppolicy.ldif /etc/ldap/schema
    fi
    if ! [ -f /etc/ldap/schema/ppolicy.schema ]; then
        cp ppolicy.schema /etc/ldap/schema
    fi
    if ! [ -f /etc/ldap/pqchecker_2.0.0_amd64.deb ]; then
        cp pqchecker_2.0.0_amd64.deb /etc/ldap/
    fi


    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/ppolicy.ldif &> /dev/null
    # for checking -> ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config cn | grep ppolicy
    touch /tmp/ppolicy_module.ldif
    touch /tmp/ppolicy_conf.ldif
    touch /tmp/ppolicy_default.ldif
    touch /tmp/pqcheckeradd.ldif

    echo "
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: ppolicy
" > /tmp/ppolicy_module.ldif

    echo "
dn: olcOverlay=ppolicy,olcDatabase={1}mdb,cn=config
objectClass: olcPpolicyConfig
olcOverlay: ppolicy
olcPPolicyDefault: cn=ppolicy,dc=part,dc=local
olcPPolicyUseLockout: FALSE
olcPPolicyHashCleartext: TRUE
" > /tmp/ppolicy_conf.ldif

    echo "
dn: cn=ppolicy,dc=part,dc=local
objectClass: device
objectClass: pwdPolicyChecker
objectClass: pwdPolicy
cn: ppolicy
pwdAllowUserChange: TRUE
pwdAttribute: userPassword
pwdCheckQuality: 2
pwdExpireWarning: 600
pwdFailureCountInterval: 30
pwdGraceAuthNLimit: 5
pwdInHistory: 5
pwdLockout: TRUE
pwdLockoutDuration: 0
pwdMaxAge: 0
pwdMaxFailure: 5
pwdMinAge: 0
pwdMinLength: 8
pwdMustChange: FALSE
pwdSafeModify: FALSE
" > /tmp/ppolicy_default.ldif

    echo "
dn: cn=ppolicy,dc=part,dc=local
changetype: modify
replace: pwdCheckQuality
pwdCheckQuality: 2
-
add: objectclass
objectclass: pwdPolicyChecker
-
add: pwdcheckmodule
pwdcheckmodule: pqchecker.so
" > /tmp/pqcheckeradd.ldif

ldapmodify -x -w 123 -D "cn=admin,dc=part,dc=local" -f /tmp/ppolicy_module.ldif &> /dev/null
# for checking -> ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcModuleList)" olcModuleLoad -LLL
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/ppolicy_conf.ldif &> /dev/null
# for checking -> ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcPpolicyConfig)" -LLL
ldapadd -x -w 123 -D "cn=admin,dc=part,dc=local" -f /tmp/ppolicy_default.ldif &> /dev/null
# for checking -> ldapsearch -Y EXTERNAL -H ldapi:/// -b dc=part,dc=loc "(objectClass=pwdPolicy)" -LLL

# make sure to transfer pqchecker.deb file to /etc/ldap.!!
# cp /home/raptor/pqchecker_2.0.0_amd64.deb /etc/ldap/
dpkg -i /etc/ldap/pqchecker_2.0.0_amd64.deb &> /dev/null

ldapadd -x -w 123 -D "cn=admin,dc=part,dc=local" -f /tmp/pqcheckeradd.ldif &> /dev/null

rm /tmp/ppolicy_module.ldif
rm /tmp/ppolicy_conf.ldif
rm /tmp/ppolicy_default.ldif
rm /tmp/pqcheckeradd.ldif
# for check password policies -> ldapsearch -Y EXTERNAL -H ldapi:/// -b dc=part,dc=loc "(objectClass=pwdPolicy)" -LLL
# for check hashing passwords -> ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcPpolicyConfig)" -LLL
# change user pass without admin DN for test password policies -> ldappasswd -Y EXTERNAL -H ldapi:/// -S "uid=john,ou=users,dc=part,dc=local"
echo "Function "ppolicy_overlay"... => Done."
}

# Initial base OUs in openLDAP Tree.
init_tree_nodes() {

    touch /tmp/addou.ldif
    ous=('Devices' 'Disabled-Users' 'Groups' 'Services-Group' 'Users')

for ouName in "${ous[@]}"; do
    echo "
dn: ou=$ouName,dc=part,dc=local
objectClass: organizationalUnit
objectClass: top
ou: $ouName    
" > /tmp/addou.ldif
    ldapadd -x -w 123 -D "cn=admin,dc=part,dc=local" -f /tmp/addou.ldif &> /dev/null
done

rm /tmp/addou.ldif

# For checking Creation of OUs
# ldapsearch -x -w 123 -D "cn=admin,dc=part,dc=local" -H ldapi:/// -b dc=part,dc=local -LLL
echo "Function "init_tree_nodes"... => Done."
}

# CHange Password of cn=config
# And edit olcRootDN of cn=config
change_cnconfig_pass() {
    read -s -p "Enter password for cn=config : " cnconfig_pass
    echo ""
    ssha_hash=$(slappasswd -s "$cnconfig_pass")
    export CNCONFIGPASS=$cnconfig_pass
    touch /tmp/cnconfigpw.ldif
    touch /tmp/cnconfigdn.ldif

    echo "
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $ssha_hash
" > /tmp/cnconfigpw.ldif

# ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/cnconfigpw.ldif &> /dev/null
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/cnconfigpw.ldif
echo "changing cn=config Password Done.!!"

echo "
dn: olcDatabase={0}config,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=config
" > /tmp/cnconfigdn.ldif

# ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/cnconfigdn.ldif &> /dev/null
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/cnconfigdn.ldif
echo "changing cn=config DN Done.!!"

rm /tmp/cnconfigpw.ldif
rm /tmp/cnconfigdn.ldif
}

#Change Password of cn=admin,dc=part,dc=local
change_cnadmin_pass() {
    read -s -p "Enter password for cn=admin : " cnadmin_pass
    echo ""
    ssha_hash=$(slappasswd -s "$cnadmin_pass")
    echo "ssha hash for cn=admin => $sshahash"
    export CNADMINPASS=$cnadmin_pass
    touch /tmp/cnadminpw.ldif
    echo "
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $ssha_hash
" > /tmp/cnadminpw.ldif

# ldapmodify -x -w 123 -D "cn=admin,dc=part,dc=local" -f /tmp/cnadminpw.ldif &> /dev/null
# ldapmodify -x -w 123 -D "cn=admin,dc=part,dc=local" -f /tmp/cnadminpw.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/cnadminpw.ldif
echo "Changing cn=admin Done.!!"
rm /tmp/cnadminpw.ldif
}

# Disable Anonymous Access
dis_anonymous() {
    touch /tmp/disanon.ldif
    echo "
dn: cn=config
changetype: modify
add: olcDisallows
olcDisallows: bind_anon
" > /tmp/disanon.ldif

# ldapadd -x -w $CNCONFIGPASS -D "cn=config" -H ldapi:/// -f /tmp/disanon.ldif &> /dev/null
ldapadd -x -w $CNCONFIGPASS -D "cn=config" -H ldapi:/// -f /tmp/disanon.ldif
echo "Disable Anonymous Access Done.!!"
rm /tmp/disanon.ldif
}

# Unset Invironment Variables set by Script
unset_vars() {
    unset CNCONFIGPASS
    unset CNADMINPASS
    echo "Unset Variables Done.!!"
}

# check_distro
# check_sudoer
install_slapd
install_lam
change_cnconfig_pass
memberOf_overlay
ppolicy_overlay
init_tree_nodes
change_cnadmin_pass
dis_anonymous
unset_vars