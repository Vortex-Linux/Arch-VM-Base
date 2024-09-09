SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

ship --vm --name arch-vm-base --source https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2
ship --vm exec --command "$SCRIPT_DIR/customize.sh"
ship --vm view arch-vm-base
