import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: control
    property color accentColor: "#a9e8d5"
    property bool nightLight: false

    // One-shot probe for the helper and backend; there is no polling. The
    // toggle is hidden when hyprsunset is not installed, and the stored
    // preference re-applies on shell start through onCompleted below.
    property bool probed: false
    readonly property bool available: probed && probe.exitCode !== 3

    spacing: 6

    Process {
        id: probe
        command: ["tessera-nightlight", "status"]
        running: true
        onExited: (exitCode, exitStatus) => {
            control.probed = true;
            if (exitCode !== 3)
                control.applyPreference();
        }
    }
    function applyPreference() {
        Quickshell.execDetached(["tessera-nightlight", control.nightLight ? "on" : "off"]);
    }
    onNightLightChanged: {
        if (probed && available)
            applyPreference();
    }

    TouchButton {
        visible: control.available
        Layout.fillWidth: true
        text: control.available && control.nightLight ? "Night light on" : "Night light"
        selected: control.nightLight
        accentColor: control.accentColor
        Accessible.name: control.nightLight ? "Turn night light off" : "Turn night light on"
        onClicked: control.nightLight = !control.nightLight
    }
}
