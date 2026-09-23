pragma Singleton
import QtQuick
import "../"

QtObject {
    // ── Per-popup open state ───────────────────────────────────────────────────
    property bool audioOpen:         false
    property bool networkOpen:       false
    property bool batteryOpen:       false
    property bool notificationsOpen: false
    property bool nixMenuOpen:       false
    property bool dashboardOpen:     false
    property bool wallpaperOpen:     false
    property bool notificationToastOpen:    false
    property bool quickOpen: false
    property bool clipboardOpen:     false

    // ── Dashboard — per-page state ───────────────────────────────────────────
    property int    dashboardPageWidth: 900
    property string dashboardPage:      "home"
    
    // ── Audio popup — per-page state ─────────────────────────────────────────
    property string audioPage: "output"

    // ── Network popup — per-page content (string key) ─────────────────────────
    property string networkPage: "wifi"

    // ── Per-popup trigger hover state ─────────────────────────────────────────
    property bool nixMenuTriggerHovered: false
    property bool audioTriggerHovered:         false
    property bool networkTriggerHovered:       false
    property bool batteryTriggerHovered:       false
    property bool notificationsTriggerHovered: false
    property bool wallpaperTriggerHovered:     false
    property bool quickTriggerHovered: false

    // ── Universal popup behavior settings ─────────────────────────────────────
    property int  slideDuration:   Theme.animDuration
    property int  hoverCloseDelay: Theme.animDuration + 200   // delay after hover leaves before closing

    // ── Confirm dialog ────────────────────────────────────────────────────────
    property bool   confirmOpen:    false
    property string confirmTitle:   ""
    property string confirmMessage: ""
    property string confirmLabel:   "Confirm"
    property string confirmAction:  ""
    property string confirmGfxMode: ""
    property bool   confirmRunning: false
    property var    confirmCallback: null   // invoked on "custom" confirm actions

    function showConfirm(title, message, label, action, gfxMode, callback) {
        confirmTitle    = title
        confirmMessage  = message
        confirmLabel    = label
        confirmAction   = action
        confirmGfxMode  = gfxMode ?? ""
        confirmCallback = callback ?? null
        confirmOpen     = true
    }

    function cancelConfirm() {
        confirmOpen     = false
        confirmAction   = ""
        confirmGfxMode  = ""
        confirmCallback = null
    }

    // ── Global state ──────────────────────────────────────────────────────────
    readonly property bool anyOpen: audioOpen || networkOpen || batteryOpen
                                    || notificationsOpen || nixMenuOpen
                                    || dashboardOpen || wallpaperOpen || quickOpen
                                    || clipboardOpen

    function closeAll() {
        audioOpen         = false
        networkOpen       = false
        batteryOpen       = false
        notificationsOpen = false
        nixMenuOpen      = false
        dashboardOpen     = false
        wallpaperOpen     = false
        quickOpen         = false
        clipboardOpen     = false
    }
}
