#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

cd ~
source stackrc
source rhosp-environment.sh

for node in $(openstack server list --name overcloud-novacompute -c Name -f value) ; do
  # use separate steps for system_upgrade_prepare + system_upgrade_run
  # instead of united system_upgrade to allow some hack for vhost0
  openstack overcloud upgrade run --stack overcloud --tags system_upgrade_prepare --limit $node
  openstack overcloud upgrade run --stack overcloud --tags system_upgrade_run --limit $node
  openstack overcloud upgrade run --stack overcloud --limit $node
done
