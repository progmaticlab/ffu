#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"


exec 3>&1 1> >(tee ${0}.log) 2>&1
echo $(date) "------------------ STARTED: $0 -------------------"

cd ~
source stackrc
source rhosp-environment.sh

for node in $(openstack server list --name overcloud-novacompute -c Name -f value) ; do
  # use separate steps for system_upgrade_prepare + system_upgrade_run
  # instead of united system_upgrade to allow some hack for vhost0
  openstack overcloud upgrade run -y --stack overcloud --tags system_upgrade_prepare --limit $node
  openstack overcloud upgrade run -y --stack overcloud --tags system_upgrade_run --limit $node
  openstack overcloud upgrade run -y --stack overcloud --limit $node
done

echo $(date) "------------------ FINISHED: $0 ------------------"
