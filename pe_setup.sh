#!/usr/bin/env bash

# configure locale support for en_US.UTF-8
sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8

# download and unpack the Puppet Enterprise tarball
curl -JL 'https://pm.puppet.com/cgi-bin/download.cgi?dist=ubuntu&rel=22.04&arch=amd64&ver=latest' -o ~/puppet-enterprise-2025.1.0-ubuntu-22.04-amd64.tar.gz && tar -xzf ~/puppet-enterprise-2025.1.0-ubuntu-22.04-amd64.tar.gz -C ~

# install Puppet Enterprise
sudo ~/puppet-enterprise-2025.1.0-ubuntu-22.04-amd64/puppet-enterprise-installer

# ask the user to configure the password for the PE console
echo "Please enter the password for the Puppet Enterprise console:"
read -s PASSWORD

sudo puppet infrastructure console_password --password=$PASSWORD

# trigger puppet agent 2 times to ensure the node is fully configured
sudo puppet agent -t 
sudo puppet agent -t

# install pdk
wget -O ~/puppet-tools-release-jammy.deb https://apt.puppet.com/puppet-tools-release-jammy.deb
sudo dpkg -i ~/puppet-tools-release-jammy.deb
sudo apt update && sudo apt upgrade
sudo apt install pdk

# set up certificate autosigning
sudo cp autosign.rb /etc/puppetlabs/puppet/
sudo chmod 700 /etc/puppetlabs/puppet/autosign.rb
sudo chown pe-puppet:pe-puppet /etc/puppetlabs/puppet/autosign.rb

echo "PASSWORD_FOR_AUTOSIGNER_SCRIPT" | sudo tee /etc/puppetlabs/puppet/psk > /dev/null
sudo chmod 600 /etc/puppetlabs/puppet/psk
sudo chown pe-puppet:pe-puppet /etc/puppetlabs/puppet/psk

sudo puppet config set autosign /etc/puppetlabs/puppet/autosign.rb --section server

# enable code manager
export PE_CONFIG=/etc/puppetlabs/enterprise/conf.d/pe.conf
sudo sed -i 's/^[[:space:]]*#\("[^"]*code_manager_auto_configure": true\)/  \1/' "$PE_CONFIG"

# set the control repo URL. 
# replace <https://user:token@my control repo.git> with the actual URL of your control repo.
sudo sed -i 's|^[[:space:]]*#\("[^"]*r10k_remote": \).*|\1"<https://user:token@my control repo.git>",|' "$PE_CONFIG"

# run puppet agent to apply the changes
sudo puppet agent -t
sudo puppet agent -t
sudo puppet agetn -t


