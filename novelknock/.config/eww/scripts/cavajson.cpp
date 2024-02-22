#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream.hpp>
#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>

void cavaToJson(std::string& s) {
    int cnt = 0;
    std::string newStr = "[";
    for (int i = 0; i < s.size(); i++) {
        if (s[i] == ';') {
            s[i] = ',';
            newStr += std::string(',' + std::to_string(cnt++) + "],[");
        } else {
            newStr.push_back(s[i]);
        }
    }
    newStr.pop_back();
    newStr.pop_back();
    s = newStr;
}

int main() {
    std::unique_ptr<FILE, decltype(&pclose)> pipe(
        popen("cava -p ~/.config/eww/scripts/custom_configs/cava", "r"),
        pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    boost::iostreams::file_descriptor_source fd(
        fileno(pipe.get()), boost::iostreams::never_close_handle);
    boost::iostreams::stream<boost::iostreams::file_descriptor_source> is(fd);
    std::string line;
    while (std::getline(is, line)) {
        cavaToJson(line);
        std::cout << '[' << line << ']'
                  << std::endl;  // print the output line by line
    }
    return 0;
}