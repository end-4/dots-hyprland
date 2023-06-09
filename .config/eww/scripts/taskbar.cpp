#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#include "nlohmann/json.hpp"
using namespace std;
using json = nlohmann::json;

string clients, pinned;
json clientjson, apps;
vector<string> appnames;

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

void addApp(json& client) {
    if(string(client["class"]).size() == 0) return;
    
    bool found = false;
    for (json& obj : apps) {
        auto it = obj.find("class");
        if (it != obj.end() && *it == client["class"]) {
            found = true;
            obj["count"] = int(obj["count"]) + 1;
            obj["address"].push_back(client["address"]);
            obj["workspace"].push_back(client["workspace"]["id"]);
            break;
        }
    }
    if (!found) {
        json newApp =
            R"({"class": "", "count": 1, "workspace": [], "address": [], "icon": ""})"_json;
        newApp["class"] = client["class"];
        newApp["address"].push_back(client["address"]);
        newApp["workspace"].push_back(client["workspace"]["id"]);
        string filename = string("./scripts/cache/" + string(client["class"]));
        std::ifstream ifs(filename);
        std::string iconpath((std::istreambuf_iterator<char>(ifs)),
                             (std::istreambuf_iterator<char>()));
        // cout << "PATH: " << filename << " | ICON PATH: " << iconpath << '\n';
        while (iconpath.size() > 0 && *iconpath.rbegin() == '\n') iconpath.pop_back();  // Remove '\n'
        newApp["icon"] = iconpath;

        apps.push_back(newApp);
    }
}

void getAppNameAndCount() {
    // Get clients
    clients = exec("hyprctl clients -j | gojq -c -M");
    pinned = exec("cat modules/taskbar.json | gojq -c -M");
    clientjson = json::parse(clients);
    apps = json::parse(pinned);

    // Access the values
    for (json client : clientjson) {
        addApp(client);
        // cout << client << '\n';
    }
}

void getAppIcon() {}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    
    getAppNameAndCount();
    getAppIcon();
    cout << apps << '\n';
}