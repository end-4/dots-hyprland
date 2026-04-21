import Quickshell

ScriptModel {
    required property int count
    values: Array(count).map((_, i) => i)
}
