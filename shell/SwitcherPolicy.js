.pragma library

function activeIndex(windows) {
    const index = windows.findIndex(window => window.activated);
    return windows.length ? Math.max(0, index) : -1;
}

function advance(index, direction, count) {
    return count ? ((Math.max(0, index) + direction) % count + count) % count : -1;
}
