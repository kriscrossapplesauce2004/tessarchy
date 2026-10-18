import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Bluetooth
import "../../shell/components"

ShellRoot {
    id: root
    function verify(value) { if (!value) throw new Error("Assertion failed"); }
    function compare(a, b) { if (a !== b) throw new Error(String(a) + " != " + String(b)); }
    function createTemporaryObject(factory, parent, properties) { return factory.createObject(testWindow.contentItem, properties || {}); }
    Window { id: testWindow; visible: true; width: 400; height: 800 }
    Timer {
        interval: 50; running: true
        onTriggered: {
            try {
                root.test_missing_adapter_and_discovery_lifecycle();
                root.test_device_actions_guard_stale_busy_blocked_unpaired();
                console.log("BLUETOOTH_TEST_PASS");
            } catch (error) { console.error("BLUETOOTH_TEST_FAIL: " + error + " " + error.stack); }
            Qt.quit();
        }
    }
    Component { id: panelFactory; BluetoothPanel { width: 368; adapter: null } }
    Component {
        id: adapterFactory
        QtObject {
            property bool enabled: true
            property bool discovering: false
            property int state: BluetoothAdapterState.Enabled
            property var devices: ({values: []})
        }
    }
    Component {
        id: deviceFactory
        QtObject {
            property string name: "<b>Headphones</b>"
            property string deviceName: ""
            property string address: "00:00:00:00:00:00"
            property bool connected: false
            property bool paired: true
            property bool bonded: true
            property bool blocked: false
            property bool batteryAvailable: true
            property real battery: 0.42
            property int state: BluetoothDeviceState.Disconnected
            property int connects: 0
            property int disconnects: 0
            function connect() { connects++; }
            function disconnect() { disconnects++; }
        }
    }
    function test_missing_adapter_and_discovery_lifecycle() {
        const panel = createTemporaryObject(panelFactory, this);
        verify(!panel.bluetoothAvailable);
        const a = createTemporaryObject(adapterFactory, this);
        const b = createTemporaryObject(adapterFactory, this);
        panel.visible = false;
        panel.adapter = a;
        verify(!a.discovering);
        panel.visible = true;
        verify(a.discovering);
        panel.adapter = b;
        verify(!a.discovering);
        verify(b.discovering);
        b.enabled = false;
        verify(!b.discovering);
        b.enabled = true;
        verify(b.discovering);
        panel.visible = false;
        verify(!b.discovering);
        b.discovering = true;
        panel.visible = true;
        panel.visible = false;
        verify(b.discovering);
        panel.adapter = null;
        verify(!panel.bluetoothAvailable);
    }
    function test_device_actions_guard_stale_busy_blocked_unpaired() {
        const adapter = createTemporaryObject(adapterFactory, this);
        const device = createTemporaryObject(deviceFactory, this);
        const panel = createTemporaryObject(panelFactory, this, {adapter: adapter});
        panel.activate(device);
        compare(device.connects, 0);
        adapter.devices = {values: [device]};
        panel.activate(device);
        compare(device.connects, 1);
        device.state = BluetoothDeviceState.Connecting;
        panel.activate(device);
        compare(device.connects, 1);
        device.state = BluetoothDeviceState.Disconnected;
        device.blocked = true;
        panel.activate(device);
        compare(device.connects, 1);
        device.blocked = false;
        device.paired = false;
        device.bonded = false;
        panel.activate(device);
        compare(device.connects, 1);
        device.connected = true;
        panel.activate(device);
        compare(device.disconnects, 1);
        adapter.enabled = false;
        panel.activate(device);
        compare(device.disconnects, 1);
        verify(panel.labelFor(device).startsWith("<b>Headphones</b>"));
    }
}
