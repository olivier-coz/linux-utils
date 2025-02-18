#!/bin/bash

# Add YouTube entries to /etc/hosts to block access
echo "127.0.0.1 youtube.com" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 www.youtube.com" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 m.youtube.com" | sudo tee -a /etc/hosts > /dev/null

echo "YouTube has been blocked."
