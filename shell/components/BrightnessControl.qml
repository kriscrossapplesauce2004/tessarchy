import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: control
    property color accentColor: "#a9e8d5"
    // The backlight probe runs once when the shell starts; there is no
    // polling. Machines without a backlight keep the section hidden instead
    // of showing a dead slider; hardware keys use the same helper.
    property bool probed: false
    property int probePercent: 0
    property real level: 0.5

    readonly property bool available: probed && probePercent >= 1

    function setLevel(next) {
        level = Math.max(0.01, Math.min(1, next));
        slider.value = level;
        settle.restart();
    }

    spacing: 6

    Process {
        id: probe
        command: ["tessera-brightness", "get"]
        running: true
        stdout: StdioCollector {
            id: probeOutput
            onDataChanged: {
                const value = parseInt(probeOutput.text.trim(), 10);
                control.probed = true;
                if (!isNaN(value) && value >= 1 && value <= 100) {
                    control.probePercent = value;
                    control.level = value / 100;
                    slider.value = control.level;
                }
            }
        }
    }
    // Rapid changes coalesce into one helper call per quiet period.
    Timer {
        id: settle
        interval: 150
        onTriggered: {
            const percent = Math.max(1, Math.min(100, Math.round(control.level * 100)));
            Quickshell.execDetached(["tessera-brightness", "set", String(percent)]);
        }
    }

    Text {
        visible: control.available
        text: "Brightness · " + Math.round(control.level * 100) + "%"
        color: "#f0f5ff"
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
    }
    LevelSlider {
        id: slider
        visible: control.available
        Layout.fillWidth: true
        from: 0.01
        to: 1
        value: control.level
        accentColor: control.accentColor
        Accessible.name: "Screen brightness"
        onMoved: {
            control.level = value;
            settle.restart();
        }
        onPressedChanged: {
            if (!pressed)
                settle.restart();
        }
    }
    RowLayout {
        visible: control.available
        Layout.fillWidth: true
        TouchButton {
            text: "−"
            Accessible.name: "Decrease brightness"
            accentColor: control.accentColor
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            onClicked: control.setLevel(control.level - 0.1)
        }
        TouchButton {
            text: "Dim"
            Accessible.name: "Dim screen to 10 percent"
            accentColor: control.accentColor
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            onClicked: control.setLevel(0.1)
        }
        TouchButton {
            text: "Bright"
            Accessible.name: "Raise screen to full brightness"
            accentColor: control.accentColor
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            onClicked: control.setLevel(1)
        }
        TouchButton {
            text: "+"
            Accessible.name: "Increase brightness"
            accentColor: control.accentColor
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            onClicked: control.setLevel(control.level + 0.1)
        }
    }
}
