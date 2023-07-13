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

string dunstOutput;
json allNotifs, notifApps;

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

// Function to check if file exists, if yes read it
string readIfExists(const string& name) {
    ifstream f(name.c_str());
    stringstream buffer;
    if (f) {                  // check if the file was opened successfully
        buffer << f.rdbuf();  // read the whole file into a string stream
        f.close();            // close the file when done
    }
    return buffer.str();  // return the string stream as a string
}

void writeToFile(const string& name, const string& content) {
    ofstream f(name.c_str(), ios::app);  // open the file in append mode
    if (f) {                   // check if the file was opened successfully
        f << content << "\n";  // write the content to the file
        f.close();             // close the file when done
    } else {
        cerr << "Error: could not open " << name
             << "\n";  // print an error message to the standard error
    }
}

inline void getDunstNotifs() {
    dunstOutput = exec("dunstctl history | gojq -c -M");
    allNotifs = json::parse(dunstOutput)["data"][0];
}

void addNotif(const json& newNotification) {
    notifApps["count"] = int(notifApps["count"]) + 1;
    bool found = false;
    for (json& existingApp : notifApps["data"]) {
        auto it = existingApp.find("name");
        if (it != existingApp.end() &&
            *it == newNotification["appname"]["data"]) {
            found = true;
            existingApp["count"] = int(existingApp["count"]) + 1;
            existingApp["content"].push_back(
                json::array({newNotification["summary"]["data"],
                             newNotification["body"]["data"]}));
            break;
        }
    }
    // Not found? A new app it is
    if (!found) {
        json newApp = R"({"name": "", "count": 1, "content": []})"_json;
        newApp["name"] = string(newNotification["appname"]["data"]);
        newApp["content"].push_back(
            json::array({newNotification["summary"]["data"],
                         newNotification["body"]["data"]}));

        notifApps["data"].push_back(newApp);
    }
}

inline void groupNotifs() {
    for (json notification : allNotifs) {
        addNotif(notification);
    }
}

int main() {
    // ios::sync_with_stdio(false);
    notifApps["data"] = json::array();
    notifApps["count"] = 0;

    getDunstNotifs();
    groupNotifs();
    cout << notifApps << '\n';
}