#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

cd ~
source stackrc
source ~/rhosp-environment.sh

if [ ! -e tripleo-heat-templates.rhosp13 ] ; then
  mv tripleo-heat-templates tripleo-heat-templates.rhosp13
fi

rm -rf tripleo-heat-templates
cp -r /usr/share/openstack-tripleo-heat-templates tripleo-heat-templates
rm -rf tf-tripleo-heat-templates
git clone https://review.opencontrail.org/tungstenfabric/tf-tripleo-heat-templates -b stable/train
cp -r tf-tripleo-heat-templates/* tripleo-heat-templates/

cp $my_dir/upgrades-environment.yaml tripleo-heat-templates/
cp $my_dir/workaround.yaml tripleo-heat-templates/
#Check if this works
name=$(sudo hiera container_image_prepare_node_names | sed 's/[]["]//g')
grep DockerInsecureRegistryAddress contrail-parameters.yaml || echo "  DockerInsecureRegistryAddress: ${name}:8787" >> contrail-parameters.yaml

$my_dir/update_nic_templates.sh

role_file="$(pwd)/tripleo-heat-templates/roles_data_contrail_aio.yaml"

./tripleo-heat-templates/tools/process-templates.py --clean \
  -r $role_file \
  -p tripleo-heat-templates/

./tripleo-heat-templates/tools/process-templates.py \
  -r $role_file \
  -p tripleo-heat-templates/

openstack overcloud upgrade prepare \
  --templates tripleo-heat-templates/ \
  --stack overcloud --libvirt-type kvm \
  --roles-file $role_file \
  -e docker_registry.yaml \
  -e tripleo-heat-templates/environments/rhsm.yaml \
  -e rhsm.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-services.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-net-single.yaml \
  -e tripleo-heat-templates/environments/contrail/endpoints-public-dns.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-plugins.yaml \
  -e misc_opts.yaml \
  -e contrail-parameters.yaml \
  -e containers-prepare-parameter.yaml \
  -e tripleo-heat-templates/upgrades-environment.yaml \
  -e tripleo-heat-templates/workaround.yaml

openstack overcloud external-upgrade run --stack overcloud --tags container_image_prepare

ctrl_ip=$(openstack server list --name overcloud-controller-0 -c Networks -f value | cut -d '=' -f2)
[[ -n "$ctrl_ip" ]]

node_admin_username=${NODE_ADMIN_USERNAME:-'heat-admin'}
pcs_bootstrap_node=$(ssh $node_admin_username@$ctrl_ip "sudo hiera -c /etc/puppet/hiera.yaml pacemaker_short_bootstrap_node_name")
[[ -n "$pcs_bootstrap_node" ]]

openstack overcloud external-upgrade run --stack overcloud --tags ceph_systemd \
  -e ceph_ansible_limit=$pcs_bootstrap_node
openstack overcloud upgrade run --stack overcloud --tags system_upgrade --limit $pcs_bootstrap_node
openstack overcloud external-upgrade run --stack overcloud --tags system_upgrade_transfer_data
openstack overcloud upgrade run --stack overcloud --playbook upgrade_steps_playbook.yaml --tags nova_hybrid_state --limit all
openstack overcloud upgrade run --stack overcloud --limit $pcs_bootstrap_node

upgraded_controllers=$pcs_bootstrap_node
for node in $(openstack server list --name overcloud-controller -c Name -f value | grep -v "$pcs_bootstrap_node" ) ; do
  openstack overcloud external-upgrade run --stack overcloud --tags ceph_systemd \
    -e ceph_ansible_limit=$node
  openstack overcloud upgrade run --stack overcloud --tags system_upgrade --limit $node
  upgraded_controllers+=",$node"
  openstack overcloud upgrade run --stack overcloud --limit $upgraded_controllers
done

for node in $(openstack server list --name overcloud-contrailcontroller -c Name -f value) ; do
  openstack overcloud upgrade run --stack overcloud --tags system_upgrade --limit $node
  openstack overcloud upgrade run --stack overcloud --limit $node
done

for node in $(openstack server list --name overcloud-novacompute -c Name -f value) ; do
  openstack overcloud upgrade run --stack overcloud --tags system_upgrade --limit $node
  openstack overcloud upgrade run --stack overcloud --limit $node
done

sed -i '/ceph3_.*\|.*_stein/d' containers-prepare-parameter.yaml

openstack overcloud upgrade converge \
  --templates tripleo-heat-templates/ \
  --stack overcloud --libvirt-type kvm \
  --roles-file $role_file \
  -e docker_registry.yaml \
  -e tripleo-heat-templates/environments/rhsm.yaml \
  -e rhsm.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-services.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-net-single.yaml \
  -e tripleo-heat-templates/environments/contrail/endpoints-public-dns.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-plugins.yaml \
  -e misc_opts.yaml \
  -e contrail-parameters.yaml \
  -e containers-prepare-parameter.yaml \
  -e tripleo-heat-templates/upgrades-environment.yaml \
  -e tripleo-heat-templates/workaround.yaml
