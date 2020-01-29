#!/bin/bash

#Make sure the script is being executed with superuser priviliges

if [[ "$[UID]" -ne 0 ]]
then
    echo 'Please run with sudo or as root user'
    exit 1
fi

#User name input. Need to provide at least one argument

if [[ ${#} -lt 1 ]]
then
  echo "Please pass User name as argument with script"
  echo "Usage : ${0} USER_NAME [COMMENT] ..."
  echo "Create an account with the name of USER_NAME and a comments field of COMMENT"
  exit 1
fi

#First argument is user name

USER_NAME=${1}

#Remaining comments are COMMENTS
shift
COMMENT=${@}

#Generate a password

PASSWORD=$(date +%s%N | sha256sum | head -c24)

#Create account

useradd -c "${COMMENT}" -m "${USER_NAME}"

#Check if useradd command is successful

if [[ "${?}" -ne 0 ]]
then
    echo 'The account could not be created'
    exit 1
fi

#Set the password

echo ${PASSWORD} | passwd --stdin ${USER_NAME}

if [[ "${?}" -ne 0 ]]
then
    echo 'The password for the account could not be set'
    exit 1
fi

#Force password change at first login

passwd -e ${USER_NAME}

#Display information

echo
echo "Username is : ${USER_NAME}"
echo "Generated password is : ${PASSWORD}"
echo "Hostname is : ${HOSTNAME}"

exit 0
