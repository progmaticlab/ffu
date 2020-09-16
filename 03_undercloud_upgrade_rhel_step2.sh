#!/bin/bash -eux

sudo dnf -y remove python2*

sudo subscription-manager release --set=8.2
sudo subscription-manager repos --disable=*
sudo subscription-manager repos \
  --enable=rhel-8-for-x86_64-baseos-eus-rpms \
  --enable=rhel-8-for-x86_64-appstream-eus-rpms \
  --enable=rhel-8-for-x86_64-highavailability-eus-rpms \
  --enable=ansible-2.9-for-rhel-8-x86_64-rpms \
  --enable=openstack-16.1-for-rhel-8-x86_64-rpms \
  --enable=fast-datapath-for-rhel-8-x86_64-rpms

sudo dnf module disable -y container-tools:rhel8
sudo dnf module enable -y container-tools:2.0

sudo dnf distro-sync -y 

echo "Perform reboot: sudo reboot"
