#!/bin/bash

# Remove YouTube entries from /etc/hosts to unblock access
sudo sed -i '/youtube.com/d' /etc/hosts

echo "YouTube has been unblocked."
