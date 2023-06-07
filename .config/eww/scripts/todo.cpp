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
    auto it = todo.find(stringToDelete);
    int id = it - todo.begin();
    if (it != todo.end()) {
        todo.erase(id);
    }
}

int main(int argc, char* argv[]) {
    if (argc == 1) {
        cout << "Usage: todo del [ STRING ]";
    }

    rawTodo = readIfExists("modules/todo.json");
    todo = json::parse(rawTodo);
    if (argc > 2 && string(argv[1]) == "del") {
        delItem(string(argv[2]));
        exec("echo '' > modules/todo.json");
        writeToFile("modules/todo.json", todo.dump());
    }
}