import QtQuick
import QtQuick.Window
import Quickshell
import "../../shell/components"

ShellRoot {
    Window {
        visible: true
        width: 400; height: 800
        AudioPanel { id: panel; width: 368 }
    }
    Timer {
        interval: 200; running: true
        onTriggered: {
            if (!panel.backendAvailable && panel.devices.length === 0 && panel.streams.length === 0)
                console.log("AUDIO_TEST_PASS");
            else console.error("AUDIO_TEST_FAIL: unexpected backend in isolated runtime");
            Qt.quit();
        }
    }
}
