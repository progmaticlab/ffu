#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

cd ~

mv tripleo-heat-templates tripleo-heat-templates.rhosp13
cp -r /usr/share/openstack-tripleo-heat-templates tripleo-heat-templates
git clone https://review.opencontrail.org/tungstenfabric/tf-tripleo-heat-templates -b stable/train
cp -r tf-tripleo-heat-templates/* tripleo-heat-templates/

cp $my_dir/upgrades-environment.yaml tripleo-heat-templates/
cp $my_dir/workaround.yaml tripleo-heat-templates/

#Check if this works
name=`sudo hiera container_image_prepare_node_names | sed 's/[]["]//g'`
grep DockerInsecureRegistryAddress contrail-parameters.yaml || echo "  DockerInsecureRegistryAddress: $name" >> contrail-parameters.yaml

source stackrc
#For nightly lab
#tripleo-ansible-inventory --ansible_ssh_user stack -static-yaml-inventory ~/inventory.yaml
tripleo-ansible-inventory -static-yaml-inventory ~/inventory.yaml

ansible-playbook -i ~/inventory.yaml $my_dir/playbook-leapp-data.yaml
ansible-playbook -i ~/inventory.yaml $my_dir/playbook-nics.yaml
ansible-playbook -i ~/inventory.yaml $my_dir/playbook-nics-vlans.yaml
ansible-playbook overcloud_Compute -i ~/inventory.yaml $my_dir/playbook-nics-vhost0.yaml
ansible-playbook -i ~/inventory.yaml $my_dir/playbook-ssh.yaml

echo Rebooting overcloud
ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs cluster stop"
ansible-playbook  -i ~/inventory.yaml -l overcloud_ContrailController --forks=1 $my_dir/playbook-overcloud_node_reboot.yaml
ansible overcloud_Controller -i ~/inventory.yaml -m ping
ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs cluster start"
ansible-playbook  -i ~/inventory.yaml -l overcloud_ContrailController --forks=1 $my_dir/playbook-overcloud_node_reboot.yaml
ansible overcloud_ContrailController -i ~/inventory.yaml -m ping
ansible-playbook  -i ~/inventory.yaml -l overcloud_Compute $my_dir/playbook-overcloud_node_reboot.yaml
ansible overcloud_Compute -i ~/inventory.yaml -m ping

ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs status"

