#!/bin/bash


export ZUUL_URL="https://git.openstack.org"
export ZUUL_PROJECT="openstack/oslo.messaging"
export ZUUL_BRANCH="master"
export ZUUL_REF="HEAD"
 
DEVSTACK_JOB = <<JOB
export PYTHONUNBUFFERED=true
export DEVSTACK_GATE_TEMPEST=1
export DEVSTACK_GATE_TEMPEST_FULL=1
export DEVSTACK_GATE_NEUTRON=1
export PROJECTS="openstack/devstack-plugin-amqp1 $PROJECTS"
export DEVSTACK_LOCAL_CONFIG="enable_plugin devstack-plugin-amqp1 git://git.openstack.org/openstack/devstack-plugin-amqp1"
 export DEVSTACK_PROJECT_FROM_GIT="oslo.messaging"
cp devstack-gate/devstack-vm-gate-wrap.sh ./safe-devstack-vm-gate-wrap.sh
./safe-devstack-vm-gate-wrap.sh
JOB
    
yum update
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
yum -y install git
yum -y install emacs
pip install tox

ssh-keygen -N "" -t rsa -f /root/.ssh/id_rsa
KEY_CONTENTS=$(cat /root/.ssh/id_rsa.pub | awk '{print $2}' )
git clone https://git.openstack.org/openstack-infra/system-config /opt/system-config
/opt/system-config/install_puppet.sh
/opt/system-config/install_modules.sh
puppet apply --modulepath=/opt/system-config/modules:/etc/puppet/modules -e 'class { openstack_project::single_use_slave: install_users => false,   enable_unbound => true, ssh_key => \"$KEY_CONTENTS\" }'
echo "jenkins ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jenkins
export WORKSPACE=/home/jenkins/workspace/testing
mkdir -p "$WORKSPACE"
cd $WORKSPACE
git clone --depth 1 https://git.openstack.org/openstack-infra/devstack-gate
 
exec 0<&- ${DEVSTACK_JOB}
