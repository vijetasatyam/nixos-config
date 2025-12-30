# containers.nix
# this config houses all the config related to containers like docker and podman
# pkgs.podman
#
# pkgs.podman-compose
#
# pkgs.pods(use flathub/flatpak)
# pkgs.freerdp(use flathub/flatpak)
#
#
# config for podman
#
#
# Initial configuration

# To properly support Podman's container restart policy, conmon needs fdescfs(5) to be mounted on /dev/fd.

# If /dev/fd is not already mounted:

# mount -t fdescfs fdesc /dev/fd

# To make it permanent, add the following line to /etc/fstab:

# fdesc   /dev/fd         fdescfs         rw      0       0

# To start Podman after reboot:

# service podman enable

# Networking

# Container networking relies on NAT to allow container network packets out to the host's network. This requires a PF firewall to perform the translation. A simple example is included - to use it:

# cp /usr/local/etc/containers/pf.conf.sample /etc/pf.conf

# Edit /etc/pf.conf and set v4egress_if, v6egress_if variables to your network interface(s)s

# Enable and start pf:

# service pf enable
# service pf start

# The sample PF configuration includes support for port redirections. These are implemented as redirect rules in anchors nested under cni-rdr.

# Support for redirecting connections from the container host to services running inside a container is included for FreeBSD 13.3 and later. To enable this, first load the pf kernel module and enable PF support for these redirections using sysctl:

# echo 'pf_load="YES"' >> /boot/loader.conf
# kldload pf
# sysctl net.pf.filter_local=1
# echo 'net.pf.filter_local=1' >> /etc/sysctl.conf.local
# service pf restart

# Redirect rules will work if the destination address is localhost (e.g. 127.0.0.1 or ::1) - to enable this, the following line must be included in your /etc/pf.conf:

# nat-anchor "cni-rdr/*"

# if upgrading from an older version, this needs to be added to /etc/pf.conf.

# For example if host port 1234 is redirected to an http service running in a container, you could connect to it using:

# fetch -o- http://$(hostname):1234

# or

# fetch -o- http://localhost:1234

# Storage

# Container images and related state is stored in /var/db/containers. It is recommended to use ZFS for this:

# zfs create -o mountpoint=/var/db/containers zroot/containers

# If your system cannot use ZFS, change storage.conf to use the vfs storage driver:

# sed -I .bak -e 's/driver = "zfs"/driver = "vfs"/' /usr/local/etc/containers/storage.conf

# Verification

# After following these steps you should be able to run native images:

# podman run --rm docker.io/dougrabson/hello
#
