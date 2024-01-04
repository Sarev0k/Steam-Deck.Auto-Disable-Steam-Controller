# Steam-Deck.Auto-Disable-Steam-Controller
Script to Automatically disable the built in Steam Controller when a dock is connected and then enable once disconnected.

# WORK IN PROGRESS!
This will probably have bugs, so beware! log bugs under [issues](https://github.com/Sarev0k/Steam-Deck.Auto-Disable-Steam-Controller/issues)!

# About

When using External Controllers with the Steam Deck, sometimes the build in Steam Controller gets in the way by either not allowing the use of an External Controller at all, Having to Reassign Controller in the config each time you play a game, or interfering with Multiplayer games. This script simply listens to `udev` for when the dock is connected via USB then disables the Built in Steam Controller so that the (first) External Controller Defaults to Player One.

The Built in Steam Controller will be disabled until the dock is disconnected.

# Currently Works With
 - [UGREEN 6-in-1 USB C Docking Station with 4K@60Hz HDMI](https://www.ugreen.com/collections/usb-hub/products/ugreen-6-in-1-usb-c-docking-station-with-4k-60hz-hdmi)

# Manually adding other Devices

To add another device, run `lsusb` to identify the device you'd like to add, then run the following command:
```bash
usb_addr=$(lsusb | grep -i 'My USB Device' | cut -d' ' -f2,4 | cut -d: -f1 | tr ' ' '/')
udevadm info --query=property --name "/dev/bus/usb/$usb_addr" | grep PRODUCT | cut -d'=' -f2 >> /home/deck/.local/share/SDADSC/conf/simple_device_list.txt
```

# Installation

## Via Curl (One Line Install)

In Konsole type:
```bash
curl -sSL https://raw.githubusercontent.com/Sarev0k/Steam-Deck.Auto-Disable-Steam-Controller/main/curl_install.sh | bash
```

a `sudo` password is required (run `passwd` if required first)

# How to Temporarily Disable

```bash
touch /home/deck/.local/share/SDADSC/conf/disabled
````

to re-enable:
```bash
rm /home/deck/.local/share/SDADSC/conf/disabled
```

# Uninstallation

Run the following commands:
```bash
# To delete the code
sudo rm -r /home/deck/.local/share/SDADSC
# To delete the rule
sudo rm -r /etc/udev/rules.d/99-disable-steam-input.rules
# To reload the service
sudo udevadm control --reload
```
