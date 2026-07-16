#!/bin/bash

# CLEER v0.0.1 - Beta

# Set the base path for the system
base_path="/usr/local/bin/CLEER"

# tmp for alises
alias_file="/tmp/cleer_aliases"
> "$alias_file"

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
    local content="$1"
    local includes=""

    > "$alias_file"

    while IFS= read -r line; do
        if [[ "$line" =~ import:[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)([[:space:]]*->[[:space:]]*([A-Za-z_][A-Za-z0-9_]*))? ]]; then
            library="${BASH_REMATCH[1]}"

            if [ -n "${BASH_REMATCH[3]}" ]; then
                alias="${BASH_REMATCH[3]}"
            else
                alias="$library"
            fi

            registry=$(grep "^${library}=" /usr/local/bin/CLEER/libraries/libraries.conf)

            if [ -z "$registry" ]; then
                echo "Unknown library: $library"
                exit 1
            fi

            namespace=$(echo "$registry" | cut -d= -f2)
            header=$(echo "$registry" | cut -d= -f3)
            echo "$alias=$namespace" >> "$alias_file"
            includes+="\n#include \"$header\""
            content=$(echo "$content" | sed \
                "s/import:[[:space:]]*$library.*//")

        fi

    done <<< "$content"

    echo -e "$includes\n$content"
}

function change_namespaces() {
    local content="$1"

    # Built-in namespaces (no imports)
    content=$(echo "$content" | sed \
        -e 's/console\./console::/g' \
        -e 's/url\./url::/g')

    # Imported library aliases
    while IFS="=" read -r alias namespace; do
        content=$(echo "$content" | sed \
            -E "s/\b${alias}\./${namespace}::/g")
    done < "$alias_file"

    echo "$content"
}

function change_write() {
    local modified_content

    modified_content=$(sed -E \
        's/write\((.*?)([[:space:]]*->[[:space:]]*)(.*?)\)/write(\3, \1)/g' \
        <<< "$1")

    echo "$modified_content"
}

function change_var_uninitialized() {
    local modified_content
    # "var name;" initializer to deduce a type from.
    modified_content=$(sed -E 's/var[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*;/cleer::string \1;/' <<< "$1")
    echo "$modified_content"
}

function change_main() {
    local modified_content
    # Only touch standalone "main" tokens
    modified_content=$(sed -E 's/\bmain(\s*\()/int main\1/; t; s/\bmain\b/int main()/' <<< "$1")
    echo "$modified_content"
}

function report_compile_errors() {
    local raw_output="$1"
    local cpp_path="$2"
    local cleer_path="$3"
    local cleer_name
    cleer_name=$(basename "$cleer_path")

    # Escape regex metacharacters in the cpp path so it's safe to match literally
    local cpp_path_escaped
    cpp_path_escaped=$(printf '%s' "$cpp_path" | sed 's/[][\.^$*+?(){}|/]/\\&/g')

    echo "CLEER compile error in ${cleer_name}:"
    echo ""

    while IFS= read -r line; do
        if [[ "$line" =~ ^${cpp_path_escaped}:([0-9]+):([0-9]+):\ (error|warning|note):\ (.*)$ ]]; then
            local cpp_line="${BASH_REMATCH[1]}"
            local level="${BASH_REMATCH[3]}"
            local msg="${BASH_REMATCH[4]}"
            local cleer_line=$((cpp_line - 1))
            local src_line=""
            if [ "$cleer_line" -ge 1 ]; then
                src_line=$(sed -n "${cleer_line}p" "$cleer_path")
            fi
            echo "  ${cleer_name}:${cleer_line}: ${level}: ${msg}"
            if [ -n "$src_line" ]; then
                echo "      ${src_line}"
            fi
        elif [[ "$line" == *"$cpp_path"* ]]; then
            # Raw pointer into the generated .cpp with no line/col
            continue
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+[[:space:]]*\| ]] || [[ "$line" =~ ^[[:space:]]*\| ]]; then
            continue
        else
            echo "  $line"
        fi
    done <<< "$raw_output"
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

    # Give uninitialized "var x;" a concrete type instead of "auto x;"
    modified_content=$(change_var_uninitialized "$modified_content")

    # Change "main" with "int main()"
    modified_content=$(change_main "$modified_content")

    # Write the modified include at the beginning of the file
    echo "#include \"/usr/local/bin/CLEER/include/cleer.h\"" > "$new_file_path"

    # Write the modified content to the .cpp file
    echo "$modified_content" >> "$new_file_path"

    # Compiling command
    compile_command="g++ -std=c++17 -I ${directory}/include ${new_file_path} -o ${directory}/${exe_file}"

    local compile_output
    compile_output=$(eval "$compile_command" 2>&1)
    local compile_status=$?

    if [ "$compile_status" -ne 0 ]; then
        report_compile_errors "$compile_output" "$new_file_path" "$cleer_file_path"
        return 1
    fi

    # Execute the file in the terminal
    executable_path="${directory}/${exe_file}"
    eval "$executable_path"
}

modify_cleer_file "$(basename "$cleer_file_path")"
compile_result=$?
# Remove the main.cleer.cpp file regardless of success or failure
rm -f "${cleer_file_path}.cpp"
exit $compile_result