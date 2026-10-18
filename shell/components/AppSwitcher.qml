pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../SwitcherPolicy.js" as SwitcherPolicy
import Quickshell
import Quickshell.Wayland

FocusScope {
    id: control
    property var windows: []
    property color accentColor: "#a9e8d5"
    property bool reducedMotion: false
    property bool fillApp: false
    property var pendingTarget: null
    property var selection: null
    readonly property int currentIndex: cards.currentIndex
    signal activated
    signal dismissed
    signal closeRequested(var target)

    function selectActive() {
        cards.currentIndex = SwitcherPolicy.activeIndex(windows);
        selection = windows[cards.currentIndex] || null;
    }
    function step(direction) {
        cards.currentIndex = SwitcherPolicy.advance(windows.indexOf(selection), direction, windows.length);
        selection = windows[cards.currentIndex] || null;
    }
    function activateCurrent() {
        const window = selection && windows.indexOf(selection) >= 0 ? selection : windows[cards.currentIndex];
        if (window && window.wayland) {
            pendingTarget = window.wayland;
            activated();
            // Let the compositor release the switcher's keyboard grab first.
            activateTimer.restart();
        }
        else if (!cards.count) dismissed();
    }
    Timer {
        id: activateTimer
        interval: 100
        onTriggered: {
            const target = control.pendingTarget;
            control.pendingTarget = null;
            if (target) {
                target.activate();
                if (control.fillApp) target.maximized = true;
            }
        }
    }
    Connections {
        target: control.pendingTarget
        function onClosed() { control.pendingTarget = null; }
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
            activateCurrent();
            event.accepted = true;
        }
    }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    Keys.onReturnPressed: activateCurrent()
    Keys.onEnterPressed: activateCurrent()
    Keys.onEscapePressed: dismissed()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        ListView {
            id: cards
            Layout.fillWidth: true
            Layout.fillHeight: true
            // Keep the requested app stable while the floating dock expands.
            onWidthChanged: Qt.callLater(() => { if (control.selection && !moving) currentIndex = control.windows.indexOf(control.selection); })
            onMovementEnded: control.selection = control.windows[currentIndex] || null
            orientation: ListView.Horizontal
            model: control.windows
            spacing: 16
            clip: true
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - Math.min(width * 0.82, 340)) / 2
            preferredHighlightEnd: preferredHighlightBegin
            highlightMoveDuration: control.reducedMotion ? 0 : 180
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property var handle: modelData.wayland
                readonly property var entry: handle ? DesktopEntries.heuristicLookup(handle.appId) : null
                width: Math.min(cards.width * 0.82, 340)
                height: cards.height
                scale: ListView.isCurrentItem ? 1 : 0.94
                Behavior on scale { NumberAnimation { duration: control.reducedMotion ? 0 : 180 } }
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 10
                            color: Qt.alpha(control.accentColor, 0.16)
                            Image { anchors.centerIn: parent; width: 22; height: 22; source: card.entry && card.entry.icon ? Quickshell.iconPath(card.entry.icon) : "../artwork/tessarchy-mark.svg"; sourceSize.width: 22; sourceSize.height: 22 }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.entry ? card.entry.name : card.handle ? card.handle.appId : "Application"
                            color: "#edf5fa"; font.pixelSize: 13; elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 20
                        color: "#4018283d"
                        border.color: card.ListView.isCurrentItem ? Qt.alpha(control.accentColor, 0.65) : "#34465e"
                        Item {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true
                            ScreencopyView {
                                id: preview
                                anchors.fill: parent
                                captureSource: control.visible ? card.handle : null
                                live: control.visible
                                paintCursor: false
                                constraintSize: Qt.size(width, height)
                            }
                            Column {
                                visible: !preview.hasContent
                                anchors.centerIn: parent
                                width: parent.width - 24
                                spacing: 14
                                Image { anchors.horizontalCenter: parent.horizontalCenter; source: "../artwork/tessarchy-mark.svg"; width: 48; height: 48 }
                                Text { width: parent.width; text: card.modelData.title || "Untitled window"; color: "#edf5fa"; wrapMode: Text.WrapAnywhere; horizontalAlignment: Text.AlignHCenter }
                                Text { width: parent.width; text: "Preview unavailable"; color: "#a7bbca"; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12 }
                            }
                            // Taps select; horizontal drags are stolen by the ListView.
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { cards.currentIndex = card.index; control.selection = card.modelData; control.activateCurrent(); }
                                Accessible.name: "Switch to " + (card.modelData.title || "Untitled window")
                                Accessible.role: Accessible.Button
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: card.modelData.title || "Untitled window"
                        color: "#edf5fa"; font.pixelSize: 14; elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
            Text {
                visible: cards.count === 0
                anchors.centerIn: parent
                width: parent.width - 32
                text: "Your open apps will appear here.\nTap Home to launch your first."
                color: "#b7c7cc"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Repeater {
                model: Math.min(cards.count, 9)
                Rectangle {
                    required property int index
                    width: 5; height: 5; radius: 3
                    color: index === cards.currentIndex ? control.accentColor : "#668fa6b6"
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
            TouchButton {
                id: returnButton
                text: "Return to app"
                implicitWidth: 56
                enabled: !!(control.windows[cards.currentIndex] && control.windows[cards.currentIndex].wayland)
                accentColor: control.accentColor
                background: Rectangle { radius: 28; color: returnButton.down ? "#66a9e8d5" : "#351c2c43"; border.color: "#409dbbad" }
                contentItem: Image { source: "../icons/return.svg"; sourceSize.width: 22; sourceSize.height: 22; fillMode: Image.Pad; opacity: parent.enabled ? 1 : 0.35 }
                onClicked: control.activateCurrent()
            }
            TouchButton {
                id: closeButton
                text: "Close window…"
                implicitWidth: 56
                enabled: !!(control.windows[cards.currentIndex] && control.windows[cards.currentIndex].wayland)
                background: Rectangle { radius: 28; color: closeButton.down ? "#66a9e8d5" : "#351c2c43"; border.color: "#409dbbad" }
                contentItem: Image { source: "../icons/close.svg"; sourceSize.width: 22; sourceSize.height: 22; fillMode: Image.Pad; opacity: parent.enabled ? 1 : 0.35 }
                onClicked: control.closeRequested(control.windows[cards.currentIndex].wayland)
            }
        }
    }
}
