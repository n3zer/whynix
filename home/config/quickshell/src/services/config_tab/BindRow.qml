import QtQuick
import "../../"

// One editable niri keybind row (used by KeybindsPage).
// Click the combo pill to record a new combo, ✕ to unbind.
// Emits rebindRequested / unbindRequested upward; the page runs the ops.
Item {
    id: br

    required property string combo

    signal rebindRequested(string combo, string mods, string key)
    signal confirmRequested(string combo, string mods, string key)
    signal unbindRequested(string combo)

    readonly property var _b: KeybindService._niriById[br.combo] || null

    readonly property string _label: {
        var b = br._b
        if (!b) return ""
        if (b.comment) return b.comment
        var t = b.action || ""
        if (b.args) t += " " + b.args
        return t
    }
    readonly property string _comboText: {
        var b = br._b
        if (!b || b.key === "") return "Unbound"
        return b.mods ? b.mods + " + " + b.key : b.key
    }

    property bool isCapturing: false
    property int    _heldMods: 0
    property int    _pressedMods: 0
    property string _liveMods:    ""
    property string capturedMods: ""
    property string capturedKey:  ""
    readonly property string _conflictLabel: {
        if (!br.capturedKey) return ""
        return KeybindService.wouldConflictNiri(br.capturedMods, br.capturedKey)
    }
    readonly property bool _hasConflict: _conflictLabel !== ""

function _commitCapture() {
            if (br.capturedKey === "") return
            console.log("Keybinds: capture", br.combo, "→", br.capturedMods, "+", br.capturedKey)
            // Ask the page to show a confirmation modal before applying.
            br.confirmRequested(br.combo, br.capturedMods, br.capturedKey)
            br.isCapturing  = false
            br.capturedMods = ""
            br.capturedKey  = ""
            br._liveMods    = ""
        }

    // Returns the internal modifier bit for a key (0 if not a modifier).
    function _modFromKey(k) {
        if (k === Qt.Key_Shift || k === Qt.Key_Shift_L || k === Qt.Key_Shift_R) return 1
        if (k === Qt.Key_Control || k === Qt.Key_Control_L || k === Qt.Key_Control_R) return 4
        if (k === Qt.Key_Alt || k === Qt.Key_Alt_L || k === Qt.Key_Alt_R) return 8
        if (k === Qt.Key_Meta || k === Qt.Key_Meta_L || k === Qt.Key_Meta_R ||
            k === Qt.Key_Super_L || k === Qt.Key_Super_R ||
            k === Qt.Key_Hyper_L || k === Qt.Key_Hyper_R) return 64
        if (k === Qt.Key_AltGr) return 8
        return 0
    }

    height: isCapturing ? 58 : 36
    clip:   true
    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    // ── Background ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: br.isCapturing
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
            : _rH.hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        border.color: br.isCapturing
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.20)
            : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // ── Invisible focus target for key capture ────────────────────────────
    Item {
        id: _captureArea
        anchors.fill: parent
        focus:   br.isCapturing
        visible: br.isCapturing

        Keys.onPressed: function(event) {
            event.accepted = true
            var mf = br._modFromKey(event.key)
            if (mf !== 0) {
                // Track modifiers ourselves — event.modifiers is unreliable
                // on Wayland (missing Super/meta bits).
                br._heldMods |= mf
                br._liveMods = _mods(br._heldMods)
                return
            }
            br._pressedMods = br._heldMods
            br._liveMods    = _mods(br._heldMods)
        }

        Keys.onReleased: function(event) {
            event.accepted = true
            var mf = br._modFromKey(event.key)
            if (mf !== 0) {
                br._heldMods &= ~mf
                if (!br.capturedKey) br._liveMods = _mods(br._heldMods)
                return
            }
            // Bare Escape = cancel without saving
            if (event.key === Qt.Key_Escape && br._heldMods === 0) {
                br.isCapturing = false
                return
            }
            var k = _keyName(event.key)
            if (k !== "") {
                var m = _mods(br._pressedMods)
                br.capturedMods = m
                br.capturedKey  = k
                // Auto-accept unless it conflicts with another niri bind
                if (KeybindService.wouldConflictNiri(m, k) === "") {
                    _commitCapture()
                    br.isCapturing = false
                }
                // else: stay open, show conflict warning
            }
        }
    }

    // ── Normal display ────────────────────────────────────────────────────
    Item {
        anchors { top: parent.top; left: parent.left; right: parent.right
                  leftMargin: 10; rightMargin: 8 }
        height: 36
        visible: !br.isCapturing

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text:           br._label
            font.pixelSize: 12
            elide:          Text.ElideRight
            width:          parent.width - 200
            color:          Qt.rgba(1, 1, 1, 0.68)
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6

            // Unbind
            Rectangle {
                width: 22; height: 22; radius: 6
                color: _clrH.hovered ? Qt.rgba(1,1,1,0.09) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Text { anchors.centerIn: parent; text: "󰩺"; font.pixelSize: 11
                    color: _clrH.hovered ? "#ff4444" : Qt.rgba(1,1,1,0.28) }
                HoverHandler { id: _clrH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: br.unbindRequested(br.combo)
                }
            }

            // Binding pill — click to rebind
            Rectangle {
                height: 24; radius: 6
                width:  _pillT.implicitWidth + 18

                color: _pillH.hovered
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.16)
                    : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08)
                border.color: _pillH.hovered
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.40)
                    : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.24)
                border.width: 1

                Behavior on color        { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    id: _pillT
                    anchors.centerIn: parent
                    text:           br._comboText
                    font.pixelSize: 10; font.family: "JetBrains Mono"
                    color: Theme.active
                }
                HoverHandler { id: _pillH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        br._heldMods    = 0
                        br._pressedMods = 0
                        br._liveMods    = ""
                        br.capturedMods = ""
                        br.capturedKey  = ""
                        br.isCapturing  = true
                        Qt.callLater(function() { _captureArea.forceActiveFocus() })
                    }
                }
            }
        }
    }

    // ── Capture display ───────────────────────────────────────────────────
    Item {
        anchors { top: parent.top; left: parent.left; right: parent.right
                  leftMargin: 10; rightMargin: 8 }
        height: 38
        visible: br.isCapturing

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text:           br._label
            font.pixelSize: 12
            elide:          Text.ElideRight
            width:          parent.width - 210
            color:          Qt.rgba(1, 1, 1, 0.68)
        }

        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            height: 24; radius: 6
            width:  Math.max(110, _capT.implicitWidth + 18)
            color:  Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.08)
            border.color: br._hasConflict
                ? Qt.rgba(248/255, 113/255, 113/255, 0.55)
                : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b,
                          br.capturedKey !== "" ? 0.40 : 0.18)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Text {
                id: _capT
                anchors.centerIn: parent
                font.pixelSize: 10; font.family: "JetBrains Mono"
                color: br._hasConflict
                    ? "#f87171"
                    : br.capturedKey !== ""
                        ? Theme.active
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.45)
                text: {
                    if (br.capturedKey !== "")
                        return (br.capturedMods ? br.capturedMods + " + " : "") + br.capturedKey
                    if (br._liveMods !== "")
                        return br._liveMods + " + ?"
                    return "Press a key..."
                }
            }
        }
    }

    // ── Conflict warning (fades in when there's a conflict) ───────────────
    Item {
        anchors { left: parent.left; right: parent.right; leftMargin: 12 }
        y: 38
        height: 18
        opacity: (br.capturedKey !== "" && br._hasConflict) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text:           "⚠  Conflicts with: " + br._conflictLabel
            font.pixelSize: 10
            color:          "#f87171"
        }
    }

    HoverHandler { id: _rH; enabled: !br.isCapturing }

    // ── Key helpers ───────────────────────────────────────────────────────
    // Internal modifier bits (see _modFromKey): SUPER=64, SHIFT=1, CTRL=4, ALT=8.
    function _mods(flags) {
        var p = []
        if (flags & 64) p.push("SUPER")
        if (flags & 1)  p.push("SHIFT")
        if (flags & 4)  p.push("CTRL")
        if (flags & 8)  p.push("ALT")
        return p.join(" + ")
    }

    function _keyName(k) {
        if (br._modFromKey(k) !== 0) return ""
        if (k >= Qt.Key_A && k <= Qt.Key_Z)    return String.fromCharCode(k)
        if (k >= Qt.Key_0 && k <= Qt.Key_9)    return String.fromCharCode(k)
        if (k >= Qt.Key_F1 && k <= Qt.Key_F35) return "F" + (k - Qt.Key_F1 + 1)
        var m = {}
        m[Qt.Key_Escape]       = "Escape"
        m[Qt.Key_Return]       = "Return"
        m[Qt.Key_Enter]        = "KP_Enter"
        m[Qt.Key_Tab]          = "Tab"
        m[Qt.Key_Backspace]    = "BackSpace"
        m[Qt.Key_Delete]       = "Delete"
        m[Qt.Key_Insert]       = "Insert"
        m[Qt.Key_Home]         = "Home"
        m[Qt.Key_End]          = "End"
        m[Qt.Key_PageUp]       = "Page_Up"
        m[Qt.Key_PageDown]     = "Page_Down"
        m[Qt.Key_Left]         = "Left"
        m[Qt.Key_Right]        = "Right"
        m[Qt.Key_Up]           = "Up"
        m[Qt.Key_Down]         = "Down"
        m[Qt.Key_Space]        = "Space"
        m[Qt.Key_Print]        = "Print"
        m[Qt.Key_Pause]        = "Pause"
        m[Qt.Key_Minus]        = "minus"
        m[Qt.Key_Equal]        = "equal"
        m[Qt.Key_BracketLeft]  = "bracketleft"
        m[Qt.Key_BracketRight] = "bracketright"
        m[Qt.Key_Backslash]    = "backslash"
        m[Qt.Key_Semicolon]    = "semicolon"
        m[Qt.Key_Apostrophe]   = "apostrophe"
        m[Qt.Key_Comma]        = "comma"
        m[Qt.Key_Period]       = "period"
        m[Qt.Key_Slash]        = "slash"
        m[Qt.Key_QuoteLeft]    = "grave"
        return m[k] || ""
    }
}