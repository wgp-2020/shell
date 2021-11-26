#!/bin/bash
echo "----------generate ssh----------"
id_rsa_path="${HOME}/.ssh/id_rsa"
id_rsa_pub_path="${HOME}/.ssh/id_rsa.pub"
auth_path="${HOME}/.ssh/authorized_keys"
ssh_path="${HOME}/.ssh/"
if [ ! -d "$ssh_path" ]
then
        mkdir "$ssh_path"
        ssh-keygen
else
        echo "ssh floder already exists"
fi

if [ ! -f "$auth_path" ]
then
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
else
        echo "authorized_keys already exists"
fi
echo "----------restart ssh----------"
sudo service ssh restart
echo "----------shell id_rsa----------"
cat ~/.ssh/id_rsa
echo "----------shell IP----------"
curl members.3322.org/dyndns/getip
echo "----------shell user----------"
echo "$USER"
