#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

exec 3>&1 1> >(tee ${0}.log) 2>&1
echo $(date) "------------------ STARTED: $0 -------------------"

cd ~
source stackrc
source rhosp-environment.sh

ansible-playbook -c local -i localhost, $my_dir/playbook-ssh.yaml
ansible-playbook -c local -i localhost, $my_dir/playbook-nics.yaml
ansible-playbook -c local -i localhost, $my_dir/playbook-nics-vlans.yaml

echo "Perform reboot: sudo reboot"

echo $(date) "------------------ FINISHED: $0 ------------------"
