#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

sudo dnf install -y python3-tripleoclient

source ~/rhosp-environment.sh
sed -i '/undercloud_public_host\|undercloud_admin_host\|container_images_file/d' undercloud.conf
sed -i "/\[DEFAULT\]/ a undercloud_public_host = ${undercloud_public_host}" undercloud.conf
sed -i "/\[DEFAULT\]/ a undercloud_admin_host = ${undercloud_admin_host}" undercloud.conf
sed -i "/\[DEFAULT\]/ a container_images_file = containers-prepare-parameter.yaml" undercloud.conf
sed -i "s/eth/em/" undercloud.conf
cat undercloud.conf

source stackrc
openstack undercloud upgrade -y

echo undercloud tripleo upgrade finished. Checking status

sudo systemctl list-units "tripleo_*"
sudo podman ps --all
