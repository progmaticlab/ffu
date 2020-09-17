#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

cd ~
source stackrc

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
name=`sudo hiera container_image_prepare_node_names | sed 's/[]["]//g'`
grep DockerInsecureRegistryAddress contrail-parameters.yaml || echo "  DockerInsecureRegistryAddress: $name" >> contrail-parameters.yaml

$my_dir/update_nic_templates.sh

role_file="$(pwd)/tripleo-heat-templates/roles_data_contrail_aio.yaml"

./tripleo-heat-templates/tools/process-templates.py --clean \
  -r $role_file \
  -p tripleo-heat-templates/

./tripleo-heat-templates/tools/process-templates.py \
  -r $role_file \
  -p tripleo-heat-templates/

openstack overcloud upgrade prepare --templates tripleo-heat-templates/ \
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
