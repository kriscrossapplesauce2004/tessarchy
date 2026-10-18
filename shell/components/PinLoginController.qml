import QtQuick

QtObject {
    id: controller
    required property var backend
    required property int inactiveState
    property string user: "tess"
    property bool busy: false
    property string message: ""
    property string pendingPin: ""
    property bool attemptActive: false
    property bool answeredSecret: false
    signal restartRequested
    readonly property bool available: !!backend && backend.available
    readonly property bool ready: available && backend.state === inactiveState && !busy

    function begin(pin) {
        if (!ready || !/^[0-9]{4}$/.test(pin) || !/^[a-z_][a-z0-9_-]*[$]?$/.test(user)) return;
        pendingPin = pin;
        answeredSecret = false;
        attemptActive = true;
        busy = true;
        message = "";
        deadline.restart();
        backend.createSession(user);
    }
    function fail(text, cancel = true) {
        pendingPin = "";
        attemptActive = false;
        answeredSecret = false;
        deadline.stop();
        message = text;
        busy = true;
        if (cancel && available && backend.state !== inactiveState) backend.cancelSession();
        retryDelay.restart();
    }
    property Timer deadline: Timer {
        interval: 30000
        onTriggered: controller.fail("Sign-in timed out. Try again.")
    }
    property Timer retryDelay: Timer {
        interval: 3000
        onTriggered: {
            if (controller.available && controller.backend.state !== controller.inactiveState) controller.restartRequested();
            else controller.busy = false;
        }
    }
    property Connections replies: Connections {
        target: controller.backend
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!controller.attemptActive || !responseRequired) return;
            if (echoResponse || controller.answeredSecret || !/^[0-9]{4}$/.test(controller.pendingPin)) {
                controller.fail("This account needs a different sign-in method.");
                return;
            }
            const pin = controller.pendingPin;
            controller.pendingPin = "";
            controller.answeredSecret = true;
            controller.backend.respond(pin);
        }
        function onAuthFailure(message) { controller.fail("Passcode not recognized. Try again.", false); }
        function onError(error) {
            if (controller.attemptActive || controller.message.length === 0) controller.fail("Sign-in unavailable. Try again.", false);
        }
        function onReadyToLaunch() {
            if (!controller.attemptActive || !controller.answeredSecret || controller.pendingPin.length !== 0) {
                controller.fail("This account needs passcode authentication configured.");
                return;
            }
            controller.deadline.stop();
            controller.attemptActive = false;
            controller.backend.launch(["/usr/bin/start-tessarchy"]);
        }
    }
    Component.onDestruction: { pendingPin = ""; }
}
