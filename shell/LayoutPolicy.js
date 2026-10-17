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

// Desktop keeps numbered workspaces one tap away; landscape tablets only once
// the status bar has room beside the clock, tray and battery indicators.
function showWorkspaces(mode, width) {
    if (mode === "desktop") return true;
    return mode === "tablet" && width >= 900;
}

// Workspaces 1-5 always have a slot. Higher numbered workspaces extend the
// strip. Named workspaces have negative ids and are not numbered slots.
function workspaceSlots(ids) {
    let slots = 5;
    for (let i = 0; i < ids.length; i++) {
        if (ids[i] > slots) slots = ids[i];
    }
    return slots;
}

// Notification pop-ups dock below the status bar. Phone cards span the panel;
// larger screens right-align a bounded column.
function notificationPlacement(mode, width) {
    if (mode === "phone") return { fullWidth: true, maxWidth: Math.max(280, width - 16), topOffset: 56 };
    if (mode === "tablet") return { fullWidth: false, maxWidth: Math.min(360, width - 32), topOffset: 60 };
    return { fullWidth: false, maxWidth: Math.min(420, width - 32), topOffset: 60 };
}

// Seconds a pop-up stays on screen. Low urgency leaves sooner, normal after a
// comfortable read, and critical notifications stay until dismissed.
function notificationTimeout(urgency) {
    if (urgency === 2) return 0;
    if (urgency === 0) return 4;
    return 8;
}

// Media: prefer the player that is actually playing; otherwise the first
// connected player; -1 when no player is connected.
function preferredPlayerIndex(playing) {
    for (let i = 0; i < playing.length; i++) {
        if (playing[i]) return i;
    }
    return playing.length > 0 ? 0 : -1;
}

function mediaSummary(title, artist) {
    const track = title && title.length > 0 ? title : "Unknown track";
    const by = artist && artist.length > 0 ? artist : "Unknown artist";
    return track + " — " + by;
}

function nodeLabel(description, nickname, name) {
    for (const candidate of [description, nickname, name]) {
        if (candidate !== undefined && candidate !== null && String(candidate).trim() !== "") return String(candidate).trim();
    }
    return "Unknown device";
}

function streamLabel(appName, mediaName, nodeName) {
    for (const candidate of [appName, mediaName, nodeName]) {
        if (candidate !== undefined && candidate !== null && String(candidate).trim() !== "") return String(candidate).trim();
    }
    return "Unknown app";
}

function playbackStream(mediaClass) {
    if (mediaClass === undefined || mediaClass === null || String(mediaClass).trim() === "") return true;
    return String(mediaClass).indexOf("Output") >= 0;
}

function volumePercent(value) {
    return Math.round(Math.max(0, Math.min(1, Number(value) || 0)) * 100);
}

function duration(seconds) {
    const total = Math.floor(Number(seconds) || 0);
    if (!isFinite(total) || total <= 0) return "";
    if (total < 60) return "less than a minute";
    let minutes = Math.round(total / 60);
    const hours = Math.floor(minutes / 60);
    minutes = minutes % 60;
    if (hours > 0) return hours + "h " + String(minutes).padStart(2, "0") + "m";
    return minutes + "m";
}

// Hyprland monitor transforms: 0/1/2/3 are normal/90/180/270 degrees.
function nextTransform(current) {
    const value = Number.isInteger(current) ? current : 0;
    return ((value + 1) % 4 + 4) % 4;
}
