#ifndef OS_H
#define OS_H

#include <string>
#include <fstream>
#include <cstdlib>
#include <cstdio>
#include <filesystem>
#include <iostream>



namespace os {

namespace fs = std::filesystem;

// Move Function
void move(const std::string& oldPath, const std::string& newPath) {
    int result = std::rename(oldPath.c_str(), newPath.c_str());
    if (result != 0) {
        std::perror("Error, cannot move the file");
    } else {
        std::cout << "File smoved from " << oldPath << " to " << newPath << std::endl;
    }
}

// Overwrite Function
void overwrite(const std::string& filename, const std::string& content) {
    std::ofstream file(filename);
    if (file) {
        file << content;
        file.close();
    }
}

// Write Function
void write(const std::string& filename, const std::string& content) {
    std::ofstream file(filename, std::ios_base::app);
    if (file) {
        file << content;
        file.close();
    }
}

// ls Function
void ls(const std::string& path) {
    for (const auto& entry : fs::directory_iterator(path)) {
        std::cout << entry.path().filename() << std::endl;
    }
}

// Read Function
std::string read(const std::string& filename) {
    std::ifstream file(filename);
    if (file) {
        std::string content((std::istreambuf_iterator<char>(file)),
                            std::istreambuf_iterator<char>());
        return content;
    } else {
        return "";
    }
}

// Create Function
void create(const std::string& filename) {
    std::ofstream file(filename);
    if (!file) {
        std::cerr << "Cannot create the file: " << filename << std::endl;
    }
}

// pwd Function
std::string pwd() {
    std::filesystem::path path = std::filesystem::current_path();
    return path.string();
}

// Start Function
void start(const std::string& path) {
    std::string command;
    command = "xdg-open \"" + path + "\"";
    std::system(command.c_str());
}

// Command Function
void command(const std::string& command) {
    std::system(command.c_str());
}

// Size Function
std::uintmax_t size(const std::string& filePath) {
    std::filesystem::path path(filePath);
    if (std::filesystem::exists(path)) {
        try {
            return std::filesystem::file_size(path);
        } catch (std::filesystem::filesystem_error&) {
        }
    }
    throw std::runtime_error("Cannot get file size");
}


};

#endif // OS_H
