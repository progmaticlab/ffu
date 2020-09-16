#!/bin/bash -eux

cd ~
source stackrc

if [ ! -e tripleo-heat-templates.rhosp13 ] ; then
  mv tripleo-heat-templates tripleo-heat-templates.rhosp13
  cp -r /usr/share/openstack-tripleo-heat-templates tripleo-heat-templates
  git clone https://review.opencontrail.org/tungstenfabric/tf-tripleo-heat-templates -b stable/train
  cp -r tf-tripleo-heat-templates/* tripleo-heat-templates/

  cp $my_dir/upgrades-environment.yaml tripleo-heat-templates/
  cp $my_dir/workaround.yaml tripleo-heat-templates/
  #Check if this works
  name=`sudo hiera container_image_prepare_node_names | sed 's/[]["]//g'`
  grep DockerInsecureRegistryAddress contrail-parameters.yaml || echo "  DockerInsecureRegistryAddress: $name" >> contrail-parameters.yaml

  $my_dir/update_nic_templates.sh
fi

openstack overcloud upgrade prepare --templates tripleo-heat-templates/ \
  --stack overcloud --libvirt-type kvm \
  --roles-file tripleo-heat-templates/roles_data_contrail_aio.yaml \
  -e tripleo-heat-templates/upgrades-environment.yaml \
  -e tripleo-heat-templates/environments/rhsm.yaml \
  -e tripleo-heat-templates/workaround.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-services.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-net-single.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-plugins.yaml \
  -e rhsm.yaml \
  -e misc_opts.yaml \
  -e contrail-parameters.yaml \
  -e containers-prepare-parameter.yaml
