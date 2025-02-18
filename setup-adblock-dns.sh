#!/bin/bash

echo "Setting up ControlD DNS (p2) with DNS-over-TLS..."

# ControlD Free Resolver (Malware & Ads Blocking)
CONTROLD_DNS_IPV4="76.76.2.11"
CONTROLD_DNS_HOSTNAME="p2.freedns.controld.com"
RESOLVED_CONF="/etc/systemd/resolved.conf"
STUBBY_CONF="/etc/stubby/stubby.yml"

# Enable systemd-resolved if not active
echo "Enabling systemd-resolved..."
sudo systemctl enable --now systemd-resolved

# Backup resolved.conf if not already backed up
if [ ! -f "${RESOLVED_CONF}.bak" ]; then
    echo "Creating backup of resolved.conf..."
    sudo cp "$RESOLVED_CONF" "${RESOLVED_CONF}.bak"
fi

# Modify systemd-resolved config
echo "Configuring systemd-resolved for ControlD..."
sudo sed -i '/^DNS=/d' "$RESOLVED_CONF"
sudo sed -i '/^DNSOverTLS=/d' "$RESOLVED_CONF"

sudo bash -c "cat > $RESOLVED_CONF" <<EOF
[Resolve]
DNS=$CONTROLD_DNS_IPV4#$CONTROLD_DNS_HOSTNAME
DNSOverTLS=yes
EOF

# Restart systemd-resolved to apply changes
echo "Restarting systemd-resolved..."
sudo systemctl restart systemd-resolved

# Verify systemd-resolved settings
echo "Checking systemd-resolved status..."
resolvectl status | grep "DNS Servers"

# Optional: Configure Stubby for DNS-over-TLS
if command -v stubby >/dev/null 2>&1; then
    echo "Configuring Stubby for ControlD DNS-over-TLS..."

    # Backup Stubby config if not already backed up
    if [ ! -f "${STUBBY_CONF}.bak" ]; then
        sudo cp "$STUBBY_CONF" "${STUBBY_CONF}.bak"
    fi

    # Modify Stubby config
    sudo sed -i 's/round_robin_upstreams: .*/round_robin_upstreams: 0/' "$STUBBY_CONF"
    sudo sed -i '/- address_data:/,/tls_port:/d' "$STUBBY_CONF"

    sudo bash -c "cat >> $STUBBY_CONF" <<EOF

# ControlD DNS-over-TLS Resolver
upstream_recursive_servers:
  - address_data: $CONTROLD_DNS_IPV4
    tls_auth_name: "$CONTROLD_DNS_HOSTNAME"
EOF

    # Restart Stubby
    echo "Restarting Stubby..."
    sudo systemctl restart stubby
fi

echo "ControlD DNS setup complete with DNS-over-TLS!"
