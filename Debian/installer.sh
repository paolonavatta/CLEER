#!/bin/bash

# Directory
destination="/usr/local/bin"

# Current script name
script_name="installer.sh"

# Clear the line and print the new message
function print_message() {
  tput cuu1  # Move cursor up by 1 line
  tput el    # Clear the line
  echo "$1"
}

# create link to cleer.sh
ln -s cleer.sh cleer

# Copy files in usr/local/bin
print_message "Copying files in usr/local/bin..."
for entry in *; do
  if [ "$entry" != "$script_name" ]; then
    cp -r "$entry" "$destination"
  fi
done


# Icon path
icon_path="/usr/local/bin/CLEER/assets/ubuntu-logo.png"

# MIME file creation
print_message "Creating MIME File..."
mime_file="/usr/share/mime/packages/cleer-mime.xml"
echo '<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-cleer">
    <comment>CLEER File</comment>
    <icon name="cleer-icon"/>
    <glob-deleteall/>
    <glob pattern="*.cleer"/>
  </mime-type>
</mime-info>' | sudo tee "$mime_file" > /dev/null

# MIME Info Update
print_message "Updating MIME infos..."
sudo update-mime-database /usr/share/mime

# Copy the icon in the icons directory
print_message "Copying the Icons in the Icons Directory..."
sudo cp "$icon_path" /usr/share/icons/hicolor/48x48/mimetypes/cleer-icon.png

# Update icons
print_message "Updating Icons..."
sudo update-icon-caches /usr/share/icons/*

# Associate .cleer to the icon
print_message "Assosciating .cleer to its Icon..."
xdg-icon-resource install --novendor --context mimetypes --size 48 /usr/share/icons/hicolor/48x48/mimetypes/cleer-icon.png application-x-cleer
xdg-mime default application-x-cleer.desktop application/x-cleer

# Check if GCC is installed, and install if not
if ! command -v gcc &> /dev/null; then
  print_message "GCC not found. Installing GCC..."
  sudo apt-get update
  sudo apt-get install -y gcc
  print_message "GCC installed successfully."
fi

# Make Cleer executable

chmod +x "$destination/cleer.sh"
sudo ln -sf "$destination/cleer.sh" /usr/local/bin/cleer
chmod +x /usr/local/bin/cleer

print_message "CLEER Succesfully Installed."
