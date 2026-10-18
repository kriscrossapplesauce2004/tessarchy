pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: screen
    property bool busy: false
    property bool available: false
    property string message: ""
    property date date: new Date()
    property bool use24Hour: false
    property string accountName: "Tessarchy"
    property string digits: ""
    readonly property bool compact: height < 700
    readonly property int keySize: Math.max(48, Math.min(compact ? 62 : 80, Math.floor((width - 64) / 3)))
    signal submitted(string pin)
    focus: true

    function appendDigit(digit) {
        if (!available || busy || digits.length >= 4 || !/^[0-9]$/.test(digit)) return;
        digits += digit;
        if (digits.length === 4) submitDelay.restart();
    }
    function eraseDigit() {
        if (busy) return;
        submitDelay.stop();
        digits = digits.slice(0, -1);
    }
    function clear() {
        submitDelay.stop();
        digits = "";
    }
    function submit() {
        if (!available || busy || !/^[0-9]{4}$/.test(digits)) return;
        submitDelay.stop();
        const pin = digits;
        digits = "";
        submitted(pin);
    }
    onBusyChanged: { if (busy) clear(); }
    onAvailableChanged: { if (!available) clear(); }
    Timer { id: submitDelay; interval: 150; onTriggered: screen.submit(); }
    Keys.onPressed: event => {
        if (/^[0-9]$/.test(event.text)) { screen.appendDigit(event.text); event.accepted = true; }
        else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) { screen.eraseDigit(); event.accepted = true; }
        else if (event.key === Qt.Key_Escape) { screen.clear(); event.accepted = true; }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { screen.submit(); event.accepted = true; }
    }

    Image {
        anchors.fill: parent
        source: "../artwork/aurora-fold.png"
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle { anchors.fill: parent; color: "#b3091325" }
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        Item {
            width: screen.width
            implicitHeight: Math.max(screen.height, content.implicitHeight + 40)
            ColumnLayout {
                id: content
                anchors.centerIn: parent
                width: Math.min(360, screen.width - 32)
                spacing: screen.compact ? 12 : 20
                Item {
                    Layout.preferredWidth: content.width
                    Layout.preferredHeight: header.implicitHeight
                    Column {
                        id: header
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: screen.compact ? 4 : 8
                        BrandMark {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: screen.compact ? 42 : 64
                            height: width
                            reducedMotion: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(screen.date, screen.use24Hour ? "h:mm" : "h:mm AP").replace(/ [AP]M$/, "")
                            textFormat: Text.PlainText
                            color: "#f0f5ff"
                            font { pixelSize: screen.compact ? 42 : 64; weight: Font.Light; letterSpacing: -2 }
                        }
                        Text {
                            visible: !screen.compact
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(screen.date, "dddd, MMMM d")
                            textFormat: Text.PlainText
                            color: "#b4cbd6"; font.pixelSize: 14
                        }
                    }
                }
                Text {
                    text: "Enter passcode"
                    textFormat: Text.PlainText
                    color: "#f0f5ff"; font.pixelSize: 17; font.weight: Font.Medium
                    Layout.alignment: Qt.AlignHCenter
                }
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18
                    Accessible.name: "Passcode, " + screen.digits.length + " of 4 digits entered"
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            width: 11; height: 11; radius: 6
                            color: index < screen.digits.length ? "#e2fff6" : "transparent"
                            border { color: "#b4d5d2"; width: 1.5 }
                        }
                    }
                }
                Text {
                    text: screen.busy && screen.message.length === 0 ? "Checking…" : screen.message
                    textFormat: Text.PlainText
                    color: "#b4cbd6"; font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.minimumHeight: 32
                    Accessible.role: Accessible.AlertMessage
                }
                GridLayout {
                    columns: 3
                    columnSpacing: screen.compact ? 16 : 22
                    rowSpacing: screen.compact ? 8 : 12
                    Layout.alignment: Qt.AlignHCenter
                    Repeater {
                        model: [
                            {digit: "1", letters: ""}, {digit: "2", letters: "ABC"}, {digit: "3", letters: "DEF"},
                            {digit: "4", letters: "GHI"}, {digit: "5", letters: "JKL"}, {digit: "6", letters: "MNO"},
                            {digit: "7", letters: "PQRS"}, {digit: "8", letters: "TUV"}, {digit: "9", letters: "WXYZ"},
                            {digit: "", letters: ""}, {digit: "0", letters: ""}, {digit: "delete", letters: ""}
                        ]
                        delegate: Button {
                            id: key
                            required property var modelData
                            readonly property bool blank: modelData.digit === ""
                            readonly property bool erase: modelData.digit === "delete"
                            Layout.preferredWidth: screen.keySize
                            Layout.preferredHeight: screen.keySize
                            Layout.minimumWidth: 48
                            Layout.minimumHeight: 48
                            enabled: !blank && screen.available && !screen.busy && (erase ? screen.digits.length > 0 : screen.digits.length < 4)
                            focusPolicy: blank ? Qt.NoFocus : Qt.TabFocus
                            opacity: blank ? 0 : enabled ? 1 : 0.38
                            Accessible.name: erase ? "Delete digit" : modelData.digit
                            Accessible.ignored: blank
                            contentItem: Item {
                                Column {
                                    visible: !key.erase
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: key.modelData.digit
                                        textFormat: Text.PlainText
                                        color: "#f0f5ff"; font.pixelSize: screen.compact ? 24 : 30
                                    }
                                    Text {
                                        visible: text.length > 0
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: key.modelData.letters
                                        textFormat: Text.PlainText
                                        color: "#b4cbd6"; font.pixelSize: 8; font.letterSpacing: 1.3
                                    }
                                }
                                Image {
                                    visible: key.erase
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    source: "../icons/backspace.svg"
                                }
                            }
                            background: Rectangle {
                                radius: width / 2
                                color: key.down ? "#507dabaa" : "#283a5268"
                                border.color: key.activeFocus ? "#a9e8d5" : "#45688091"
                                border.width: key.activeFocus ? 2 : 1
                            }
                            onClicked: { if (erase) screen.eraseDigit(); else screen.appendDigit(modelData.digit); }
                        }
                    }
                }
                Text {
                    text: screen.accountName
                    textFormat: Text.PlainText
                    color: "#a9e8d5"; font.pixelSize: 10; font.letterSpacing: 2
                    elide: Text.ElideRight
                    Layout.maximumWidth: content.width
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
