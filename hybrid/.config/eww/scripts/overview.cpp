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

#define ROWS 2
#define COLS 5

string clients;
json clientjson, apps;
json workspaces;
string workspaceInitTemplate =
    "[{\"address\":\"_none\",\"at\":[0,0],\"class\":\"workspace\",\"size\":["
    "1920,1080],\"title\":\"__WORKSPACE_ID\",\"workspace\":{\"id\":__WORKSPACE_"
    "ID,\"name\":\"__WORKSPACE_ID\"}}]";
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

void initWorkspaces() {
    for (int i = 0; i < ROWS; i++) {
        workspaces.push_back(json::array({})); // []
        for (int j = 0; j < COLS; j++) {
            int workspaceNum = i * COLS + j + 1;  // Note: Workspaces are 1-base
            string workspaceInitString =
                regex_replace(workspaceInitTemplate, regex("__WORKSPACE_ID"),
                              to_string(workspaceNum));
            json thisWorkspaceInit = json::parse(workspaceInitString);
            workspaces[i].push_back(thisWorkspaceInit);
        }
    }
}

void addApp(json& client) {
    if(string(client["class"]).size() == 0) return;
    
    // Calculate position in overview tile
    int workspaceNum = int(client["workspace"]["id"]) - 1;  // 1-base to 0-base
    if(workspaceNum < 0) return; //Skip scratchpads/specials, as they have negative ids
    int i = workspaceNum / COLS, j = workspaceNum % COLS;

    // New JSON for app
    json newApp =
        R"({"class": "", "workspace": {"id": 8, "name": "8"}, "title": "", "at": [0, 0], "size": [0, 0], "address": [], "icon": ""})"_json;
    // Add normal stuff
    newApp["class"] = client["class"];
    newApp["address"] = client["address"];
    newApp["workspace"] = client["workspace"];
    newApp["title"] = client["title"];
    newApp["at"] = client["at"];
    newApp["size"] = client["size"];
    // Icon path
    string filename = string("./scripts/cache/" + string(client["class"]));
    std::ifstream ifs(filename);
    std::string iconpath((std::istreambuf_iterator<char>(ifs)),
                         (std::istreambuf_iterator<char>()));
    while (iconpath.size() > 0 && *iconpath.rbegin() == '\n') iconpath.pop_back();  // Remove '\n'
    newApp["icon"] = iconpath;

    workspaces[i][j].push_back(newApp);
}

void getApps() {
    // Get clients
    clients = exec("hyprctl clients -j | gojq -c -M");
    clientjson = json::parse(clients);

    // Access the values
    for (json client : clientjson) {
        addApp(client);
    }
}

int main(int argc, char* argv[]) {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    initWorkspaces();
    getApps();
    if (argc == 2) cout << workspaces[0][stoi(argv[1]) - 1] << '\n';
    if (argc == 3 && string(argv[1]) == "--row" && stoi(argv[2]) >= 1 && stoi(argv[2]) <= ROWS) {
        cout << workspaces[stoi(argv[2]) - 1] << '\n';
    } else
        cout << workspaces << '\n';
}