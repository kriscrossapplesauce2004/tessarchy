import QtQuick
import QtTest
import "../../shell/components"

TestCase {
    name: "MediaControls"
    Component { id: panelFactory; MediaPanel { width: 368 } }
    Component {
        id: playerFactory
        QtObject {
            property bool canControl: true
            property bool canGoPrevious: false
            property bool canGoNext: true
            property bool canTogglePlaying: true
            property bool canSeek: false
            property bool isPlaying: false
            property string trackTitle: "<b>Track</b>"
            property string trackArtist: "Artist"
            property string identity: "Test player"
            property int previousCalls: 0
            property int nextCalls: 0
            property int toggleCalls: 0
            property real seekOffset: 0
            function previous() { previousCalls++; }
            function next() { nextCalls++; }
            function togglePlaying() { toggleCalls++; }
            function seek(offset) { seekOffset += offset; }
        }
    }
    function test_capability_changes_and_disappearing_player() {
        const player = createTemporaryObject(playerFactory, this);
        const panel = createTemporaryObject(panelFactory, this, {player: player});
        panel.activate("previous");
        compare(player.previousCalls, 0);
        panel.activate("next");
        compare(player.nextCalls, 1);
        panel.activate("toggle");
        compare(player.toggleCalls, 1);
        panel.activate("forward");
        compare(player.seekOffset, 0);
        player.canSeek = true;
        panel.activate("forward");
        compare(player.seekOffset, 10);
        panel.activate("back");
        compare(player.seekOffset, 0);
        player.canControl = false;
        panel.activate("next");
        compare(player.nextCalls, 1);
        panel.player = null;
        panel.activate("toggle");
        compare(player.toggleCalls, 1);
    }
}
