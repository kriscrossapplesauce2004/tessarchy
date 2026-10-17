import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../LayoutPolicy.js" as Policy

ColumnLayout {
    id: panel
    property color accentColor: "#a9e8d5"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: !!(sink && sink.ready && sink.audio)
    readonly property var devices: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream)
    readonly property var streams: Pipewire.nodes.values.filter(node => node.isStream && node.audio && !node.isSink && Policy.playbackStream(node.properties["media.class"]))

    spacing: 6

    // Keep every device and stream we display alive while this page is open.
    PwObjectTracker {
        objects: panel.devices.concat(panel.streams)
    }

    Text {
        text: {
            if (!panel.available)
                return "No audio output connected";
            const name = Policy.nodeLabel(panel.sink.description, panel.sink.nickname, panel.sink.name);
            if (panel.sink.audio.muted)
                return "Muted · " + name;
            return "Volume · " + Policy.volumePercent(panel.sink.audio.volume) + "% · " + name;
        }
        color: "#f0f5ff"
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
    }
    LevelSlider {
        Layout.fillWidth: true
        from: 0
        to: 1
        value: panel.available ? panel.sink.audio.volume : 0
        enabled: panel.available
        accentColor: panel.accentColor
        Accessible.name: "Output volume"
        onMoved: panel.sink.audio.volume = value
    }
    RowLayout {
        Layout.fillWidth: true
        TouchButton {
            text: "−"
            Accessible.name: "Decrease volume"
            enabled: panel.available
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            onClicked: panel.sink.audio.volume = Math.max(0, panel.sink.audio.volume - 0.05)
        }
        TouchButton {
            text: panel.available && panel.sink.audio.muted ? "Unmute" : "Mute"
            enabled: panel.available
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            onClicked: panel.sink.audio.muted = !panel.sink.audio.muted
        }
        TouchButton {
            text: "+"
            Accessible.name: "Increase volume"
            enabled: panel.available
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            onClicked: panel.sink.audio.volume = Math.min(1, panel.sink.audio.volume + 0.05)
        }
    }
    Text {
        visible: panel.devices.length > 1
        text: "OUTPUT DEVICE"
        color: "#8da7b9"
        font {
            pixelSize: 11
            letterSpacing: 2
        }
    }
    Repeater {
        model: panel.devices
        delegate: TouchButton {
            required property var modelData
            visible: panel.devices.length > 1
            selected: modelData === panel.sink
            accentColor: panel.accentColor
            Layout.fillWidth: true
            text: Policy.nodeLabel(modelData.description, modelData.nickname, modelData.name)
            Accessible.name: "Use output device " + text
            onClicked: {
                if (modelData !== panel.sink)
                    Pipewire.preferredDefaultAudioSink = modelData;
            }
        }
    }
    Text {
        visible: panel.streams.length > 0
        text: "APPS"
        color: "#8da7b9"
        font {
            pixelSize: 11
            letterSpacing: 2
        }
    }
    Repeater {
        model: panel.streams
        delegate: ColumnLayout {
            id: streamRow
            required property var modelData
            readonly property string streamName: Policy.streamLabel(streamRow.modelData.properties["application.name"], streamRow.modelData.properties["media.name"], streamRow.modelData.name)

            Layout.fillWidth: true
            spacing: 2
            Text {
                text: (streamRow.modelData.audio.muted ? "Muted · " : "") + streamRow.streamName
                color: "#f0f5ff"
                Layout.fillWidth: true
                wrapMode: Text.WrapAnywhere
            }
            RowLayout {
                Layout.fillWidth: true
                LevelSlider {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 3
                    from: 0
                    to: 1
                    value: streamRow.modelData.audio.volume
                    accentColor: panel.accentColor
                    Accessible.name: "Volume for " + streamRow.streamName
                    onMoved: streamRow.modelData.audio.volume = value
                }
                TouchButton {
                    text: streamRow.modelData.audio.muted ? "Unmute" : "Mute"
                    accentColor: panel.accentColor
                    Layout.preferredWidth: 1
                    Accessible.name: (streamRow.modelData.audio.muted ? "Unmute " : "Mute ") + streamRow.streamName
                    onClicked: streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted
                }
            }
        }
    }
}
