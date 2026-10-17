import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../LayoutPolicy.js" as Policy

ColumnLayout {
    id: panel
    property color accentColor: "#a9e8d5"

    readonly property var device: UPower.displayDevice
    readonly property bool batteryPresent: !!(device && device.ready && device.isPresent)

    spacing: 6

    Text {
        Layout.fillWidth: true
        color: "#f0f5ff"
        wrapMode: Text.WrapAnywhere
        Accessible.name: text
        text: {
            if (!panel.batteryPresent)
                return UPower.onBattery ? "On battery power" : "No battery · on AC power";
            const percent = Policy.volumePercent(panel.device.percentage) + "%";
            switch (panel.device.state) {
            case UPowerDeviceState.Charging:
                return panel.device.timeToFull > 0 ? "Charging · " + percent + " · " + Policy.duration(panel.device.timeToFull) + " to full" : "Charging · " + percent;
            case UPowerDeviceState.PendingCharge:
                return "Plugged in · " + percent;
            case UPowerDeviceState.FullyCharged:
                return "Fully charged · " + percent;
            case UPowerDeviceState.Discharging:
                return panel.device.timeToEmpty > 0 ? "Battery · " + percent + " · " + Policy.duration(panel.device.timeToEmpty) + " left" : "Battery · " + percent;
            case UPowerDeviceState.Empty:
                return "Battery empty · " + percent;
            default:
                return "Battery · " + percent;
            }
        }
    }
    Text {
        visible: panel.batteryPresent && panel.device.healthSupported
        text: "Battery health · " + Policy.volumePercent(panel.device.healthPercentage) + "%"
        color: "#b7c7cc"
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
    }
    Text {
        text: "POWER MODE"
        color: "#8da7b9"
        font {
            pixelSize: 11
            letterSpacing: 2
        }
    }
    RowLayout {
        Layout.fillWidth: true
        TouchButton {
            text: "Save"
            accentColor: panel.accentColor
            selected: PowerProfiles.profile === PowerProfile.PowerSaver
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Accessible.name: "Power saver mode"
            onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
        }
        TouchButton {
            text: "Balanced"
            accentColor: panel.accentColor
            selected: PowerProfiles.profile === PowerProfile.Balanced
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Accessible.name: "Balanced power mode"
            onClicked: PowerProfiles.profile = PowerProfile.Balanced
        }
        TouchButton {
            text: "Performance"
            accentColor: panel.accentColor
            enabled: PowerProfiles.hasPerformanceProfile
            selected: PowerProfiles.profile === PowerProfile.Performance
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Accessible.name: PowerProfiles.hasPerformanceProfile ? "Performance power mode" : "Performance power mode unavailable"
            onClicked: PowerProfiles.profile = PowerProfile.Performance
        }
    }
}
