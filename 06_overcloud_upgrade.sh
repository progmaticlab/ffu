#!/bin/bash 

set -o xtrace

source stackrc
./ffu/update_nic_templates.sh

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

