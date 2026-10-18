pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Services.Greetd
import "components"

ShellRoot {
    PinLoginController {
        id: login
        backend: Greetd
        inactiveState: GreetdState.Inactive
        onRestartRequested: Qt.quit()
        user: Quickshell.env("TESSARCHY_LOGIN_USER") || "tess"
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Window {
        visible: true
        visibility: Window.FullScreen
        flags: Qt.Window | Qt.FramelessWindowHint
        title: "Tessarchy sign-in"
        color: "#091325"
        onClosing: close => { close.accepted = false; }
        PinScreen {
            anchors.fill: parent
            available: login.available && login.backend.state === GreetdState.Inactive
            busy: login.busy
            message: login.available ? login.message : "Sign-in service unavailable"
            accountName: login.user
            date: clock.date
            onSubmitted: pin => login.begin(pin)
        }
    }
}
