#!/bin/bash

# Directories
destination="/usr/local/bin"
cleer_dir="$destination/CLEER"
icon_dest="/usr/share/icons/hicolor/48x48/mimetypes/cleer-icon.png"
mime_file="/usr/share/mime/packages/cleer-mime.xml"

function print_message() {
  tput cuu1  # Move cursor up by 1 line
  tput el    # Clear the line
  echo "$1"
}

# Confirmation
read -p "This will remove CLEER from your system. Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Uninstall cancelled."
  exit 0
fi

# Remove the CLEER program directory
if [ -d "$cleer_dir" ]; then
  print_message "Removing $cleer_dir..."
  sudo rm -rf "$cleer_dir"
else
  print_message "$cleer_dir not found, skipping."
fi

# Remove cleer.sh and the cleer symlink/launcher
if [ -f "$destination/cleer.sh" ]; then
  print_message "Removing $destination/cleer.sh..."
  sudo rm -f "$destination/cleer.sh"
fi

if [ -e "$destination/cleer" ]; then
  print_message "Removing $destination/cleer..."
  sudo rm -f "$destination/cleer"
fi

# Remove the MIME type definition
if [ -f "$mime_file" ]; then
  print_message "Removing MIME file..."
  sudo rm -f "$mime_file"
  print_message "Updating MIME database..."
  sudo update-mime-database /usr/share/mime
else
  print_message "MIME file not found, skipping."
fi

# Remove the icon
if [ -f "$icon_dest" ]; then
  print_message "Removing icon..."
  sudo rm -f "$icon_dest"
  print_message "Updating icon cache..."
  sudo gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1
else
  print_message "Icon not found, skipping."
fi

# Reset the default handler for .cleer files
if command -v xdg-mime &> /dev/null; then
  print_message "Clearing .cleer MIME association..."
  xdg-mime uninstall /usr/share/applications/application-x-cleer.desktop 2>/dev/null
fi

print_message "CLEER has been successfully uninstalled."
print_message "Note: gcc was not removed."