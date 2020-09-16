#!/bin/bash -e

my_file="$(readlink -e "$0")"
my_dir="$(dirname "$my_file")"

/sbin/ip addr list

sudo systemctl stop openstack-* httpd haproxy mariadb rabbitmq* docker xinetd

sudo yum -y remove *el7ost* galera* haproxy* \
    httpd mysql* pacemaker* xinetd python-jsonpointer \
    qemu-kvm-common-rhev qemu-img-rhev rabbit* \
    redis* \
    -- \
    -*openvswitch* -python-docker -python-PyMySQL \
    -python-pysocks -python2-asn1crypto -python2-babel \
    -python2-cffi -python2-cryptography -python2-dateutil \
    -python2-idna -python2-ipaddress -python2-jinja2 \
    -python2-jsonpatch -python2-markupsafe -python2-pyOpenSSL \
    -python2-requests -python2-six -python2-urllib3 \
    -python-httplib2 -python-passlib -python2-netaddr -ceph-ansible

sudo rm -rf /etc/httpd /var/lib/docker

sudo yum install -y leapp

sudo tar -xzf $my_dir/leapp-data8.tar.gz -C /etc/leapp/files

sudo subscription-manager refresh

echo 'openvswitch2.11' | sudo tee -a /etc/leapp/transaction/to_remove
echo 'openvswitch2.13' | sudo tee -a /etc/leapp/transaction/to_install
echo 'ceph-ansible' | sudo tee -a /etc/leapp/transaction/to_keep

sudo leapp upgrade --debug \
  --enablerepo rhel-8-for-x86_64-baseos-eus-rpms \
  --enablerepo rhel-8-for-x86_64-appstream-eus-rpms \
  --enablerepo fast-datapath-for-rhel-8-x86_64-rpms \
  --enablerepo ansible-2.9-for-rhel-8-x86_64-rpms

sudo touch /.autorelabel

echo "Perform reboot: sudo reboot"
