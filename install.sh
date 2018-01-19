#!/bin/bash

# This script installs samba, creates the samba share, and adds the users to samba password file.

# Make sure the script is being executed with superuser privileges

if [[ "${UID}" -ne 0 ]]

then

  echo 'Please run with sudo or as root.'

  exit 1

fi

# Update the repos and install updates

apt-get update && apt-get upgrade -y


# Install samba

apt-get install -y samba

# Echo config into smb.conf file
echo '[global]
  workgroup = WORKGROUP
  server string = samba2
  server role = standalone server
  security = user
  map to guest = Bad User
  log file = /var/log/samba/%m.log
  max log size = 50
  dns proxy = no

[SambaShareVM]
        comment = sambaShareVM
        inherit acls = no
        inherit permissions = yes
        valid user = @smbusers
        path = /mnt/samba/
        read only = no
        guest ok = no' > /etc/samba/smb.conf

# Create smbusers group

groupadd smbusers

# Ask for the users name.


read -p 'Enter the username to create: ' USER_NAME


# Ask for the real name.

read -p 'Enter the full name of the person who this account is for: ' COMMENT

# Ask for the password.



read -p 'Enter the password to use for the account: ' PASSWORD

# Ask for the samba password required to access the samba folder share

read -p 'Enter the password you wish to use to access your samba shared folder: ' SMBPASSWORD

# Create user

useradd -c "${COMMENT}" -m ${USER_NAME}

# Check to see if the useradd command succeeded

# We dont want to the tell the user that an account was created when it hasnt been

if [[ "${?}" -ne 0 ]]

then

  echo 'The account could not be created.'

  exit 1

fi

# Set the password for the user.

echo ${USER_NAME}:${PASSWORD} | chpasswd

#Check the password could be set if not inform the user.
if [[ "${?}" -ne 0 ]]

then

  echo 'The password for the account could not be set.'

  exit 1

fi

# set the smbpassword for the user


(echo ${SMBPASSWORD}; echo ${SMBPASSWORD}) | smbpasswd -as ${USER_NAME}

# Check if the smbpassword could be created if not inform user.

if [[ "${?}" -ne 0 ]]

then

  echo 'The password for the account could not be set.'

  exit 1

fi


# Add the user to the group smbusers

usermod -aG smbusers ${USER_NAME}

# Force user to change password on first login.

#passwd -e ${USER_NAME}

# Diplay the username, password and the host where the user was created.

echo

echo 'username:'

echo "${USER_NAME}"

echo

echo 'password:'

echo "${PASSWORD}"

echo 'Your samba share password is:'

echo "${SMBPASSWORD}"

echo 'host:'

echo "${HOSTNAME}"

# Set permissions on samba share

chown -R 775 /mnt/samba

#Enable samba to start on boot

systemctl enable smbd

#Start the samba service

systemctl start smbd

exit 0
