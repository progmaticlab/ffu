#!/bin/bash -eu

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

cd
source nightly-env.sh

function run_ssh() {
  local user=$1	
  local addr=$2
  local ssh_key=${3:-''}
  local command=$4
  local ssh_opts='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no'
  if [[ -n "$ssh_key" ]] ; then
    ssh_opts+=" -i $ssh_key"
  fi
  echo ------------------------- Running on $user@$addr -----------------------------------
  echo ---  Command: $command
  ssh ${user}@${addr} ${command}
  if [ $? -ne 0 ]
  then
     echo ===================== FAIL: ${command}
     echo Exiting
     exit 1
  else
     echo --------------------- Command ${command} finished successfull
  fi
}

function run_ssh_undercloud() {
  run_ssh $SSH_USER $mgmt_ip $ssh_private_key "NODE_ADMIN_USERNAME=$SSH_USER $@"
}

function wait_ssh() {
  local user=$1	
  local addr=$2
  local ssh_key=${3:-''}
  local max_iter=${4:-120}
  local iter=0
  local ssh_opts='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no'
  if [[ -n "$ssh_key" ]] ; then
    ssh_opts+=" -i $ssh_key"
  fi
  local tf=$(mktemp)
  sleep 60
  while ! scp $ssh_opts -B $tf ${user}@${addr}:/tmp/ ; do
    if (( iter >= max_iter )) ; then
      echo "Could not connect to VM $addr"
      exit 1
    fi
    echo "Waiting for VM $addr..."
    sleep 30
    ((++iter))
  done
  echo "Node is back!"
}

function reboot_and_wait_undercloud() {
  echo "Rebooting undercloud"
  run_ssh_undercloud 'sudo reboot'
  wait_ssh $SSH_USER $mgmt_ip $ssh_private_key
}

function checkForVariable() {
  local env_var=$(declare -p "$1")
  if !  [[ -v $1 && $env_var =~ ^declare\ -x ]]; then
    echo "Error: Define $1 environment variable"
    exit 1
  fi
}

checkForVariable SSH_USER
checkForVariable RHEL_USER
checkForVariable RHEL_PASSWORD
checkForVariable RHEL_POOL_ID
checkForVariable mgmt_ip
checkForVariable ssh_private_key
checkForVariable undercloud_public_host
checkForVariable undercloud_admin_host

cd

echo "Copiyng ffu/* to undercloud node"
scp -r $my_dir/ffu $SSH_USER@$mgmt_ip:./
scp -r nightly-env.sh $SSH_USER@$mgmt_ip:./rhosp-environment.sh

echo Preparing for undercloud RHEL upgrade

run_ssh_undercloud 'ffu/00-nightly-lab-fix.sh'

echo "Preparing for undercloud RHEL upgrade"
run_ssh_undercloud './ffu/01_undercloud_prepare.sh'
reboot_and_wait_undercloud

run_ssh_undercloud './ffu/02_undercloud_upgrade_rhel_step1.sh'
reboot_and_wait_undercloud

run_ssh_undercloud './ffu/03_undercloud_upgrade_rhel_step2.sh'
reboot_and_wait_undercloud

run_ssh_undercloud './ffu/04_undercloud_upgrade_tripleo.sh'

######################################################
#                  OVERCLOUD                         #
######################################################
run_ssh_undercloud './ffu/06_overcloud_prepare.sh'
run_ssh_undercloud './ffu/07_overcloud_prepare_templates.sh'
run_ssh_undercloud './ffu/08_overcloud_upgrade_prepare.sh'
run_ssh_undercloud './ffu/09_overcloud_upgrade_os.sh'
run_ssh_undercloud './ffu/10_overcloud_upgrade_contrail_ctrl.sh'
run_ssh_undercloud './ffu/11_overcloud_upgrade_compute.sh'
run_ssh_undercloud './ffu/12_overcloud_upgrade_converge.sh'
