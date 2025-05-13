
# Installing Alpine Linux 3.21.3 on OVH VPS Using GRUB

This guide explains how to boot and install Alpine Linux 3.21.3 (or other Linux) on an OVH VPS using GRUB. 
This method uses manual ISO booting via GRUB and does not rely on PXE, netboot, or OVH's OS templates.

Inspired by https://linuxhandbook.com/install-alpine-linux-on-vps/ from the LHB Community.
However, now in OVH's VPS, GRUB is not accessible as easily and /etc/grub.d/00_header needs to be edited.

## Prerequisites

- An OVH VPS with some linux pre-installed
- Access to the OVH KVM console
- SSH access

## 1. Prepare the System

SSH into your VPS:

```bash
ssh root@<your-server-ip>

```

Ensure GRUB is installed:

```bash
ls /boot/grub

```

Install GRUB if missing:

```bash
sudo apt update
sudo apt install grub-pc

```

## 2. Download Alpine Linux ISO

Download the ISO (latest virt version) to the root directory:

```bash
cd /
sudo wget https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-virt-3.21.3-x86_64.iso

```

Optionally verify the hash:

```bash
sha256sum alpine-virt-3.21.3-x86_64.iso

```

Compare with the checksum from the official Alpine release page.

## 3. Configure GRUB to Show the Menu

Edit GRUB settings:

```bash
sudo nano /etc/default/grub

```

Replace contents with:

```ini
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=false
GRUB_FORCE_HIDDEN_MENU="false"
GRUB_TERMINAL="console"

```

Patch `/etc/grub.d/00_header` to force timeout:

```bash
sudo nano /etc/grub.d/00_header

```

In the `make_timeout()` function, update as follows:

```bash
if [ x\$feature_timeout_style = xy ] ; then
  set timeout_style=menu
  set timeout=10
else
  set timeout=10

```

## 4. Reinstall and Update GRUB

```bash
sudo grub-install --target=i386-pc /dev/sda --recheck
sudo update-grub

```

## 5. Reboot into GRUB and Manually Boot ISO

```bash
sudo reboot

```

Open the KVM console in the OVH dashboard. When the GRUB menu appears, press `c` to access the GRUB command line. Run:

```grub
loopback l (hd0,1)/alpine-virt-3.21.3-x86_64.iso
linux (l)/boot/vmlinuz-virt
initrd (l)/boot/initramfs-virt
boot

```

If the ISO is on a different partition, adjust `(hd0,1)` accordingly.

## 6. Mount ISO from RAM

When the system drops to an emergency shell with a boot media error, copy the ISO to RAM and remount:

```sh
mount /dev/sda1 /media/sda1
cp /media/sda1/alpine-virt-3.21.3-x86_64.iso /dev/shm/
umount /dev/sda1
mount -o loop -t iso9660 /dev/shm/alpine-virt-3.21.3-x86_64.iso /media/cdrom
exit

```

This is required before installing Alpine to `/dev/sda`.

## 7. Install Alpine Permanently

After exiting the emergency shell, Alpine will boot into the live environment.

Log in as `root` (no password by default), then start the installer:

```sh
setup-alpine
```

## 8. Enable SSH Access

If SSH login with password is disabled (as it should be for security purposes), log in via KVM and set up key-based authentication:

```sh
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAA... user@host" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh
/etc/init.d/sshd restart

```

Replace the SSH key with your own public key.


## The end

Congrats, you are now free of systemd


