pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Quickshell
import "components"

ShellRoot {
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Window {
        visible: true
        visibility: Window.FullScreen
        width: 400; height: 800
        title: "Tessarchy sign-in preview"
        PinScreen {
            anchors.fill: parent
            available: true
            message: "Preview · sign-in disabled"
            date: clock.date
            onSubmitted: pin => { clear(); }
        }
    }
}
