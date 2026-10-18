import QtQuick
import QtQuick.Layouts

TouchButton {
    id: control
    required property string symbol
    property bool showLabel: true
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.minimumHeight: 48
    implicitHeight: 48
    padding: 4
    background: Rectangle {
        radius: 16
        color: control.down ? Qt.alpha(control.accentColor, 0.3) : control.selected ? Qt.alpha(control.accentColor, 0.15) : "transparent"
    }
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: 2
            opacity: control.enabled ? 1 : 0.35
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../icons/" + control.symbol + ".svg"
                sourceSize.width: 21
                sourceSize.height: 21
                width: 21
                height: 21
            }
            Text {
                visible: control.showLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: control.text
                color: control.selected ? control.accentColor : "#d0dced"
                font.pixelSize: 10
            }
        }
    }
}
