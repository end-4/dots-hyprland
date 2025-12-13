import qs
import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    width: 800
    height: 520

    property string notesDir: "Documents/.notes"
    property string currentFilePath: ""
    property bool unlocked: false
    property string lastPassword: ""
    
    property string fileToDeleteAfterSave: ""
    property string pendingUnlockPath: ""
    property string filterMode: "All" 
    property string pendingSaveAction: "save" 
    property int pendingInfoIndex: -1
    property string _cleanText: ""

    signal locked()
    signal unlockedSignal()

    Rectangle {
        anchors.fill: parent
        color: "#101010"
    }

    StackLayout {
        id: stack
        anchors.fill: parent
        currentIndex: 0

        NotesBrowser {
            id: browser
            model: notesListModel
            isRefreshing: listProc.running
            
            onFilterChanged: (mode) => {
                root.filterMode = mode
                refreshFileList()
            }
            onRefreshRequested: refreshFileList()
            
            onCreateRequested: {
                overlays.mode = "create"
                overlays.resetInputs()
                overlays.focusInput()
            }
            
            onNoteFlipped: (index, path) => fetchFileInfo(index, path)
            
            onNoteOpened: (path, isEncrypted) => {
                root.currentFilePath = path
                if (isEncrypted) {
                    root.pendingUnlockPath = path
                    overlays.mode = "unlock"
                    overlays.resetInputs()
                    overlays.focusInput()
                } else {
                    notesUnlock(path, "")
                }
            }
        }

        NotesEditor {
            id: editor
            filePath: root.currentFilePath
            unlocked: root.unlocked
            
            onBackRequested: {
                if (editor.text !== root._cleanText) {
                    overlays.unsavedVisible = true
                } else {
                    lockNotes()
                }
            }
            
            onSaveRequested: notesSave()
            
            onRenameRequested: {
                overlays.mode = "rename"
                var name = root.currentFilePath.split('/').pop().replace(/\.(txt|enc)$/, "")
                overlays.setInput1(name)
                overlays.focusInput()
            }
            
            onEncryptRequested: {
                overlays.mode = "encrypt"
                overlays.resetInputs()
            }
            
            onDecryptRequested: {
                overlays.mode = "decrypt"
                overlays.resetInputs()
                overlays.focusInput()
            }
            
            onDeleteRequested: overlays.deleteVisible = true
        }
    }

    NotesOverlays {
        id: overlays
        
        onUnsavedAction: (action) => {
            overlays.unsavedVisible = false
            if (action === "save") notesSave()
            lockNotes()
        }
        
        onDeleteConfirmed: deleteCurrentNotes()
        
        onActionConfirmed: (mode, t1, t2) => {
            handleOverlayAction(mode, t1, t2)
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        enabled: stack.currentIndex === 1 && unlocked
        onActivated: notesSave()
    }
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: {
            overlays.mode = "create"
            overlays.resetInputs()
            overlays.focusInput()
        }
    }

    ListModel { id: notesListModel }

    function handleOverlayAction(mode, text1, text2) {
        if (mode === "unlock") {
            if (pendingUnlockPath !== "") notesUnlock(pendingUnlockPath, text1)
        } 
        else if (mode === "create") {
            var filename = text1.trim()
            if (filename === "") return
            if (!filename.endsWith(".txt")) filename += ".txt"
            
            if (checkFileExists(filename.replace(".txt", ""))) {
                overlays.shake()
                return
            }
            createNotes(notesDir + "/" + filename, "")
            overlays.mode = "none"
        }
        else if (mode === "rename") {
            var newName = text1.trim()
            if (newName === "") return
            
            var ext = currentFilePath.endsWith(".enc") ? ".enc" : ".txt"
            var fullNewName = newName + ext
            var currentName = currentFilePath.split('/').pop()
            
            if (fullNewName === currentName) {
                overlays.mode = "none"
                return
            }
            if (checkFileExists(newName)) {
                overlays.shake()
                return
            }
            renameNotes(currentFilePath, notesDir + "/" + fullNewName)
            overlays.mode = "none"
        }
        else if (mode === "encrypt") {
            if (text1 !== text2) {
                overlays.shake()
                return
            }
            convertToEncrypted(text1)
            overlays.mode = "none"
        }
        else if (mode === "decrypt") {
            if (text1 !== lastPassword) {
                overlays.shake()
                return
            }
            convertToPlain()
            overlays.mode = "none"
        }
    }

    function checkFileExists(baseName) {
        for(var i=0; i<notesListModel.count; i++) {
            var existingName = notesListModel.get(i).fileName
            var existingBase = existingName.replace(/\.(txt|enc)$/, "")
            if (existingBase === baseName) return true
        }
        return false
    }

    function lockNotes() {
        unlocked = false
        lastPassword = ""
        currentFilePath = ""
        editor.text = ""
        stack.currentIndex = 0
        locked()
    }

    function shellEscape(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'";
    }

    function refreshFileList() {
        notesListModel.clear();
        var filterCmd = "";
        if (filterMode === "Notes") filterCmd = " -name '*.txt'";
        else if (filterMode === "Encrypted") filterCmd = " -name '*.enc'";

        var cmd = "mkdir -p " + shellEscape(notesDir) +
                  " && find " + shellEscape(notesDir) + " -maxdepth 1 -type f" + filterCmd + " -printf '%f\\n'";
        listProc.command = ["bash", "-c", cmd];
        listProc.running = true;
    }

    Process {
        id: listProc
        stdout: SplitParser {
            onRead: data => {
                var fname = data.trim()
                if (fname) {
                    var unique = true
                    for(var i=0; i<notesListModel.count; i++) {
                        if (notesListModel.get(i).fileName === fname) {
                            unique = false; break;
                        }
                    }
                    if (unique) {
                        notesListModel.append({ 
                            fileName: fname, 
                            filePath: root.notesDir + "/" + fname,
                            fileDetails: "" 
                        })
                    }
                }
            }
        }
    }

    function fetchFileInfo(index, path) {
        pendingInfoIndex = index
        var cmd = "stat -c '%Y|%s' " + shellEscape(path)
        infoProc.command = ["bash", "-c", cmd]
        infoProc.running = true
    }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onTextChanged: {
                if (pendingInfoIndex > -1 && pendingInfoIndex < notesListModel.count) {
                    var parts = text.trim().split('|');
                    if (parts.length === 2) {
                        var ts = parseInt(parts[0]) * 1000; 
                        var size = parseInt(parts[1]);
                        var dateStr = Qt.formatDateTime(new Date(ts), "yyyy-MM-dd HH:mm");
                        var sizeStr = (size < 1024) ? (size + " B") : ((size / 1024).toFixed(1) + " KB");
                        var finalStr = "Modified:\n" + dateStr + "\n\nSize:\n" + sizeStr;
                        notesListModel.setProperty(pendingInfoIndex, "fileDetails", finalStr);
                    }
                }
            }
        }
    }

    function notesUnlock(path, password) {
        unlockProc.pendingPath = path
        unlockProc.pendingPassword = password
        var cmd;
        if (path.endsWith(".enc")) {
            cmd = "printf '%s' " + shellEscape(password) +
                " | openssl enc -aes-256-cbc -pbkdf2 -d -iter 100000 -in " +
                shellEscape(path) + " -pass stdin"
        } else {
            cmd = "cat " + shellEscape(path)
        }
        unlockProc.command = ["bash", "-c", cmd]
        unlockProc.running = true
    }

    Process {
        id: unlockProc
        property string pendingPassword
        property string pendingPath
        stdout: StdioCollector { id: unlockOut }
        onExited: (code) => {
            if (code === 0) {
                editor.text = unlockOut.text
                _cleanText = unlockOut.text  
                unlocked = true
                lastPassword = pendingPassword
                currentFilePath = pendingPath
                stack.currentIndex = 1
                overlays.mode = "none"
            } else {
                if (overlays.mode === "unlock") overlays.shake()
            }
        }
    }

    function notesSave() {
        var tmp = "/tmp/qs_save_" + Math.random().toString().slice(2)
        var script = ""
        var args = []
        if (currentFilePath.endsWith(".enc")) {
            script = "printf '%s' \"$1\" > \"$2\" && " +
                     "printf '%s' \"$3\" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in \"$2\" -out \"$4\" -pass stdin && " +
                     "rm -f \"$2\""
            args = ["bash", "-c", script, "qs-save", editor.text, tmp, lastPassword, currentFilePath]
        } else {
            script = "printf '%s' \"$1\" > \"$2\" && mv \"$2\" \"$3\""
            args = ["bash", "-c", script, "qs-save", editor.text, tmp, currentFilePath]
        }
        saveProc.command = args
        saveProc.running = true
    }

    Process {
        id: saveProc
        onExited: (code) => {
            if (code === 0) {
                if (pendingSaveAction === "encrypt") editor.triggerLockAnim(true)
                else if (pendingSaveAction === "decrypt") editor.triggerLockAnim(false)
                else editor.notify("Saved")
                
                pendingSaveAction = "save"
                _cleanText = editor.text
                
                if (fileToDeleteAfterSave !== "") {
                    var cmd = "rm " + shellEscape(fileToDeleteAfterSave)
                    listProc.command = ["bash", "-c", cmd]
                    listProc.running = true
                    fileToDeleteAfterSave = ""
                    refreshFileList()
                }
            } else {
                editor.notify("Save failed")
            }
        }
    }

    function createNotes(path, password) {
        createProc.pendingPath = path
        createProc.pendingPassword = password
        var cmd;
        if (path.endsWith(".enc")) {
            var tmp = "/tmp/qs_new_" + Math.random().toString().slice(2)
            var write = "printf '' > " + shellEscape(tmp)
            var enc  = "printf '%s' " + shellEscape(password) +
                       " | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in " +
                       shellEscape(tmp) + " -out " + shellEscape(path) + " -pass stdin"
            cmd = "mkdir -p " + shellEscape(notesDir) + " && " + write + " && " + enc + " && rm -f " + shellEscape(tmp)
        } else {
            cmd = "mkdir -p " + shellEscape(notesDir) + " && touch " + shellEscape(path)
        }
        createProc.command = ["bash", "-c", cmd]
        createProc.running = true
    }

    Process {
        id: createProc
        property string pendingPassword
        property string pendingPath
        onExited: (code) => {
            if (code === 0) {
                unlocked = true
                lastPassword = pendingPassword
                currentFilePath = pendingPath
                editor.text = ""
                _cleanText = ""  
                stack.currentIndex = 1
                editor.notify("Note created")
                refreshFileList()
            }
        }
    }

    function renameNotes(oldPath, newPath) {
        renameProc.newPath = newPath
        var cmd = "mv " + shellEscape(oldPath) + " " + shellEscape(newPath)
        renameProc.command = ["bash", "-c", cmd]
        renameProc.running = true
    }

    Process {
        id: renameProc
        property string newPath
        onExited: (code) => {
            if (code === 0) {
                currentFilePath = newPath
                editor.notify("Renamed")
                refreshFileList()
            }
        }
    }

    function deleteCurrentNotes() {
        if (currentFilePath === "") return;
        var cmd = "rm " + shellEscape(currentFilePath);
        deleteProc.command = ["bash", "-c", cmd];
        deleteProc.running = true;
    }

    Process {
        id: deleteProc
        onExited: (code) => {
            if (code === 0) {
                lockNotes()
                refreshFileList()
            }
        }
    }

    function convertToEncrypted(pass) {
        pendingSaveAction = "encrypt"
        fileToDeleteAfterSave = currentFilePath
        currentFilePath = currentFilePath.replace(/\.txt$/, ".enc")
        lastPassword = pass
        notesSave()
    }

    function convertToPlain() {
        pendingSaveAction = "decrypt"
        fileToDeleteAfterSave = currentFilePath
        currentFilePath = currentFilePath.replace(/\.enc$/, ".txt")
        lastPassword = ""
        notesSave()
    }

    Component.onCompleted: refreshFileList()
}
