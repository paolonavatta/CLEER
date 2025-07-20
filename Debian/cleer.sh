#!/bin/bash

# CLEER v0.0.1 - Beta

# Set the base path for the system
base_path="/usr/local/bin/CLEER"

# Check if a .cleer file is provided as an argument
if [ -z "$1" ]; then
  echo "CLEER 0.0.1 - beta"
  exit 1
fi

if [ "$1" == "--version" ]; then
  echo "CLEER 0.0.1 - beta"
  exit 0
fi

if [ "$1" == "--help" ]; then
  echo "cleer file.cleer      Compile file.cleer"
  echo " "
  echo "--help                Display this message"
  echo "--version             Display CLEER Version"
  exit 0
fi
# Get the absolute path of the provided .cleer file
cleer_file_path=$(realpath "$1")

# Check if the .cleer file exists
if [ ! -f "$cleer_file_path" ]; then
  echo "File not found: $cleer_file_path"
  exit 1
fi

# Get the directory of the .cleer file
directory=$(dirname "$cleer_file_path")

function change_includes() {
    local modified_content
    modified_content=$(sed -e 's/#include <os>/#include "\/usr\/local\/bin\/CLEER\/libraries\/operativesystem.h"/' <<< "$1")
    echo "$modified_content"
}



function change_namespaces() {
    local modified_content
    modified_content=$(sed -e 's/console\./console::/' \
                          -e 's/os\./os::/' \
                          -e 's/url\./url::/'  <<< "$1")
    echo "$modified_content"
}

function change_write() {
    local modified_content
    modified_content=$(sed -E 's/write\((.*?)(\s*>\s*)(.*?)\)/write(\1, \3)/' <<< "$1")
    echo "$modified_content"
}

function change_main() {
    local modified_content
    modified_content=$(sed -e 's/main/int main()/' <<< "$1")
    echo "$modified_content"
}

function modify_cleer_file() {
    local file="$1"
    local cfile="${file}.cpp"
    local exe_file="${file%.*}"
    local new_file_path="${directory}/${cfile}"
    local cleer_file_path="${directory}/${file}"

    # Read the .cleer file
    cleer_content=$(< "$cleer_file_path")

    # Change includes
    modified_content=$(change_includes "$cleer_content")

    # Change namespaces
    modified_content=$(change_namespaces "$modified_content")

    # Change "write" statements
    modified_content=$(change_write "$modified_content")

    # Change "main" with "int main()"
    modified_content=$(change_main "$modified_content")

    # Write the modified include at the beginning of the file
    echo "#include \"/usr/local/bin/CLEER/include/cleer.h\"" > "$new_file_path"

    # Write the modified content to the .cpp file
    echo "$modified_content" >> "$new_file_path"

    # Compiling command
    compile_command="g++ -std=c++17 -I ${directory}/include ${new_file_path} -L${directory}/lib -Wl,-rpath,${directory}/lib -L/usr/local/bin/CLEER/lib -lcleer -o ${directory}/${exe_file}"

    # Execute the compiling command
    eval "$compile_command"

    # Execute the file in the terminal
    executable_path="${directory}/${exe_file}"
    eval "$executable_path"
}

modify_cleer_file "$(basename "$cleer_file_path")"
# Remove the main.cleer.cpp file
rm "${cleer_file_path}.cpp"
