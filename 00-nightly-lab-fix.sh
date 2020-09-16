#!/bin/bash -eu

source ~/rhosp-environment.sh

sudo subscription-manager unregister
sudo subscription-manager register --username $RHEL_USER --password $RHEL_PASSWORD
sudo subscription-manager attach --pool $RHEL_POOL_ID
sudo subscription-manager repos --disable=*
sudo subscription-manager repos --enable=rhel-7-server-rpms \
  --enable=rhel-7-server-extras-rpms \
  --enable=rhel-7-server-rh-common-rpms \
  --enable=rhel-ha-for-rhel-7-server-rpms \
  --enable=rhel-7-server-openstack-13-rpms \
  --enable=rhel-7-server-rhceph-3-tools-rpms

sudo rm -f /etc/yum.repos.d/local.repo
