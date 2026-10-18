import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "PhonePasscode"
    Component { id: screenFactory; PinScreen { width: 400; height: 800; available: true } }
    Component {
        id: backendFactory
        QtObject {
            property bool available: true
            property int state: 0
            property int created: 0
            property int canceled: 0
            property int responses: 0
            property int launches: 0
            property string response: ""
            property var command: []
            signal authMessage(string message, bool error, bool responseRequired, bool echoResponse)
            signal authFailure(string message)
            signal error(string error)
            signal readyToLaunch()
            function createSession(user) { created++; state = 1; }
            function cancelSession() { canceled++; state = 0; }
            function respond(value) { responses++; response = value; }
            function launch(value) { launches++; command = value; }
        }
    }
    Component { id: controllerFactory; PinLoginController { backend: null; inactiveState: 0 } }
    SignalSpy { id: submissions; signalName: "submitted" }
    function test_exactly_four_digits_clear_after_submission() {
        const screen = createTemporaryObject(screenFactory, this);
        submissions.target = screen;
        submissions.clear();
        screen.appendDigit("x");
        screen.appendDigit("12");
        compare(screen.digits, "");
        screen.appendDigit("0"); screen.appendDigit("1"); screen.appendDigit("2");
        screen.submit();
        compare(submissions.count, 0);
        screen.appendDigit("3");
        screen.submit();
        compare(submissions.count, 1);
        compare(submissions.signalArguments[0][0], "0123");
        compare(screen.digits, "");
        wait(200);
        compare(submissions.count, 1);
        submissions.target = null;
    }
    function test_delete_busy_and_small_screen_targets() {
        const screen = createTemporaryObject(screenFactory, this, {width: 320, height: 568});
        verify(screen.keySize >= 48);
        screen.appendDigit("1"); screen.appendDigit("2");
        screen.eraseDigit(); compare(screen.digits, "1");
        screen.busy = true;
        compare(screen.digits, "");
        screen.appendDigit("3"); compare(screen.digits, "");
        screen.busy = false;
        screen.appendDigit("4");
        screen.available = false;
        compare(screen.digits, "");
    }
    function test_authentication_requires_secret_challenge_and_success() {
        const backend = createTemporaryObject(backendFactory, this);
        const login = createTemporaryObject(controllerFactory, this, {backend: backend});
        login.begin("123"); compare(backend.created, 0);
        login.begin("0123"); compare(backend.created, 1);
        login.begin("4567"); compare(backend.created, 1);
        backend.authMessage("Password:", false, true, false);
        compare(backend.response, "0123");
        compare(login.pendingPin, "");
        compare(backend.launches, 0);
        backend.readyToLaunch();
        compare(backend.launches, 1);
        compare(backend.command[0], "/usr/bin/start-tessarchy");
    }
    function test_failure_and_unexpected_prompts_never_launch() {
        const backend = createTemporaryObject(backendFactory, this);
        const login = createTemporaryObject(controllerFactory, this, {backend: backend});
        login.begin("0123");
        backend.state = 0;
        backend.authFailure("test failure");
        backend.error("follow-up backend error");
        verify(login.message.startsWith("Passcode not recognized"));
        compare(login.pendingPin, "");
        compare(backend.launches, 0);
        verify(login.busy);
        login.begin("4567"); compare(backend.created, 1);
        const other = createTemporaryObject(controllerFactory, this, {backend: backend});
        other.begin("0123");
        backend.authMessage("Visible prompt", false, true, true);
        compare(backend.responses, 0);
        compare(other.pendingPin, "");
        compare(backend.launches, 0);
    }
    function test_no_challenge_and_extra_secret_fail_closed() {
        const backend = createTemporaryObject(backendFactory, this);
        const login = createTemporaryObject(controllerFactory, this, {backend: backend});
        login.begin("0123");
        backend.readyToLaunch();
        compare(backend.launches, 0);
        compare(login.pendingPin, "");
        const nextBackend = createTemporaryObject(backendFactory, this);
        const next = createTemporaryObject(controllerFactory, this, {backend: nextBackend});
        next.begin("0123");
        nextBackend.authMessage("Password:", false, true, false);
        nextBackend.authMessage("Second secret:", false, true, false);
        compare(nextBackend.responses, 1);
        compare(nextBackend.launches, 0);
        verify(nextBackend.canceled > 0);
    }
}
