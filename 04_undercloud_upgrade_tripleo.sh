#!/bin/bash 

set -o xtrace

sudo dnf install -y python3-tripleoclient
cp ffu/containers-prepare-parameter.yaml .

if grep -q "containers-prepare-parameter.yaml" undercloud.conf; then
    echo "undercloud.conf was already fixed. Skipping"
else
    source rhosp-environment.sh; sed -i "/\[DEFAULT\]/ a undercloud_public_host = ${undercloud_public_host}" undercloud.conf
    source rhosp-environment.sh; sed -i "/\[DEFAULT\]/ a undercloud_admin_host = ${undercloud_admin_host}" undercloud.conf
    sed -i "/\[DEFAULT\]/ a container_images_file = containers-prepare-parameter.yaml" undercloud.conf
    sed -i "s/eth/em/" undercloud.conf
fi

cat undercloud.conf
source stackrc; openstack undercloud upgrade -y

echo undercloud tripleo upgrade finished. Checking status

sudo systemctl list-units "tripleo_*"
sudo podman ps

