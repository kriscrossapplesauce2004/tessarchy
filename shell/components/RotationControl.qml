import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../LayoutPolicy.js" as Policy

ColumnLayout {
    id: control
    property color accentColor: "#a9e8d5"

    readonly property var monitor: Hyprland.focusedMonitor
    readonly property int transform: {
        if (!control.monitor || !control.monitor.lastIpcObject)
            return 0;
        const value = control.monitor.lastIpcObject.transform;
        return Number.isInteger(value) && value >= 0 && value < 4 ? value : 0;
    }
    readonly property string orientation: ["0°", "90°", "180°", "270°"][control.transform]

    spacing: 6

    function rotate() {
        if (!control.monitor)
            return;
        const next = Policy.nextTransform(control.transform);
        // Fixed argv: the monitor name comes from the compositor and the
        // transform from our own cycle, so nothing user-supplied is parsed.
        Quickshell.execDetached(["hyprctl", "keyword", "monitor",
                                 control.monitor.name + ",transform," + next]);
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: Hyprland.refreshMonitors()
    }

    Text {
        text: "Screen orientation · " + (control.monitor ? control.orientation : "no monitor")
        color: "#d0dced"
        font.pixelSize: 14
    }
    TouchButton {
        text: "Rotate screen"
        enabled: control.monitor !== null
        accentColor: control.accentColor
        Layout.fillWidth: true
        Accessible.name: control.monitor ? "Rotate screen, now " + control.orientation : "Rotate screen unavailable"
        onClicked: control.rotate()
    }
}
