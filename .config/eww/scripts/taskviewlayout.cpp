#include <array>       // This script tries to show windows of workspaces
#include <cmath>       // in a reasonable way in Task View
#include <filesystem>  //
#include <fstream>     // Goal: all windows on the same row have equal height
#include <iostream>    //
#include <memory>      //
#include <regex>       // binary search -> ok scale
#include <stdexcept>   // -> sort small-wide windows -> match pairs -> rows
#include <string>

#include "nlohmann/json.hpp"

using namespace std;
using json = nlohmann::json;

#define COLS 10
#define RES_WIDTH 1920
#define RES_HEIGHT 1080
#define RESERVED_BOTTOM 250
#define SPACING 30
#define TITLEBAR_AND_BORDER_HEIGHT 51
#define MIN_ROW_HEIGHT 186  // 100px (else scroll down)
#define MAX_ROW_HEIGHT 300  // 100px (else scroll down)
const json EMPTY_JSON = R"([])"_json;
const string workspaceInitTemplate = "[]";

int numOfApps[COLS] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
string clients;
json clientjson, workspaces;
json workspacesArranged;

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
    int i = 0;
    for (int j = 0; j < COLS; j++) {
        int workspaceNum = i * COLS + j + 1;  // Note: Workspaces are 1-base
        string workspaceInitString =
            regex_replace(workspaceInitTemplate, regex("__WORKSPACE_ID"),
                          to_string(workspaceNum));
        json thisWorkspaceInit = json::parse(workspaceInitString);
        workspaces.push_back(thisWorkspaceInit);
    }
}

void addApp(json& client) {
    if(string(client["class"]).size() == 0) return;
    // Calculate position in overview tile
    int workspaceNum = int(client["workspace"]["id"]) - 1;  // 1-base to 0-base
    if (workspaceNum < 0)
        return;  // Skip scratchpads/specials, as they have negative ids
    int i = workspaceNum / COLS, j = workspaceNum % COLS;

    // New JSON for app
    json newApp =
        R"({"class": "", "workspace": {"id": 8, "name": "8"}, "title": "", "at": [0, 0], "size": [0, 0], "address": [], "icon": ""})"_json;

    // Add normal stuff
    newApp["class"] = client["class"];
    newApp["address"] = client["address"];
    newApp["workspace"] = client["workspace"];
    newApp["title"] = client["title"];
    newApp["size"] = client["size"];

    // Icon path
    string filename = string("./scripts/cache/" + string(client["class"]));
    std::ifstream ifs(filename);
    std::string iconpath((std::istreambuf_iterator<char>(ifs)),
                         (std::istreambuf_iterator<char>()));
    while (iconpath.size() > 0 && *iconpath.rbegin() == '\n')
        iconpath.pop_back();  // Remove '\n'
    newApp["icon"] = iconpath;

    // Counting
    int size_x = int(newApp["size"][0]);
    int size_y = int(newApp["size"][1]);
    if (size_x <= size_y * 2) {  // Normal
        newApp["countAs"] = 1;   //     count as 1 window
    } else {                     // Very wide
        newApp["countAs"] = 2;   //     count as 2 windows
    }
    numOfApps[int(newApp["workspace"]["id"]) - 1] += int(newApp["countAs"]);

    // Push
    workspaces[j].push_back(newApp);
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

void scaleWindows() {
    for (int i = 0; i < workspaces.size(); i++) {
        if (workspaces[i].size() == 0) {
            workspacesArranged.push_back(EMPTY_JSON);
            continue;
        }
        // Declare
        int numOfRows = numOfApps[i] > 3 ? int(ceil(sqrt(numOfApps[i]))) : 1;
        int winsPerRow = (numOfApps[i] + (numOfRows - 1)) / numOfRows;  // ceil
        json thisWorkspace = EMPTY_JSON;
        for (int i = 0; i < numOfRows; i++) thisWorkspace.push_back(EMPTY_JSON);
        int rowHeight =
            min(max(MIN_ROW_HEIGHT,
                    (RES_HEIGHT - RESERVED_BOTTOM - SPACING) / numOfRows -
                        TITLEBAR_AND_BORDER_HEIGHT - SPACING),
                MAX_ROW_HEIGHT);
        int thisRowCnt = 0, rowsDone = 0;

        // cout << "Workspace " << i + 1 << " | Rows: " << numOfRows
        //      << " | Per row: " << winsPerRow << '\n';

        // Scale
        for (json& window : workspaces[i]) {
            int cntAs = int(window["countAs"]);
            if (cntAs == 1) {
                window["size"][0] = int(window["size"][0]) /
                                    (float(window["size"][1]) / rowHeight);
                window["size"][1] = rowHeight;
            } else {  // cntAs == 2
                window["size"][1] =
                    int(float(window["size"][1]) /
                        (float(window["size"][0]) / (rowHeight * 2)));
                window["size"][0] = rowHeight * 2;
            }

            // int minWidth = string(window["title"]).size() * 9;
            // cout << "Window: " << string(window["title"])
            //      << ", min width: " << minWidth << '\n';
            // if (window["size"][0] < minWidth) {
            //     window["size"][1] = int(window["size"][1]) *
            //                         (float(minWidth) /
            //                         int(window["size"][0]));
            //     window["size"][0] = minWidth;
            // }
            // cout << " --> " << window["size"][0] << "x" << window["size"][1]
            //      << '\n';
            
            thisWorkspace[rowsDone].push_back(window);
            thisRowCnt += int(window["countAs"]);
            if (thisRowCnt >= winsPerRow) {
                rowsDone++;
                thisRowCnt = 0;
            }
        }

        workspacesArranged.push_back(thisWorkspace);
    }
}

int main(int argc, char* argv[]) {
    ios::sync_with_stdio(false);

    // Get windows in workspaces, counting
    initWorkspaces();
    getApps();

    // cout << ">>>>>>>> [DEBUG INGO START] >>>>>>>>" << '\n';
    // cout << workspaces << '\n';
    // cout << "<<<<<<<< [DEBUG INGO END] <<<<<<<<" << '\n' << '\n';

    // cout << "# of apps: ";
    // for (int i = 0; i < COLS; i++) cout << numOfApps[i] << ' ';
    // cout << '\n';
    // Scaling, arranging
    scaleWindows();

    cout << workspacesArranged << '\n';
}