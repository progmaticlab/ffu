#!/bin/bash 

set -o xtrace

mv tripleo-heat-templates tripleo-heat-templates.rhosp13
cp -r /usr/share/openstack-tripleo-heat-templates tripleo-heat-templates
git clone https://review.opencontrail.org/tungstenfabric/tf-tripleo-heat-templates -b stable/train
cp -r tf-tripleo-heat-templates/* tripleo-heat-templates/

cp ffu/upgrades-environment.yaml tripleo-heat-templates/
cp ffu/workaround.yaml tripleo-heat-templates/
cp ffu/rhsm.yaml .

#Check if this works
name=`sudo hiera container_image_prepare_node_names | sed 's/[]["]//g'`
grep DockerInsecureRegistryAddress contrail-parameters.yaml || echo "  DockerInsecureRegistryAddress: $name" >> contrail-parameters.yaml

source stackrc; tripleo-ansible-inventory --static-yaml-inventory ~/inventory.yaml
#For nightly lab
#sed -i 's/ansible_ssh_user: heat-admin/ansible_ssh_user: stack/' ~/inventory.yaml
ansible-playbook -i ~/inventory.yaml ffu/playbook-leapp-data.yaml
ansible-playbook -i ~/inventory.yaml ffu/playbook-nics.yaml
ansible-playbook -i ~/inventory.yaml ffu/playbook-nics-vlans.yaml
ansible-playbook overcloud_Compute -i ~/inventory.yaml ffu/playbook-nics-vhost0.yaml
ansible-playbook -i ~/inventory.yaml ffu/playbook-ssh.yaml


echo Rebooting overcloud
ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs cluster stop"
ansible-playbook  -i ~/inventory.yaml -l overcloud_ContrailController --forks=1 ffu/playbook-overcloud_node_reboot.yaml
ansible overcloud_Controller -i ~/inventory.yaml -m ping
ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs cluster start"
ansible-playbook  -i ~/inventory.yaml -l overcloud_ContrailController --forks=1 ffu/playbook-overcloud_node_reboot.yaml
ansible overcloud_ContrailController -i ~/inventory.yaml -m ping
ansible-playbook  -i ~/inventory.yaml -l overcloud_Compute ffu/playbook-overcloud_node_reboot.yaml
ansible overcloud_Compute -i ~/inventory.yaml -m ping

ansible overcloud_Controller -i ~/inventory.yaml -b -m shell -a "pcs status"

