lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC
bootloader --timeout=1 --append="console=tty1 console=ttyS0,115200n8"
auth --enableshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=cockpit
network
services --enabled=sshd
rootpw --lock

user --name=node --lock
firstboot --disabled
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --fstype=xfs --size=1024
part pv.01 --grow --size=50176

volgroup ovirt --pesize=4096 pv.01

logvol / --fstype=xfs --name=root --vgname=ovirt --size=6144 --grow
logvol /home --fstype=xfs --name=home --vgname=ovirt --size=1024 --fsoptions="nodev"
logvol /tmp --fstype=xfs --name=tmp --vgname=ovirt --size=2048 --fsoptions="nodev,noexec,nosuid"
logvol /var --fstype=xfs --name=var --vgname=ovirt --size=20480 --fsoptions="nodev"
logvol /var/log --fstype=xfs --name=log --vgname=ovirt --size=10240 --fsoptions="nodev"
logvol /var/log/audit --fstype=xfs --name=audit --vgname=ovirt --size=1024 --fsoptions="nodev"
logvol swap --name=swap --vgname=ovirt --size=8192

poweroff

# Packages
%packages
@core
dnf
kernel
yum
nfs-utils
dnf-utils
grub2-pc
# oVirt is not using EFI
#grub2-efi-x64
#shim

# pull firmware packages out
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-ivtv-firmware
-iwl1000-firmware
-iwl100-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-iwl7265-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware

# cloud-init does magical things with EC2 metadata, including provisioning
# a user account with ssh keys.
cloud-init
## Adding a dependency for cloud-init as recommended by tdawson
python3-jsonschema

# allows the host machine to issue commands to the guest operating system
qemu-guest-agent

# need this for growpart, because parted doesn't yet support resizepart
# https://bugzilla.redhat.com/show_bug.cgi?id=966993
#cloud-utils

cloud-utils-growpart
# We need this image to be portable; also, rescue mode isn't useful here.
dracut-config-generic
dracut-norescue

# Needed by oVirt
firewalld

# cherry-pick a few things from @base
tar
tcpdump
rsync

# Some things from @core we can do without in a minimal install
-biosdevname
-plymouth
NetworkManager
-iprutils

# Because we need networking
dhcp-client

# Minimal Cockpit web console
cockpit-ws
cockpit-system

# Add rng-tools as source of entropy
rng-tools

# Additions for STIG support and oVirt required packages
aide
cockpit
dracut-fips
grub2
opensc
openscap
openscap-utils
scap-security-guide
tmux

# Needed for supporting upgrade from 4.3 with SSO configured (RHBZ#1866811)
mod_auth_gssapi
# Additional packages for handling SSO enabled systems we recommend (RHBZ#1866811)
mod_session

# Distribution specific packages or with different name for different distributions
%end

#
# Adding upstream oVirt
#
%post --erroronfail
set -x
#ProLinux: replace the role of ovirt-release rpm
cat <<EOF > /etc/yum.repos.d/ovirt.repo
[ovirt4pl]
name=oVirt-4.4 for ProLinux
baseurl=http://prolinux-repo.tmaxos.com/ovirt/4.4/el8/x86_64/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-prolinux-8-release
gpgcheck=1
EOF

# Use baseurl instead of repo to ensure we use the latest rpms
#sed -i "s/^mirrorlist/#mirrorlist/ ; s/^#baseurl/baseurl/" $(find /etc/yum.repos.d/ovirt*.repo -type f ! -name "*dep*")

dnf module enable -y pki-deps 389-ds postgresql:12 mod_auth_openidc parfait

dnf install -y \
	ovirt-engine \
	ovirt-engine-dwh \
	ovirt-provider-ovn

dnf install -y \
	ovirt-engine-extension-aaa-ldap-setup

# Additional packages for handling SSO enabled systems we recommend (RHBZ#1866811)
dnf install -y \
	ovirt-engine-extension-aaa-misc

# Additional package that we recommend for more flexible engine logging
dnf install -y \
	ovirt-engine-extension-logger-log4j

#
echo "Creating a partial answer file"
#
cat > /root/ovirt-engine-answers <<__EOF__
# Answers
[environment:default]
OVESETUP_CORE/engineStop=none:None
OVESETUP_DIALOG/confirmSettings=bool:True
OVESETUP_DB/database=str:engine
OVESETUP_DB/fixDbViolations=none:None
OVESETUP_DB/secured=bool:False
OVESETUP_DB/securedHostValidation=bool:False
OVESETUP_DB/host=str:localhost
OVESETUP_DB/user=str:engine
OVESETUP_DB/port=int:5432
OVESETUP_DWH_CORE/enable=bool:True
OVESETUP_DWH_CONFIG/dwhDbBackupDir=str:/var/lib/ovirt-engine-dwh/backups
OVESETUP_DWH_PROVISIONING/postgresProvisioningEnabled=bool:True
OVESETUP_DWH_DB/secured=bool:False
OVESETUP_DWH_DB/host=str:localhost
OVESETUP_ENGINE_CORE/enable=bool:True
OVESETUP_SYSTEM/nfsConfigEnabled=bool:False
OVESETUP_SYSTEM/memCheckEnabled=bool:False
OVESETUP_CONFIG/applicationMode=str:both
OVESETUP_CONFIG/firewallManager=str:firewalld
OVESETUP_CONFIG/storageType=str:nfs
OVESETUP_CONFIG/sanWipeAfterDelete=bool:False
OVESETUP_CONFIG/updateFirewall=bool:True
OVESETUP_CONFIG/websocketProxyConfig=bool:True
OVESETUP_PROVISIONING/postgresProvisioningEnabled=bool:True
OVESETUP_VMCONSOLE_PROXY_CONFIG/vmconsoleProxyConfig=bool:True
OVESETUP_APACHE/configureRootRedirection=bool:True
OVESETUP_APACHE/configureSsl=bool:True
OSETUP_RPMDISTRO/requireRollback=none:None
OSETUP_RPMDISTRO/enableUpgrade=none:None
QUESTION/1/OVESETUP_IGNORE_SNAPSHOTS_WITH_OLD_COMPAT_LEVEL=str:yes
OVESETUP_GRAFANA_CORE/enable=bool:False
__EOF__

echo "Enabling ssh_pwauth in cloud.cfg.d"
cat > /etc/cloud/cloud.cfg.d/42_ovirt_appliance.cfg <<__EOF__
# Enable ssh pwauth by default. This ensures that ssh_pwauth is
# even enabled when cloud-init does not find a seed.
ssh_pwauth: True
__EOF__

echo "Enabling fstrim"
systemctl enable fstrim.timer

echo "Enabling cockpit socket"
systemctl enable cockpit.socket

# this is installed by default but we don't need it in virt
echo "Removing linux-firmware package."
dnf -C -y remove linux-firmware

#
# Enable the guest agent
#
dnf install -y qemu-guest-agent
systemctl enable qemu-guest-agent

rm -vf /etc/sysconfig/network-scripts/ifcfg-e*

%end
