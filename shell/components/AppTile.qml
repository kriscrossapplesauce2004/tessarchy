import QtQuick
import QtQuick.Layouts

TouchButton {
    id: control
    property string iconSource: ""
    required property string symbol
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 116
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 12
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56
                height: 56
                radius: 18
                rotation: 0
                color: Qt.alpha(control.accentColor, control.selected ? 0.4 : 0.18)
                border.color: Qt.alpha(control.accentColor, 0.3)
                Image {
                    anchors.centerIn: parent
                    rotation: 0
                    source: control.iconSource || "../icons/" + control.symbol + ".svg"
                    sourceSize.width: 28
                    sourceSize.height: 28
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: control.text
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: "#f0f5ff"
                font.pixelSize: 16
            }
        }
    }
}
