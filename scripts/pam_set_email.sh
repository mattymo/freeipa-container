#!/bin/bash
username=$PAM_USER
homedir=/home/$username

# Exit early if email is already set
grep -q "export EMAIL=" $homedir/.bash_profile && exit 0

KEYTAB=/etc/krb5.keytab
PRINCIPAL=$(klist -k "$KEYTAB" | grep host | head -1 | awk '{print $2}')
kinit -k -t "$KEYTAB" "$PRINCIPAL"

# Use ipa to get email address for user
email=$(ipa user-show $username --raw | grep mail: | awk '{print $2}')
echo "export EMAIL=$email" >> $homedir/.bash_profile
kdestroy
