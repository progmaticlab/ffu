#!/bin/bash 

set -o xtrace

ansible-playbook -c local -i localhost, ffu/playbook-ssh.yaml

ansible-playbook -c local -i localhost, ffu/playbook-nics.yaml

ansible-playbook -c local -i localhost, ffu/playbook-nics-fix.yaml

sudo reboot

