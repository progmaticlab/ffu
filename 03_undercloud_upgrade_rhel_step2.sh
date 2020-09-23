#!/bin/bash -eux

sudo dnf -y remove python2*

sudo subscription-manager release --set=8.2
sudo subscription-manager repos --disable=*
sudo subscription-manager repos \
  --enable=rhel-8-for-x86_64-baseos-rpms \
  --enable=rhel-8-for-x86_64-appstream-rpms \
  --enable=rhel-8-for-x86_64-highavailability-rpms \
  --enable=fast-datapath-for-rhel-8-x86_64-rpms \
  --enable=ansible-2-for-rhel-8-x86_64-rpms \
  --enable=openstack-16.1-for-rhel-8-x86_64-rpms \
  --enable=satellite-tools-6.5-for-rhel-8-x86_64-rpms

sudo dnf module disable -y container-tools:rhel8
sudo dnf module enable -y container-tools:2.0

sudo dnf distro-sync -y 

echo "Perform reboot: sudo reboot"
