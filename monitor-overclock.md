# Overclocking a Monitor with Custom EDID

This document outlines how to overclock a 1920×1080@75Hz monitor to 80Hz on a Linux system using EDID injection via the initramfs and systemd-boot. Tested successfully on **Arch** with both **Sway** and **KDE Plasma 6** under **Wayland**.

_Made this so I don't forget again and waste time on this next time..._

---


## Requirements

- Systemd-boot
- mkinitcpio (not dracut or ukify)
- Tools:
  - `edid-decode`
  - `modeline2edid`
  - `cvt12` (or `cvt` or `gtf` but `cvt12` allow reduced blanking on CVT v1.1 for refresh rates not a multiple of 60hz.)
  - Optional: `wxedid` (GUI EDID editor, discovered it afterward but actually pretty good)

---

## Step-by-Step Guide

### 1. Check the Monitor's Current EDID

```bash
edid-decode /sys/class/drm/card1-DP-6/edid
````

Check the EDID for existing DTDs and **monitor range limits**.

---

### 2. Generate a 1920×1080\@80Hz Modeline

Use `cvt12` to create a modeline:

```bash
cvt12 1920 1080 80 -b
```

Example output:

```
Modeline "1920x1080_80.00_rb2"  179.52  1920 1928 1960 2000  1080 1108 1116 1122 +hsync -vsync
```

---

### 3. Convert Modeline to EDID

Create a binary EDID from the modeline:

```bash
echo 'Modeline "1080p80"  179.52  1920 1928 1960 2000  1080 1108 1116 1122 +hsync -vsync' \
  | modeline2edid -
make
```

Edit the `.S` file to change current EDID range limits if necessary by adding:

  ```c
  #define RANGE_LIMITS 48,100,30,100,300
  ```

---

### 4. Install the EDID File

```bash
sudo mkdir -p /lib/firmware/edid
sudo cp 1080p80.bin /lib/firmware/edid/edid80.bin
```

Add the file to the initramfs configuration:

```bash
sudo nano /etc/mkinitcpio.conf
```

Edit the `FILES` line:

```bash
FILES=(/lib/firmware/edid/edid80.bin)
```

Then rebuild the initramfs:

```bash
sudo mkinitcpio -P
```

---

### 5. Update the Boot Entry (systemd-boot)

Edit your bootloader config, e.g. `/boot/loader/entries/arch.conf`:

```ini
options root=... drm.edid_firmware=DP-4:edid/edid80.bin drm_kms_helper.edid_firmware=DP-4:edid/edid80.bin
```

Repeat for other outputs as needed (e.g., DP-6).

---

### 6. Reboot and Test

After rebooting, verify the new mode is available:

```bash
kscreen-doctor -o
```

To switch manually:

```bash
kscreen-doctor output.DP-4.mode.1920x1080@80
```

---


## Technical Notes

* This process works because the kernel loads a modified EDID binary during boot and uses it instead of the monitor's factory EDID.
* The refresh rate limit may be enforced by the monitor’s scaler firmware. In this case, some refresh rates (e.g., 80+ Hz) may be ignored or rejected despite a valid EDID.
* Success depends on the GPU driver, display output (DP vs HDMI), and panel capabilities.

---


