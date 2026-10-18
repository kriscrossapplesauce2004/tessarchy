import QtQuick
import Quickshell.Io

QtObject {
    id: backend
    property var state: ({canControl: false, error: ""})
    readonly property bool busy: worker.running
    property string request: "status"
    property Process worker: Process {
        command: ["python3", decodeURIComponent(Qt.resolvedUrl("../helpers/radios.py").toString().replace("file://", "")), backend.request]
        stdout: StdioCollector {
            id: output
            onStreamFinished: {
                try { backend.state = JSON.parse(text); }
                catch (error) { backend.state = {canControl: false, error: "Radio state is unavailable"}; }
            }
        }
        stderr: StdioCollector {}
        onRunningChanged: {
            if (!running && output.text.length === 0) backend.state = {canControl: false, error: "Radio service is unavailable"};
        }
    }
    property Timer poller: Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.refresh()
    }
    function refresh() {
        if (!worker.running) { request = "status"; worker.running = true; }
    }
    function toggle(name) {
        if (worker.running || ["wifi", "bluetooth", "cellular", "airplane"].indexOf(name) < 0) return;
        request = "toggle-" + name;
        worker.running = true;
    }
}
