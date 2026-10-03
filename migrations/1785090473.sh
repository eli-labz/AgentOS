echo "Repair fingerprint support left without a libfprint"

# An earlier version of this migration swapped libfprint-git for stock
# libfprint in two steps. A run that failed between them left fprintd with
# no library; finish with the driver the fingerprint setup installs now.
if agent0s-pkg-present fprintd && agent0s-pkg-missing libfprint && agent0s-pkg-missing libfprint-git; then
  agent0s-pkg-add libfprint-git
fi
