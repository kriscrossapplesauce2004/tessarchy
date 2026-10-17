.pragma library

function automaticMode(width, height) {
    if (Math.min(width, height) < 600) return "phone";
    if (width >= 1100 && height >= 650) return "desktop";
    return "tablet";
}

function effectiveMode(choice, width, height) {
    if (["phone", "tablet", "desktop"].indexOf(choice) >= 0) return choice;
    return automaticMode(width, height);
}

function title(mode) {
    return mode.charAt(0).toUpperCase() + mode.slice(1);
}

function columns(mode, width) {
    const preferred = mode === "desktop" ? 4 : mode === "tablet" ? 3 : 2;
    return Math.max(1, Math.min(preferred, Math.floor(width / 140)));
}

function panelWidth(mode, width) {
    return mode === "phone" ? width : Math.min(Math.max(0, width - 24), mode === "desktop" ? 760 : 720);
}

// Wi-Fi signal strength is 0.0..1.0 from NetworkManager; display as percent.
function signalPercent(strength) {
    return Math.round(Math.max(0, Math.min(1, Number(strength) || 0)) * 100);
}

// What tapping a network row does: connected ones disconnect; saved profiles
// and open networks connect; anything else needs a password profile first.
function wifiAction(connected, known, openSecurity) {
    if (connected) return "disconnect";
    if (known || openSecurity) return "connect";
    return "none";
}
