#!/bin/bash -e

ansible-playbook -c local -i localhost, ffu/playbook-ssh.yaml

ansible-playbook -c local -i localhost, ffu/playbook-nics.yaml

ansible-playbook -c local -i localhost, ffu/playbook-nics-vlans.yaml

echo "Perform reboot: sudo reboot"
