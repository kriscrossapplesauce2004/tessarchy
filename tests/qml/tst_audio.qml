import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "AudioControls"
    Component { id: panelFactory; AudioControls { width: 368 } }
    Component {
        id: nodeFactory
        QtObject {
            property bool ready: true
            property string name: "test-node"
            property string description: "Test output"
            property string nickname: ""
            property var properties: ({"application.name": "<b>Player</b>"})
            property QtObject audio: QtObject {
                property real volume: 0.5
                property bool muted: false
            }
        }
    }
    SignalSpy { id: outputs; signalName: "outputRequested" }
    function test_backend_loss_stale_nodes_and_bounded_volume() {
        const node = createTemporaryObject(nodeFactory, this);
        const stale = createTemporaryObject(nodeFactory, this);
        const panel = createTemporaryObject(panelFactory, this, {devices: [node], streams: [node]});
        outputs.target = panel;
        outputs.clear();
        panel.selectOutput(node);
        panel.setStreamVolume(node, 1);
        compare(outputs.count, 0);
        compare(node.audio.volume, 0.5);
        panel.backendAvailable = true;
        panel.selectOutput(node);
        compare(outputs.count, 1);
        panel.selectOutput(stale);
        compare(outputs.count, 1);
        panel.setStreamVolume(stale, 0.8);
        compare(stale.audio.volume, 0.5);
        panel.setStreamVolume(node, 2);
        compare(node.audio.volume, 1);
        panel.setStreamVolume(node, NaN);
        compare(node.audio.volume, 1);
        panel.setStreamVolume(node, -2);
        compare(node.audio.volume, 0);
        panel.toggleStreamMuted(node);
        verify(node.audio.muted);
        node.ready = false;
        panel.toggleStreamMuted(node);
        verify(node.audio.muted);
        panel.streams = [];
        node.ready = true;
        panel.setStreamVolume(node, 0.9);
        compare(node.audio.volume, 0);
        outputs.target = null;
    }
}
