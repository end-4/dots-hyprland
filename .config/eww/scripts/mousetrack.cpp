#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream.hpp>
#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
using namespace std;

void cavaToJson(std::string& s) {
    for(int i = 0; i < s.size(); i++){
        if(s[i] == ';') s[i] = ',';
    }
    s.pop_back();
}

void cursorPosToJson(std::string& s) {
    for(int i = 0; i < s.size(); i++){
        if(s[i] == ';') s[i] = ',';
    }
    s.pop_back();
}

string exec(const char* cmd) {
    array<char, 128> buffer;
    string result;
    unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

int main()
{
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen("cava -p ~/.config/eww/scripts/custom_configs/cava", "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    boost::iostreams::file_descriptor_source fd(fileno(pipe.get()), boost::iostreams::never_close_handle);
    boost::iostreams::stream<boost::iostreams::file_descriptor_source> is(fd);
    std::string line;
    while (std::getline(is, line)) {
        string st = exec("hyprctl cursorpos");
        st.pop_back();
        cout << '[' << st << ']' << endl;
    }
    return 0;
}