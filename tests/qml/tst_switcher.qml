import QtQuick
import QtTest
import "../../shell/SwitcherPolicy.js" as Policy

TestCase {
    name: "SwitcherNavigation"
    function test_empty_and_disappearing_windows() {
        compare(Policy.activeIndex([]), -1);
        compare(Policy.advance(-1, 1, 0), -1);
        compare(Policy.activeIndex([{activated: false}]), 0);
        compare(Policy.advance(4, 1, 1), 0);
    }
    function test_active_selection_and_keyboard_wrap() {
        compare(Policy.activeIndex([{activated: false}, {activated: true}]), 1);
        compare(Policy.advance(1, 1, 2), 0);
        compare(Policy.advance(0, -1, 2), 1);
        compare(Policy.advance(0, 1, 2), 1);
    }
}
