pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import "components"
import "LayoutPolicy.js" as Policy

ShellRoot {
    id: root
    signal replayBrand
    readonly property color accentColor: shellPreferences.accent === "iris" ? "#c6b7ff" : shellPreferences.accent === "ice" ? "#99d7ff" : "#a9e8d5"
    Settings {
        id: shellPreferences
        location: "file://" + (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/tessarchy/shell.ini"
        category: "Shell"
        property string layoutMode: "auto"
        property string accent: "mint"
        property bool reducedMotion: false
        property bool showLabels: true
        property bool use24Hour: true
        property real barOpacity: 0.32
        property real wallpaperDim: 0.12
    }
    // Bind these when wireless/modem integrations land. Never invent a signal.
    property real wifiStrength: -1
    property real cellularStrength: -1
    readonly property var audioSink: audioLoader.item ? (audioLoader.item as AudioStatus).sink : null
    readonly property bool audioAvailable: !!(audioSink && audioSink.ready && audioSink.audio)
    readonly property int volumePercent: audioAvailable ? Math.round(audioSink.audio.volume * 100) : 0
    Loader {
        id: audioLoader
        active: Quickshell.env("TESSARCHY_AUDIO") === "1"
        source: "components/AudioStatus.qml"
    }
    Variants {
        model: Quickshell.screens
        Scope {
            id: surface
            required property var modelData
            readonly property string mode: Policy.effectiveMode(shellPreferences.layoutMode, modelData.width, modelData.height)
            readonly property bool isPhone: mode === "phone"
            readonly property int navHeight: isPhone ? 72 : 80
            readonly property int launcherRows: Math.ceil(4 / Policy.columns(mode, Policy.panelWidth(mode, modelData.width) - 32))
            readonly property string modeLabel: (shellPreferences.layoutMode === "auto" ? "Auto · " : "") + Policy.title(mode)
            // Bumped whenever window previews should recapture (page open, Refresh, mode actions).
            property int windowPreviewTick: 0
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
            PanelWindow {
                id: panel
                screen: surface.modelData
                property string page: ""
                property var closeTarget: null
                readonly property bool expanded: page !== ""
                anchors {
                    bottom: true
                    left: surface.isPhone
                    right: surface.isPhone
                }
                implicitWidth: Policy.panelWidth(surface.mode, surface.modelData.width)
                implicitHeight: expanded ? Math.min(page === "apps" ? surface.launcherRows * 124 + 156 : surface.mode === "tablet" ? 740 : 640, surface.modelData.height - 64) : surface.navHeight
                exclusiveZone: surface.navHeight
                color: "transparent"
                Rectangle {
                    anchors.fill: parent
                    radius: surface.isPhone ? 0 : 24
                    color: panel.expanded ? "#101b30" : Qt.rgba(0.063, 0.106, 0.188, shellPreferences.barOpacity)
                    border.width: surface.isPhone ? 0 : 1
                    border.color: Qt.alpha(root.accentColor, 0.15)
                }
                WlrLayershell.namespace: "tessera"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                function showPage(name) {
                    closeTarget = null;
                    page = page === name ? "" : name;
                }
                function launch(command) {
                    Quickshell.execDetached(command);
                    page = "";
                }
                Connections {
                    target: panel.closeTarget
                    function onClosed() {
                        panel.closeTarget = null;
                        panel.page = "windows";
                    }
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: surface.isPhone ? 12 : 16
                    anchors.rightMargin: surface.isPhone ? 12 : 16
                    spacing: 8
                    ColumnLayout {
                        visible: panel.expanded
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        Text {
                            text: panel.page === "apps" ? "Your space" : panel.page === "windows" ? "Recent apps" : panel.page === "close" ? "Close this window?" : panel.page === "status" ? "Quick controls" : panel.page === "settings" ? "Settings" : "End this session?"
                            color: root.accentColor
                            font.pixelSize: 22
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth
                            ColumnLayout {
                                width: parent.width
                                spacing: 8
                                ColumnLayout {
                                    visible: panel.page === "apps"
                                    Layout.fillWidth: true
                                    GridLayout {
                                        columns: Policy.columns(surface.mode, width)
                                        columnSpacing: 12
                                        Layout.fillWidth: true
                                        AppTile {
                                            text: "Browser"
                                            symbol: "browser"
                                            accentColor: root.accentColor
                                            onClicked: panel.launch(["firefox"])
                                        }
                                        AppTile {
                                            text: "Terminal"
                                            symbol: "terminal"
                                            accentColor: root.accentColor
                                            onClicked: panel.launch(["foot"])
                                        }
                                        AppTile {
                                            text: "Settings"
                                            symbol: "settings"
                                            accentColor: root.accentColor
                                            onClicked: panel.showPage("settings")
                                        }
                                        AppTile {
                                            text: "Controls"
                                            symbol: "controls"
                                            accentColor: root.accentColor
                                            onClicked: panel.showPage("status")
                                        }
                                    }
                                    Text {
                                        text: "Prototype · Physical keyboard needed for text input."
                                        color: "#b7c7cc"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                                Loader {
                                    visible: active
                                    active: panel.page === "settings"
                                    Layout.fillWidth: true
                                    sourceComponent: SettingsPage {
                                        preferences: shellPreferences
                                        activeMode: Policy.title(surface.mode)
                                        displayWidth: surface.modelData.width
                                        displayHeight: surface.modelData.height
                                        accentColor: root.accentColor
                                        onEndSessionRequested: panel.page = "session"
                                        onControlsRequested: panel.page = "status"
                                        onReplayRequested: root.replayBrand()
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "windows"
                                    Layout.fillWidth: true
                                    onVisibleChanged: {
                                        if (visible)
                                            surface.windowPreviewTick++;
                                    }
                                    Text {
                                        visible: Hyprland.toplevels.values.length === 0
                                        text: "No recent apps. Tap Home to launch one."
                                        color: "#b7c7cc"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                    TouchButton {
                                        visible: Hyprland.toplevels.values.length > 0
                                        text: "Refresh previews"
                                        Layout.fillWidth: true
                                        Accessible.name: "Recapture window previews"
                                        onClicked: surface.windowPreviewTick++
                                    }
                                    GridLayout {
                                        visible: Hyprland.toplevels.values.length > 0
                                        columns: Policy.columns(surface.mode, surface.modelData.width)
                                        columnSpacing: 12
                                        rowSpacing: 12
                                        Layout.fillWidth: true
                                        Repeater {
                                            model: Hyprland.toplevels
                                            delegate: ColumnLayout {
                                                id: windowRow
                                                required property var modelData
                                                readonly property var handle: modelData.wayland
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignTop
                                                spacing: 4
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.minimumHeight: 48
                                                    implicitHeight: Math.round(width / 1.6)
                                                    radius: 12
                                                    color: "#0d1728"
                                                    border.width: 1
                                                    border.color: windowRow.modelData.activated ? root.accentColor : "#34465e"
                                                    clip: true
                                                    // A compositor-assisted snapshot, captured when
                                                    // this page opens or Refresh is tapped. Windows the
                                                    // compositor cannot copy, or that are hidden, simply
                                                    // keep hasContent false and show their title instead.
                                                    ScreencopyView {
                                                        id: preview
                                                        anchors.fill: parent
                                                        anchors.margins: 2
                                                        visible: preview.hasContent
                                                        captureSource: windowRow.handle
                                                        live: false
                                                        paintCursor: false
                                                        constraintSize: Qt.size(width, height)
                                                    }
                                                    Text {
                                                        anchors.fill: parent
                                                        anchors.margins: 12
                                                        visible: !preview.hasContent
                                                        text: windowRow.modelData.title || "Untitled window"
                                                        color: "#b7c7cc"
                                                        wrapMode: Text.WrapAnywhere
                                                        elide: Text.ElideRight
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                }
                                                TouchButton {
                                                    text: (windowRow.modelData.activated ? "● " : "") + (windowRow.modelData.title || "Untitled window")
                                                    Layout.fillWidth: true
                                                    enabled: windowRow.handle !== null
                                                    onClicked: {
                                                        windowRow.handle.activate();
                                                        panel.page = "";
                                                    }
                                                }
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    TouchButton {
                                                        text: windowRow.handle && windowRow.handle.maximized ? "Restore" : "Maximize"
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: 1
                                                        enabled: windowRow.handle !== null
                                                        onClicked: {
                                                            windowRow.handle.maximized = !windowRow.handle.maximized;
                                                            surface.windowPreviewTick++;
                                                        }
                                                    }
                                                    TouchButton {
                                                        text: "Close…"
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: 1
                                                        enabled: windowRow.handle !== null
                                                        onClicked: {
                                                            panel.closeTarget = windowRow.handle;
                                                            panel.page = "close";
                                                        }
                                                    }
                                                }
                                                // Recapture on page open and manual refresh so
                                                // previews do not go stale.
                                                readonly property int refreshTick: surface.windowPreviewTick
                                                onRefreshTickChanged: {
                                                    if (panel.page === "windows" && windowRow.handle !== null)
                                                        preview.captureFrame();
                                                }
                                            }
                                        }
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "close"
                                    Layout.fillWidth: true
                                    Text {
                                        text: panel.closeTarget ? panel.closeTarget.title : "Window is no longer available."
                                        color: "#f0f5f5"
                                        wrapMode: Text.WrapAnywhere
                                        Layout.fillWidth: true
                                    }
                                    TouchButton {
                                        text: "Cancel"
                                        Layout.fillWidth: true
                                        onClicked: {
                                            panel.closeTarget = null;
                                            panel.page = "windows";
                                        }
                                    }
                                    TouchButton {
                                        text: "Close window"
                                        destructive: true
                                        enabled: panel.closeTarget !== null
                                        Layout.fillWidth: true
                                        onClicked: {
                                            const target = panel.closeTarget;
                                            panel.closeTarget = null;
                                            panel.page = "windows";
                                            if (target)
                                                target.close();
                                        }
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "status"
                                    Layout.fillWidth: true
                                    spacing: 16
                                    Text {
                                        text: "CONNECTIONS"
                                        color: "#8da7b9"
                                        font {
                                            pixelSize: 11
                                            letterSpacing: 2
                                        }
                                    }
                                    Text {
                                        text: root.wifiStrength < 0 ? "Wi-Fi · unavailable" : "Wi-Fi · connected"
                                        color: "#f0f5ff"
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: root.cellularStrength < 0 ? "Cellular · no modem connected" : "Cellular · connected"
                                        color: "#f0f5ff"
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        text: "SOUND"
                                        color: "#8da7b9"
                                        font {
                                            pixelSize: 11
                                            letterSpacing: 2
                                        }
                                    }
                                    Text {
                                        text: root.audioAvailable ? (root.audioSink.audio.muted ? "Muted" : "Volume · " + root.volumePercent + "%") : "No audio output connected"
                                        color: "#f0f5ff"
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    LevelSlider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 1
                                        value: root.audioAvailable ? root.audioSink.audio.volume : 0
                                        enabled: root.audioAvailable
                                        accentColor: root.accentColor
                                        Accessible.name: "Output volume"
                                        onMoved: root.audioSink.audio.volume = value
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        TouchButton {
                                            text: "−"
                                            Accessible.name: "Decrease volume"
                                            enabled: root.audioAvailable
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            onClicked: root.audioSink.audio.volume = Math.max(0, root.audioSink.audio.volume - 0.05)
                                        }
                                        TouchButton {
                                            text: root.audioAvailable && root.audioSink.audio.muted ? "Unmute" : "Mute"
                                            enabled: root.audioAvailable
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            onClicked: root.audioSink.audio.muted = !root.audioSink.audio.muted
                                        }
                                        TouchButton {
                                            text: "+"
                                            Accessible.name: "Increase volume"
                                            enabled: root.audioAvailable
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            onClicked: root.audioSink.audio.volume = Math.min(1, root.audioSink.audio.volume + 0.05)
                                        }
                                    }
                                }
                                RowLayout {
                                    visible: panel.page === "status"
                                    Layout.fillWidth: true
                                    TouchButton {
                                        text: "Settings"
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        onClicked: panel.page = "settings"
                                    }
                                    TouchButton {
                                        text: "Session…"
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        onClicked: panel.page = "session"
                                    }
                                }
                                ColumnLayout {
                                    visible: panel.page === "session"
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Save your work before ending Tessarchy. This closes the desktop session."
                                        color: "#f0f5f5"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                    TouchButton {
                                        text: "Cancel"
                                        Layout.fillWidth: true
                                        onClicked: panel.page = ""
                                    }
                                    TouchButton {
                                        text: "End session"
                                        destructive: true
                                        Layout.fillWidth: true
                                        onClicked: Hyprland.dispatch("hl.dsp.exit()")
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        spacing: 8
                        NavButton {
                            text: "Back"
                            symbol: "back"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            enabled: panel.expanded
                            onClicked: {
                                panel.closeTarget = null;
                                panel.page = "";
                            }
                        }
                        NavButton {
                            text: surface.mode === "desktop" ? "Apps" : "Home"
                            symbol: "home"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "apps"
                            onClicked: panel.showPage("apps")
                        }
                        NavButton {
                            text: surface.mode === "desktop" ? "Windows" : "Recents"
                            symbol: "recents"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "windows"
                            onClicked: panel.showPage("windows")
                        }
                        NavButton {
                            visible: !surface.isPhone
                            text: "Settings"
                            symbol: "settings"
                            showLabel: shellPreferences.showLabels
                            accentColor: root.accentColor
                            selected: panel.page === "settings"
                            onClicked: panel.showPage("settings")
                        }
                    }
                }
            }
            PanelWindow {
                screen: surface.modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: 48
                exclusiveZone: 48
                color: Qt.rgba(0.063, 0.106, 0.188, Math.min(1, shellPreferences.barOpacity + 0.12))
                WlrLayershell.namespace: "tessera-status"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 8
                    spacing: surface.modelData.width < 360 ? 4 : 8
                    Text {
                        text: Qt.formatDateTime(clock.date, shellPreferences.use24Hour ? "hh:mm" : "h:mm AP")
                        color: "#f0f5ff"
                        font {
                            pixelSize: 16
                            bold: true
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    TouchButton {
                        visible: surface.modelData.width >= 650
                        text: surface.modeLabel
                        implicitWidth: 170
                        implicitHeight: 48
                        Layout.minimumHeight: 48
                        accentColor: root.accentColor
                        onClicked: panel.showPage("settings")
                    }
                    // Only registered application icons appear; no simulated signals.
                    RowLayout {
                        Layout.maximumWidth: Math.max(0, surface.modelData.width - (surface.modelData.width >= 650 ? 540 : 370))
                        clip: true
                        spacing: 0
                        Repeater {
                            model: SystemTray.items
                            delegate: TouchButton {
                                id: trayButton
                                required property var modelData
                                text: modelData.title
                                implicitWidth: 48
                                implicitHeight: 48
                                Layout.minimumHeight: 48
                                Layout.preferredWidth: 48
                                contentItem: Image {
                                    source: trayButton.modelData.icon
                                    sourceSize.width: 20
                                    sourceSize.height: 20
                                    fillMode: Image.Pad
                                }
                                onClicked: {
                                    if (modelData.hasMenu)
                                        modelData.display(trayButton.QsWindow.window, 0, 48);
                                    else
                                        modelData.activate();
                                }
                            }
                        }
                    }
                    StatusIcon {
                        symbol: "cellular"
                        label: "Cellular"
                        strength: root.cellularStrength
                    }
                    StatusIcon {
                        symbol: "wifi"
                        label: "Wi-Fi"
                        strength: root.wifiStrength
                    }
                    NavButton {
                        text: root.audioAvailable ? "Volume " + root.volumePercent + "%" : "Quick controls · audio unavailable"
                        symbol: root.audioAvailable && root.audioSink.audio.muted ? "volume-muted" : "volume"
                        showLabel: false
                        implicitWidth: 48
                        implicitHeight: 48
                        Layout.minimumHeight: 48
                        Layout.fillWidth: false
                        Layout.preferredWidth: 48
                        selected: panel.page === "status"
                        onClicked: panel.showPage("status")
                    }
                    RowLayout {
                        spacing: 4
                        Image {
                            source: "icons/battery.svg"
                            sourceSize.width: 22
                            sourceSize.height: 22
                            opacity: UPower.displayDevice.isPresent ? 1 : 0.35
                        }
                        Text {
                            visible: surface.modelData.width >= 380
                            text: UPower.displayDevice.isPresent ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "—"
                            color: "#a9e8d5"
                            font.pixelSize: 11
                            Accessible.name: UPower.displayDevice.isPresent ? "Battery " + text : "Battery status unavailable"
                        }
                    }
                    NavButton {
                        text: "Settings"
                        symbol: "settings"
                        showLabel: false
                        implicitWidth: 48
                        implicitHeight: 48
                        Layout.minimumHeight: 48
                        Layout.fillWidth: false
                        Layout.preferredWidth: 48
                        accentColor: root.accentColor
                        selected: panel.page === "settings"
                        onClicked: panel.showPage("settings")
                    }
                }
            }
            PanelWindow {
                screen: surface.modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                color: "#101b30"
                WlrLayershell.namespace: "tessera-home"
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                Image {
                    anchors.fill: parent
                    source: "artwork/aurora-fold.png"
                    fillMode: Image.PreserveAspectCrop
                }
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.016, 0.05, 0.1, shellPreferences.wallpaperDim)
                }
                Column {
                    visible: !panel.expanded
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(64, parent.height * (surface.isPhone ? 0.14 : 0.18))
                    spacing: 12
                    BrandMark {
                        id: homeBrand
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 96
                        height: 96
                        reducedMotion: shellPreferences.reducedMotion
                    }
                    Connections {
                        target: root
                        function onReplayBrand() {
                            homeBrand.replay();
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, shellPreferences.use24Hour ? "hh:mm" : "h:mm AP")
                        color: "#f0f5ff"
                        font {
                            pixelSize: surface.isPhone ? 58 : 72
                            weight: Font.Light
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                        color: "#a9e8d5"
                        font.pixelSize: 18
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "TESSARCHY"
                        color: root.accentColor
                        font {
                            pixelSize: 12
                            bold: true
                            letterSpacing: 5
                        }
                    }
                    TouchButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: surface.modeLabel + "  ·  Change"
                        implicitWidth: Math.min(surface.modelData.width - 32, 260)
                        accentColor: root.accentColor
                        background: Rectangle {
                            radius: 24
                            color: "#70101b30"
                            border.color: Qt.alpha(root.accentColor, 0.25)
                        }
                        onClicked: panel.showPage("settings")
                    }
                }
            }
        }
    }
}
