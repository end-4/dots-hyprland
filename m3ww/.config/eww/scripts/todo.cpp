#include <pwd.h>
#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "nlohmann/json.hpp"
using namespace std;
using json = nlohmann::json;

string rawTodo;
json todo;

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

void delItem(const string& stringToDelete) {
    cout << " [i] Full list: '" << todo << "'\n";
    cout << " [x] Deleting item: '" << stringToDelete << "'\n\n";
    for (int i = 0; i < todo.size(); i++) {
        const string& thisEntry = todo[i];
        cout << "Compare: \"" << thisEntry << "\" and \"" << stringToDelete << "\"\n";
        if (thisEntry == stringToDelete) {
            cout << "yes\n";
            todo.erase(i);
            break;
        }
    }
}

void addItem(const string& stringToAdd) {
    cout << "adding\n";
    todo.push_back(stringToAdd);
}

int main(int argc, char* argv[]) {
    if (argc == 1) {
        cout << "Usage: todo del [ STRING ]";
        return 0;
    }

    rawTodo = readIfExists("json/todo.json");
    todo = json::parse(rawTodo);
    if (argc > 2 && string(argv[1]) == "del") {
        delItem(string(argv[2]));
        exec("echo '' > json/todo.json");
        writeToFile("json/todo.json", todo.dump());
    }
    else if (argc > 2 && string(argv[1]) == "add") {
        addItem(string(argv[2]));
        exec("echo '' > json/todo.json");
        writeToFile("json/todo.json", todo.dump());
    }
}