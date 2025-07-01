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


void move(const std::string& oldPath, const std::string& newPath) {
    int result = std::rename(oldPath.c_str(), newPath.c_str());
    if (result != 0) {
        std::perror("Error, cannot move the file");
    } else {
        std::cout << "File smoved from " << oldPath << " to " << newPath << std::endl;
    }
}


void overwrite(const std::string& filename, const std::string& content) {
    std::ofstream file(filename);
    if (file) {
        file << content;
        file.close();
    }
}

void write(const std::string& filename, const std::string& content) {
    std::ofstream file(filename, std::ios_base::app);
    if (file) {
        file << content;
        file.close();
    }
}

void ls(const std::string& path) {
    for (const auto& entry : fs::directory_iterator(path)) {
        std::cout << entry.path().filename() << std::endl;
    }
}


std::string read(const std::string& filename) {
    std::ifstream file(filename);
    if (file) {
        std::string content((std::istreambuf_iterator<char>(file)),
                            std::istreambuf_iterator<char>());
        return content;
    } else {
        // Il file non esiste o non può essere aperto
        return "";
    }
}


void create(const std::string& filename) {
    std::ofstream file(filename);
    if (!file) {
        std::cerr << "Cannot create the file: " << filename << std::endl;
    }
}


std::string pwd() {
    std::filesystem::path path = std::filesystem::current_path();
    return path.string();
}

void start(const std::string& path) {

    std::string command;
    
        #ifdef _WIN32
            command = "start \"\" \"" + path + "\"";
        #elif __APPLE__  // macOS
            command = "open \"" + path + "\"";
        #else
            command = "xdg-open \"" + path + "\"";
        #endif

    std::system(command.c_str());
}



void command(const std::string& command) {
    std::system(command.c_str());
}

bool kill(pid_t pid, int signal) {
    if (kill(pid, signal) == 0) {
        return true;  // Il segnale è stato inviato con successo
    } else {
        // Gestisci l'errore se la chiamata a kill fallisce
        return false;
    }
}

std::uintmax_t size(const std::string& filePath) {
    std::filesystem::path path(filePath);
    if (std::filesystem::exists(path)) {
        try {
            return std::filesystem::file_size(path);
        } catch (std::filesystem::filesystem_error&) {
            // Gestisci eventuali errori durante il recupero delle dimensioni del file
        }
    }
    // Se il file non esiste o si verifica un errore, restituisci un valore speciale
    throw std::runtime_error("Impossibile ottenere le dimensioni del file");
}


};

#endif // OS_H
