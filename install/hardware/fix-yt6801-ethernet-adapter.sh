# Install drivers for Motorcomm YT6801 ethernet adapter used by the Slimbook Executive
if lspci | grep -i "YT6801\|Motorcomm.*Ethernet"; then
  agent0s-pkg-add linux-headers yt6801-dkms
fi
