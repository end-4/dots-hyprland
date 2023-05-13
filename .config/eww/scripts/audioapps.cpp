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

string clients;
json clientjson, apps;
string iconTheme = "";

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

string getIconPath(string iconname) {
    if (iconTheme == "") {
        iconTheme =
            exec(string("gsettings get org.gnome.desktop.interface icon-theme")
                     .c_str());
        iconTheme.pop_back();
        // cout << "icon theme: " << iconTheme << '\n';
    }
    if (iconname.size() == 0) {
        return "";
    } else if (iconname[0] == '/') {
        return iconname;  // Already absolute path
    } else if (iconname[0] == '\n') {
        return "";  // wtf
    }
    string path = readIfExists("scripts/cache/" + iconname);
    if (path == "") {
        path = exec(
            string("geticons -t " + iconTheme + " " + string(iconname) + " | head -n 1").c_str());
        writeToFile("scripts/cache/" + iconname, path);
        // cout << "icon name: " << iconname << '\n';
        // cout << "path: " << path << '\n';
    }
    while (path.size() > 0 && *path.rbegin() == '\n')
        path.pop_back();  // Remove '\n'
    return path;
}

void addApp(json& client) {
    string volumestr = client["volume"]["front-left"]["value_percent"];
    volumestr.pop_back();
    int volume = stoi(volumestr);
    client = client["properties"];

    bool found = false;
    for (json& obj : apps) {
        auto it = obj.find("name");
        if (it != obj.end() && *it == client["application.name"]) {
            found = true;
            obj["count"] = int(obj["count"]) + 1;
            obj["volume"].push_back(
                json::array({client["object.serial"], volume}));
            break;
        }
    }
    if (!found) {
        json newApp =
            R"({"name": "", "count": 1, "volume": [], "icon": ""})"_json;
        newApp["name"] = client["application.name"];
        newApp["volume"].push_back(
            json::array({client["object.serial"], volume}));

        string iconpath;
        auto it = client.find("application.icon_name");
        if (it != client.end())
            iconpath = getIconPath(client["application.icon_name"]);
        else {
            iconpath = getIconPath(client["application.process.binary"]);
        }
        newApp["icon"] = iconpath;

        apps.push_back(newApp);
    }
}

void getAudioClients() {
    clients = exec("pactl --format json list sink-inputs");
    clientjson = json::parse(clients);
    for (json client : clientjson) {
        addApp(client);
        // cout << client << '\n';
    }
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    getAudioClients();
    cout << apps << '\n';
}