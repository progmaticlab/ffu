#!/bin/bash

STACK_NAME="overcloud"
ROLES_DATA="/home/stack/tripleo-heat-templates/roles_data_contrail_aio.yaml"
NIC_CONFIG_LINES=$(openstack stack environment show $STACK_NAME | grep "::Net::SoftwareConfig" | sed -E 's/ *OS::TripleO::// ; s/::Net::SoftwareConfig:// ; s/ http.*user-files/ /')
echo "$NIC_CONFIG_LINES"
echo "$NIC_CONFIG_LINES" | while read LINE; do
    ROLE=$(echo "$LINE" | awk '{print $1;}')
    NIC_CONFIG=$(echo "$LINE" | awk '{print $2;}')

    echo ROLES_DATA: $ROLES_DATA
    echo ROLE: $ROLE
    echo NIC_CONFIG: $NIC_CONFIG
    python3 /usr/share/openstack-tripleo-heat-templates/tools/merge-new-params-nic-config-script.py \
            --tht-dir /home/stack/tripleo-heat-templates \
            --roles-data $ROLES_DATA \
            --role-name "$ROLE" \
            --discard-comments yes \
            --template "$NIC_CONFIG"
done
