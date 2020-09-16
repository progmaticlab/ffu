#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

cd ~
source stackrc

# TODO: ita fails - no python3 on overcloud at this moment
# openstack tripleo validator run --group pre-upgrade

#For nightly lab
#tripleo-ansible-inventory --ansible_ssh_user stack -static-yaml-inventory ~/inventory.yaml
tripleo-ansible-inventory -static-yaml-inventory ~/inventory.yaml

ansible-playbook -i ~/inventory.yaml $my_dir/playbook-leapp-data.yaml
ansible-playbook -i ~/inventory.yaml $my_dir/playbook-nics.yaml
ansible-playbook -i ~/inventory.yaml $my_dir/playbook-nics-vlans.yaml
ansible-playbook overcloud_Compute -i ~/inventory.yaml $my_dir/playbook-nics-vhost0.yaml
ansible-playbook -i ~/inventory.yaml $my_dir/playbook-ssh.yaml


echo "Rebooting overclouds"
ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs cluster stop"
ansible-playbook  -i ~/inventory.yaml -l overcloud_ContrailController --forks=1 $my_dir/playbook-overcloud_node_reboot.yaml
ansible overcloud_Controller -i ~/inventory.yaml -m ping
ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs cluster start"
ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs status"

ansible-playbook  -i ~/inventory.yaml -l overcloud_ContrailController --forks=1 $my_dir/playbook-overcloud_node_reboot.yaml
ansible overcloud_ContrailController -i ~/inventory.yaml -m ping

ansible-playbook  -i ~/inventory.yaml -l overcloud_Compute $my_dir/playbook-overcloud_node_reboot.yaml
ansible overcloud_Compute -i ~/inventory.yaml -m ping
