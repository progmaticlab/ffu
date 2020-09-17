#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

ansible-playbook -c local -i localhost, $my_dir/playbook-ssh.yaml

ansible-playbook -c local -i localhost, $my_dir/playbook-nics.yaml

ansible-playbook -c local -i localhost, $my_dir/playbook-nics-vlans.yaml

echo "Perform reboot: sudo reboot"
