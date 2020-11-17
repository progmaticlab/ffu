#!/bin/bash -eux

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"


exec 3>&1 1> >(tee ${0}.log) 2>&1
echo $(date) "------------------ STARTED: $0 -------------------"

cd ~
source stackrc
source rhosp-environment.sh

role_file="$(pwd)/tripleo-heat-templates/roles_data_contrail_aio.yaml"

sed -i '/ceph3_.*\|.*_stein/d' containers-prepare-parameter.yaml

tls_env_files=''
if [[ -n "$ENABLE_TLS" ]] ; then
  tls_env_files+=' -e tripleo-heat-templates/environments/contrail/contrail-tls.yaml'
  tls_env_files+=' -e tripleo-heat-templates/environments/ssl/tls-everywhere-endpoints-dns.yaml'
  tls_env_files+=' -e tripleo-heat-templates/environments/services/haproxy-public-tls-certmonger.yaml'
  tls_env_files+=' -e tripleo-heat-templates/environments/ssl/enable-internal-tls.yaml'
else
  # use names even w/o tls case
  tls_env_files+=' -e tripleo-heat-templates/environments/contrail/endpoints-public-dns.yaml'
fi

openstack overcloud upgrade converge -y \
  --templates tripleo-heat-templates/ \
  --stack overcloud --libvirt-type kvm \
  --roles-file $role_file \
  -e tripleo-heat-templates/environments/rhsm.yaml \
  -e rhsm.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-services.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-net-single.yaml \
  -e tripleo-heat-templates/environments/contrail/contrail-plugins.yaml \
  $tls_env_files \
  -e misc_opts.yaml \
  -e contrail-parameters.yaml \
  -e containers-prepare-parameter.yaml \
  -e tripleo-heat-templates/upgrades-environment.yaml \
  -e tripleo-heat-templates/workaround.yaml

echo $(date) "------------------ FINISHED: $0 ------------------"
