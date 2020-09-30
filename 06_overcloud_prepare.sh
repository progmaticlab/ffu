#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

exec 3>&1 1> >(tee ${0}.log) 2>&1
echo $(date) "------------------ STARTED: $0 -------------------"

cd ~
source stackrc

# TODO: ita fails - no python3 on overcloud at this moment
# openstack tripleo validator run --group pre-upgrade

# Disable PCS fencing
ctrl_ip=$(openstack server list --name overcloud-controller-0 -c Networks -f value | cut -d '=' -f2)
[[ -n "$ctrl_ip" ]]
node_admin_username=${NODE_ADMIN_USERNAME:-'heat-admin'}
pcs_bootstrap_node_name=$(ssh $node_admin_username@$ctrl_ip "sudo hiera -c /etc/puppet/hiera.yaml pacemaker_short_bootstrap_node_name")
pcs_bootstrap_node_ip=$(openstack server list --name $pcs_bootstrap_node_name -c Networks -f value | cut -d '=' -f2)
ssh $node_admin_username@$pcs_bootstrap_node_ip "sudo pcs property set stonith-enabled=false"

#For nightly lab
#tripleo-ansible-inventory --ansible_ssh_user stack -static-yaml-inventory inventory.yaml
tripleo-ansible-inventory --static-yaml-inventory inventory.yaml

ansible-playbook -i inventory.yaml $my_dir/playbook-leapp-data.yaml
ansible-playbook -i inventory.yaml $my_dir/playbook-nics.yaml
ansible-playbook -i inventory.yaml $my_dir/playbook-nics-vlans.yaml
ansible-playbook -i inventory.yaml -l overcloud_Compute $my_dir/playbook-nics-vhost0.yaml
ansible-playbook -i inventory.yaml $my_dir/playbook-ssh.yaml

echo "Rebooting overclouds"
ansible overcloud_Controller -i inventory.yaml -b -m shell -a "pcs cluster stop"
ansible-playbook  -i inventory.yaml -l overcloud --forks=1 $my_dir/playbook-overcloud_node_reboot.yaml
ansible overcloud -i inventory.yaml -m ping
ansible overcloud_Controller -i inventory.yaml -b -m shell -a "pcs cluster start"
ansible overcloud_Controller -i inventory.yaml -b -m shell -a "pcs status"

echo $(date) "------------------ FINISHED: $0 ------------------"
