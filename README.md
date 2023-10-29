<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="logo.png">
  <img alt="Logo" src="logo.png" height="150px">
</picture>
<br>
CCTK BatteryCfg
</div>
<br>

# Dell® CCTK BatteryCfg
KDE Plasma widget to manage primary battery configuration using Dell Client Configuration Toolkit (CCTK).

## Install

### Dependencies

- One of the following tools is required for notifications to work. Note that in many distros at least one of the two is installed by default, check it out.
  - [notify-send](https://www.commandlinux.com/man-page/man1/notify-send.1.html) - a program to send desktop notifications.
  - [zenity](https://www.commandlinux.com/man-page/man1/zenity.1.html) - display GTK+ dialogs.

### From KDE Store
You can find it in your software center, in the subcategories `Plasma Addons > Plasma Widgets`.  
Or you can download or install it directly from the [KDE Store](https://store.kde.org/p/2097829/) website.

### Manually
- Download/clone this repo.
- Run from a terminal the command `plasmapkg2 -i [widget folder name]`.

## Root even to breathe
The CCTK tool requires root privileges even to read the status of an option.

If you want to avoid this:
1. Allow CCTK (`/opt/dell/dcc/cctk`) to run with root privileges without a password prompt ([How to run a specific program as root without a password prompt?](https://unix.stackexchange.com/questions/18830/how-to-run-a-specific-program-as-root-without-a-password-prompt)).
2. Go to the widget settings and disable the "I need sudo" option.

## Disclaimer
I'm not a widget or KDE developer, I did this by looking at other widgets, using AI chatbots, consulting documentation, etc. So use it at your own risk.
Any recommendations and contributions are welcome.

## Screenshots
