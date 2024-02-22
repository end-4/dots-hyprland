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

int workspace_a, workspace_b;
string clients;
json clientjson;
vector<string> windows_a, windows_b;
bool output = false;

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

void tryAddApp(const json& client) {
    if (int(client["workspace"]["id"]) == workspace_a)
        windows_a.push_back(client["address"]);
    else if (int(client["workspace"]["id"]) == workspace_b)
        windows_b.push_back(client["address"]);
}

void getApps() {
    // Get clients
    clients = exec("hyprctl clients -j | gojq -c -M");
    clientjson = json::parse(clients);

    // Access the values
    for (json client : clientjson) {
        tryAddApp(client);
    }
}

void swapWorkspaces() {
    for (string address : windows_a) {
        string cmd = "hyprctl dispatch movetoworkspacesilent " +
                     to_string(workspace_b) + ",address:" + address;
        if (output) cout << cmd << '\n';
        exec(&cmd[0]);
    }
    for (string address : windows_b) {
        string cmd = "hyprctl dispatch movetoworkspacesilent " +
                     to_string(workspace_a) + ",address:" + address;
        if (output) cout << cmd << '\n';
        exec(&cmd[0]);
    }
}

int main(int argc, char* argv[]) {
    ios::sync_with_stdio(false);

    if (argc < 3) {
        cout << "Usage: swapws [WORKSPACE_NUMBER_1] [WORKSPACE_NUMBER_2]"
             << endl;
        return 0;
    }
    if (argc == 4 && string(argv[3]) == "--output") output = true;

    workspace_a = stoi(string(argv[1]));
    workspace_b = stoi(string(argv[2]));
    if (workspace_a <= 0 || workspace_b <= 0 || workspace_a == workspace_b) {
        cout << "Nahhh that's stupid" << endl;
        return 0;
    }

    getApps();
    swapWorkspaces();
}