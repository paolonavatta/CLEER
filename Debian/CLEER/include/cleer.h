#include <iostream>
#include <string>
#include <cstdlib>
#include <chrono>
#include <thread>
#include <filesystem>
#include "../libraries/operativesystem.h"
#include "../string.h"

#include <iostream>
#include <string>

namespace cleer {
    class string : public std::string {
    public:
        string() : std::string() {}
        string(const char* str) : std::string(str) {}
        string(const std::string& str) : std::string(str) {}

        string get(int start, int end) const {
            if (start < 0 || start >= length() || end < start || end >= length()) {
                throw std::out_of_range("Invalid range");
            }
            return string(substr(start, end - start + 1));
        }
    };
}

std::string getKeyboardInput() {
    std::string input;
    char c = std::cin.get();  

    if (c == '\033') {  
        char arrow1 = std::cin.get();
        char arrow2 = std::cin.get();

        if (arrow1 == '[') {
            switch (arrow2) {
                case 'A': 
                    input = "UpArr";
                    break;
                case 'B':  
                    input = "DownArr";
                    break;
                case 'C':  
                    input = "RightArr";
                    break;
                case 'D':  
                    input = "LeftArr";
                    break;
                default:
                    break;
            }
        }
    } else {
        input = c;
    }

    return input;
}


#define var auto
#define func auto
#define br std::cout << std::endl


using namespace cleer;


namespace console {
    #ifdef _WIN32
    #include <Windows.h>
#elif defined(__APPLE__)
    #include <unistd.h>
#else
    #include <cstdlib>
#endif

void cls () {
    #ifdef _WIN32
        std::system("cls");
    #elif defined(__APPLE__)
        std::system("clear");
    #else
        std::system("clear");
    #endif
}
template<typename... Args>
void print(const Args&... args) {
    ((std::cout << args), ...);
}

template<typename T>
void println(const T& content) {
    std::cout << content << std::endl;
}

template<typename... Args>
void println(const Args&... args) {
    print(args...);
    std::cout << std::endl;
}

template<typename T>
void input(T& variable) {
    std::cin >> variable;
}

}

namespace url {
    void open(const std::string& url) {
        
        std::string command;

        #ifdef _WIN32
            command = "start " + url;
        #elif __APPLE__  // macOS
            command = "open " + url;
        #else
            command = "xdg-open " + url;
        #endif

        
        std::system(command.c_str());
    }
}
