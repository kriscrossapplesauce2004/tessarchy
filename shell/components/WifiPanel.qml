import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../LayoutPolicy.js" as Policy

ColumnLayout {
    id: panel
    required property var device
    property color accentColor: "#a9e8d5"

    readonly property bool wifiAvailable: panel.device !== null
    readonly property bool wifiOn: panel.wifiAvailable && Networking.wifiEnabled
    readonly property bool wifiHardwareOn: panel.wifiAvailable && Networking.wifiHardwareEnabled
    readonly property var networks: {
        if (!panel.device || !panel.device.networks)
            return [];
        const list = panel.device.networks.values.slice();
        list.sort(function (a, b) {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        return list;
    }
    readonly property bool anyLocked: {
        for (let i = 0; i < panel.networks.length; i++) {
            const network = panel.networks[i];
            if (!network.known && !network.connected && network.security !== WifiSecurityType.Open)
                return true;
        }
        return false;
    }

    spacing: 8

    Component.onCompleted: {
        if (panel.device)
            panel.device.scannerEnabled = true;
    }
    onVisibleChanged: {
        if (panel.device)
            panel.device.scannerEnabled = panel.visible;
    }

    function labelFor(network) {
        const name = String(network.name);
        const signal = Policy.signalPercent(network.signalStrength) + "%";
        if (network.connected)
            return name + " · " + signal + " · connected";
        if (network.state === ConnectionState.Connecting)
            return name + " · " + signal + " · connecting…";
        if (network.known)
            return name + " · " + signal;
        if (network.security === WifiSecurityType.Open)
            return name + " · " + signal + " · open";
        return name + " · " + signal + " · password required";
    }

    function activate(network) {
        const action = Policy.wifiAction(network.connected, network.known,
                                         network.security === WifiSecurityType.Open);
        if (action === "disconnect")
            network.disconnect();
        else if (action === "connect")
            network.connect();
    }

    Text {
        visible: !panel.wifiAvailable
        text: "Wi-Fi · no NetworkManager backend"
        color: "#8da7b9"
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    TouchButton {
        visible: panel.wifiAvailable
        text: !panel.wifiHardwareOn ? "Wi-Fi · hardware blocked"
              : panel.wifiOn ? "Wi-Fi · on" : "Wi-Fi · off"
        selected: panel.wifiOn
        enabled: panel.wifiHardwareOn
        accentColor: panel.accentColor
        Layout.fillWidth: true
        Accessible.name: text
        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }
    Text {
        visible: panel.wifiAvailable && panel.wifiOn && panel.networks.length === 0
        text: "Scanning for networks…"
        color: "#8da7b9"
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    Repeater {
        model: panel.wifiAvailable && panel.wifiOn ? panel.networks : []
        delegate: TouchButton {
            required property var modelData
            readonly property bool actionable: Policy.wifiAction(modelData.connected, modelData.known,
                                                                 modelData.security === WifiSecurityType.Open) !== "none"
            text: panel.labelFor(modelData)
            selected: modelData.connected
            enabled: actionable
            accentColor: panel.accentColor
            Layout.fillWidth: true
            Accessible.name: actionable ? text : text + " · enter the password with nmcli to save a profile"
            onClicked: panel.activate(modelData)
        }
    }
    Text {
        visible: panel.wifiAvailable && panel.wifiOn && panel.anyLocked
        text: "New secured networks need a saved profile first; this shell has no password entry yet."
        color: "#8da7b9"
        font.pixelSize: 12
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
