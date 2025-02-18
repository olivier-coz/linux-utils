#!/bin/bash

echo "Reverting DNS settings to default..."

RESOLVED_CONF="/etc/systemd/resolved.conf"
BACKUP_CONF="/etc/systemd/resolved.conf.bak"

# Restore the backup if it exists
if [ -f "$BACKUP_CONF" ]; then
    echo "Restoring original resolved.conf..."
    sudo cp "$BACKUP_CONF" "$RESOLVED_CONF"
else
    echo "No backup found! Resetting to default systemd-resolved settings..."
    sudo sed -i '/^DNS=/d' "$RESOLVED_CONF"
    sudo sed -i '/^DNSOverTLS=/d' "$RESOLVED_CONF"
    sudo sed -i '/^DNSSEC=/d' "$RESOLVED_CONF"
    sudo sed -i '/^Domains=/d' "$RESOLVED_CONF"
fi

echo "Resetting resolv.conf symlink..."
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo "Restarting systemd-resolved..."
sudo systemctl restart systemd-resolved

echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager

# Verify the DNS reset
echo "Checking current DNS settings..."
resolvectl status | grep "Current DNS Server"

echo "DNS settings have been restored to normal!"
