#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit
fi

if [ -f /etc/sysctl.d/99-disable-ipv6.conf ]; then
  echo "Enabling IPv6..."
  sudo rm -f /etc/sysctl.d/99-disable-ipv6.conf
  sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
  sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0
  sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=0
else
  echo "Disabling IPv6..."
  cat <<EOF | sudo tee /etc/sysctl.d/99-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
  sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
fi

ip -6 addr show
