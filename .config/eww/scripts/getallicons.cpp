#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <regex>
#include <stdexcept>
#include <string>
#include "nlohmann/json.hpp"
using namespace std;
using json = nlohmann::json;



int main(int argc, char* argv[]) {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    entries = exec("hyprctl clients -j | gojq -c -M");
    
}