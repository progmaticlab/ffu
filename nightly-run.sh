#!/bin/bash -e

source ~/nightly-env.sh

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
}

function wait_ssh() {
  local user=$1	
  local addr=$2
  local ssh_key=${3:-''}
  local max_iter=${4:-20}
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
  echo Node is back!
}

checkForVariable() {
  local env_var=
  env_var=$(declare -p "$1")
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
echo Generating yaml files
cat ffu/rhsm.yaml.template | envsubst > ffu/rhsm.yaml
cat ffu/containers-prepare-parameter.yaml.template | envsubst > ffu/containers-prepare-parameter.yaml


echo Copiyng ffu/* to undercloud node
scp -r ~/ffu $SSH_USER@$mgmt_ip:
scp -r ~/nightly-env.sh $SSH_USER@$mgmt_ip:rhosp-environment.sh

echo Preparing for undercloud RHEL upgrade

run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'ffu/00-nightly-lab-fix.sh'
run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'ffu/01_undercloud_prepare.sh'
echo Rebooting undercloud
run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'sudo reboot'

echo Waiting undercloud return after reboot
wait_ssh $SSH_USER $mgmt_ip $ssh_private_key

run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'ffu/02_undercloud_upgrade_rhel_step1.sh'
echo Rebooting undercloud
run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'sudo reboot'

echo Waiting undercloud return after reboot. It takes long time!
wait_ssh $SSH_USER $mgmt_ip $ssh_private_key 120

run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'ffu/03_undercloud_upgrade_rhel_step2.sh'
echo Rebooting undercloud
run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'sudo reboot'
wait_ssh $SSH_USER $mgmt_ip $ssh_private_key

run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'ffu/04_undercloud_upgrade_tripleo.sh'

#######################################################
#                   OVERCLOUD                         #
#######################################################


run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'ffu/05_overcloud_prepare.sh'

run_ssh $SSH_USER $mgmt_ip $ssh_private_key 'ffu/06_overcloud_upgrade.sh'
