#!/bin/bash
#Steam Deck Auto Disable Steam Controller by scawp updated by Sarev0k
#License: DBAD: https://github.com/Sarev0k/Steam-Deck.Auto-Disable-Steam-Controller/blob/main/LICENSE.md
#Source: https://github.com/Sarev0k/Steam-Deck.Auto-Disable-Steam-Controller
# Use at own Risk!

set -e
shopt -s extglob

script_install_dir="/etc/SDADSC"
conf_dir="$script_install_dir/conf"
tmp_dir="$script_install_dir/tmp"
mkdir -p $tmp_dir

boot_id=$(cat /proc/sys/kernel/random/boot_id)
interface_ids_file="$tmp_dir/${boot_id}_interface_ids.txt"

# Cleanup interface ids from previous boots, that are no longer reflective of the current system state.
rm -f $tmp_dir/!($interface_ids_file*) 2> /dev/null || true

action=$1
vendor_id=$(echo $2 | cut -d'/' -f1)
model_id=$(echo $2 | cut -d'/' -f2)
revision=$(echo $2 | cut -d'/' -f3)
interface_id=$3

function controllerState {
  if compgen -G "/sys/bus/usb/drivers/usbhid/$sc_hid_id:1\.[0-2]" > /dev/null; then
    echo bind
  else
    echo unbind
  fi
}

if [ ! -f "$conf_dir/disabled" ]; then
  if [ -n "$(grep "^$vendor_id/$model_id/$revision$" "$conf_dir/simple_device_list.txt")" ] ||
     [ -n "$(grep "^$vendor_id/$model_id$" "$conf_dir/simple_device_list.txt")" ] ||
     [ -n "$(grep "^$vendor_id$" "$conf_dir/simple_device_list.txt")" ]; then
    # The upstream project had issues with the hid_id changing from one version of steamos to the next
    # so to combat this, we're looking it up each time this script is executed.
    #
    # Intentionally leaving this lookup outside the synchronization block, since leaving it inside prevented controller
    # state changes.
    sc_usb_addr=$(lsusb | grep 'Valve Software Steam Controller' | cut -d' ' -f2,4 | cut -d: -f1 | tr ' ' '/')
    sc_hid_id=$(udevadm info --query=property --name "/dev/bus/usb/$sc_usb_addr" | grep DEVPATH | rev | cut -d'/' -f1 | rev)

    touch $interface_ids_file

    # Ensure file integrity by blocking multiple executions beyond this point
    interface_ids_file_lock="$interface_ids_file.lock"
    while ! ln -s $interface_ids_file $interface_ids_file_lock; do :; done

    sed -i "/^$interface_id$/d" $interface_ids_file
    if [ $action = "disable" ]; then
      echo $interface_id >> $interface_ids_file
    fi

    # When the interface_ids file is non-empty, the dock is connected, and we should unbind the controller in response.
    # When the interface_ids file is empty, the dock is not connected, and we should rebind the controller in response.
    if [ -s $interface_ids_file ]; then
      operation=unbind
    else
      operation=bind
    fi

    # Compute this once up front, to avoid inconsistencies if there is a race.
    current_state=$(controllerState)

    # Only change the controller bindings if it's not already in the desired state.
    if [ "$current_state => $operation" = "unbind => bind" ] ||
       [ "$current_state => $operation" = "bind => unbind" ]; then
      echo "$sc_hid_id:1.0" > "/sys/bus/usb/drivers/usbhid/$operation"
      echo "$sc_hid_id:1.1" > "/sys/bus/usb/drivers/usbhid/$operation"
      echo "$sc_hid_id:1.2" > "/sys/bus/usb/drivers/usbhid/$operation"

      # Wait until the state change occurs before proceeding
      while [ "$current_state" != "$operation" ]; do
        current_state=$(controllerState)
      done
    fi

    # Release the lock.
    rm $interface_ids_file_lock
  fi
fi

exit 0
