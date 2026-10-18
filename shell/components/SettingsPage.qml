pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var preferences
    required property string activeMode
    required property int displayWidth
    required property int displayHeight
    property color accentColor: "#a9e8d5"
    signal endSessionRequested
    signal controlsRequested
    signal replayRequested
    spacing: 20

    RowLayout {
        Layout.fillWidth: true
        BrandMark {
            id: previewBrand
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            playOnStart: false
            reducedMotion: page.preferences.reducedMotion
        }
        ColumnLayout {
            Layout.fillWidth: true
            Text {
                text: "TESSARCHY"
                color: "#f0f5ff"
                font {
                    pixelSize: 20
                    bold: true
                    letterSpacing: 2
                }
            }
            Text {
                text: "One shell. Every screen."
                color: "#8da7b9"
                font.pixelSize: 13
            }
        }
    }
    Text {
        text: "WORKSPACE MODE"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    Text {
        text: page.displayWidth + " × " + page.displayHeight + " logical pixels · " + page.activeMode
        color: "#aabccb"
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    GridLayout {
        columns: width >= 560 ? 4 : 2
        columnSpacing: 10
        rowSpacing: 10
        Layout.fillWidth: true
        Repeater {
            model: [
                {
                    value: "auto",
                    label: "Automatic",
                    icon: "auto"
                },
                {
                    value: "phone",
                    label: "Phone",
                    icon: "phone"
                },
                {
                    value: "tablet",
                    label: "Tablet",
                    icon: "tablet"
                },
                {
                    value: "desktop",
                    label: "Desktop",
                    icon: "desktop"
                }
            ]
            delegate: AppTile {
                required property var modelData
                text: modelData.label
                symbol: modelData.icon
                selected: page.preferences.layoutMode === modelData.value
                accentColor: page.accentColor
                implicitHeight: 100
                onClicked: {
                    page.preferences.layoutMode = modelData.value;
                    page.preferences.sync();
                }
            }
        }
    }
    Text {
        text: "Automatic follows the usable display size, including rotation. Override it to keep a layout. New apps fill Phone/Tablet layouts; Desktop starts apps tiled. Existing windows stay in place. Desktop and wide tablets show a workspace strip in the status bar."
        color: "#8da7b9"
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    Text {
        text: "KEYBOARD"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    Text {
        text: "Super + 1…5 · switch workspace\nSuper + Shift + 1…5 · move window to workspace\nSuper + Q · confirm window close\nSuper + Tab · next window\nSuper + F · maximize · Super + Shift + F · fullscreen\nSuper + Return · terminal · Super + Shift + E · confirm session exit"
        color: "#aabccb"
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    Text {
        text: "APPEARANCE"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: [
                {
                    label: "Mint",
                    value: "mint",
                    color: "#a9e8d5"
                },
                {
                    label: "Iris",
                    value: "iris",
                    color: "#c6b7ff"
                },
                {
                    label: "Ice",
                    value: "ice",
                    color: "#99d7ff"
                }
            ]
            delegate: TouchButton {
                required property var modelData
                text: modelData.label
                selected: page.preferences.accent === modelData.value
                accentColor: modelData.color
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                onClicked: {
                    page.preferences.accent = modelData.value;
                    page.preferences.sync();
                }
            }
        }
    }
    Text {
        text: "Bar opacity · " + Math.round(page.preferences.barOpacity * 100) + "%"
        color: "#d0dced"
        font.pixelSize: 14
    }
    LevelSlider {
        from: 0.1
        to: 1
        value: page.preferences.barOpacity
        Layout.fillWidth: true
        Layout.minimumHeight: 56
        focusPolicy: Qt.NoFocus
        accentColor: page.accentColor
        Accessible.name: "Bar opacity"
        onMoved: page.preferences.barOpacity = value
    }
    Text {
        text: "Wallpaper shade · " + Math.round(page.preferences.wallpaperDim * 100) + "%"
        color: "#d0dced"
        font.pixelSize: 14
    }
    LevelSlider {
        from: 0
        to: 0.75
        value: page.preferences.wallpaperDim
        Layout.fillWidth: true
        Layout.minimumHeight: 56
        focusPolicy: Qt.NoFocus
        accentColor: page.accentColor
        Accessible.name: "Wallpaper shade"
        onMoved: page.preferences.wallpaperDim = value
    }
    TouchButton {
        text: page.preferences.showLabels ? "Navigation labels · On" : "Navigation labels · Off"
        selected: page.preferences.showLabels
        accentColor: page.accentColor
        Layout.fillWidth: true
        onClicked: {
            page.preferences.showLabels = !page.preferences.showLabels;
            page.preferences.sync();
        }
    }
    TouchButton {
        text: page.preferences.use24Hour ? "Clock · 24 hour" : "Clock · 12 hour"
        Layout.fillWidth: true
        onClicked: {
            page.preferences.use24Hour = !page.preferences.use24Hour;
            page.preferences.sync();
        }
    }
    Text {
        text: "MOTION"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    TouchButton {
        text: page.preferences.reducedMotion ? "Reduced motion · On" : "Reduced motion · Off"
        selected: page.preferences.reducedMotion
        accentColor: page.accentColor
        Layout.fillWidth: true
        onClicked: {
            page.preferences.reducedMotion = !page.preferences.reducedMotion;
            page.preferences.sync();
        }
    }
    RowLayout {
        Layout.fillWidth: true
        BrandMark {
            id: motionPreview
            Layout.preferredWidth: 80
            Layout.preferredHeight: 80
            playOnStart: false
            reducedMotion: page.preferences.reducedMotion
        }
        TouchButton {
            text: "Replay logo"
            enabled: !page.preferences.reducedMotion
            Layout.fillWidth: true
            onClicked: {
                previewBrand.replay();
                motionPreview.replay();
                page.replayRequested();
            }
        }
    }
    Text {
        text: "SYSTEM"
        color: page.accentColor
        font {
            pixelSize: 11
            bold: true
            letterSpacing: 2
        }
    }
    TouchButton {
        text: "Sound & connections"
        Layout.fillWidth: true
        onClicked: page.controlsRequested()
    }
    TouchButton {
        text: "Session…"
        Layout.fillWidth: true
        onClicked: page.endSessionRequested()
    }
    Text {
        text: "Tessera 0.1 · Experimental Arch session\nInitial text entry requires a physical keyboard."
        color: "#8da7b9"
        font.pixelSize: 12
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
