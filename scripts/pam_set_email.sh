#!/bin/bash
username=$PAM_USER
homedir=/home/$username

# Rather than query multiple times, store the info here
USER_INFO=$(ipa user-show $username --raw)

# Default to bash, but check for others
LOGIN_SHELL=bash
DETECT_SHELL=$(echo "$USER_INFO" | awk -F'[:/]' '/loginshell/ {print $NF}')
if [ ! -z "$DETECT_SHELL" ]
then
    LOGIN_SHELL=$DETECT_SHELL
fi

# Using rc file because we also want non-login shells to get this setup
STARTUP_FILE=$homedir/.${DETECT_SHELL}rc

# Exit early if email is already set
[ -f $STARTUP_FILE ] && grep -q "export EMAIL=" $STARTUP_FILE && exit 0

KEYTAB=/etc/krb5.keytab
PRINCIPAL=$(klist -k "$KEYTAB" | grep host | head -1 | awk '{print $2}')
kinit -k -t "$KEYTAB" "$PRINCIPAL"

# Use ipa to get email address for user
email=$(echo "$USER_INFO" | grep mail: | awk '{print $2}')
echo "export EMAIL=$email" >> $STARTUP_FILE
kdestroy
