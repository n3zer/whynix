import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../"
import "../../"

// Active niri keybinds (parsed by KeybindService from binds.user.kdl).
// Rows are editable: click the combo pill to record a new combo, ✕ to unbind.
// Changes are written by patch_niri_binds.py to the live + repo copies of
// binds.user.kdl; niri reloads on its own through the include watcher.
Item {
    id: root

    property var _binds: KeybindService._niriBinds

    Component.onCompleted: KeybindService.loadNiriBinds()

    function _applyOps(ops) {
        console.log("Keybinds: applying", JSON.stringify(ops))
        KeybindService.applyNiriOps(ops)
        // niri normally reloads via the include watcher; force it anyway so a
        // write always takes effect immediately.
        _niriReloadProc.command = ["niri", "msg", "action", "load-config-file"]
        _niriReloadProc.running = false
        _niriReloadProc.running = true
        _reloadTimer.restart()
    }

    // Shown from BindRow after a new combo is captured — confirm before applying.
    function _confirmRebind(combo, mods, key) {
        var b = KeybindService._niriById[combo]
        var oldLabel = b ? (b.comment || b.label || b.action || "") : ""
        var newCombo = (mods ? mods + " + " : "") + key
        Popups.showConfirm(
            "Rebind keybind",
            "Change <b>" + combo + "</b> to <b>" + newCombo + "</b>" +
            (oldLabel ? "<br>· <i>" + oldLabel + "</i>" : "") + "?",
            "Apply",
            "custom",
            "",
            function() {
                root._applyOps([{ combo: combo, mods: mods, key: key }])
            }
        )
    }

    property Process _niriReloadProc: Process { command: []; running: false }

    // Give niri a moment before re-listing the binds.
    property Timer _reloadTimer: Timer {
        interval: 600
        repeat:   false
        onTriggered: KeybindService.loadNiriBinds()
    }

    // ── Scrollable list ───────────────────────────────────────────────────────
    Flickable {
        anchors {
            top:         parent.top
            left:        parent.left
            right:       parent.right
            bottom:      parent.bottom
            leftMargin:  12
            rightMargin: 12
            bottomMargin: 12
            topMargin:   6
        }
        contentWidth:   width
        contentHeight:  _col.implicitHeight + 16
        clip:           true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 3; implicitHeight: 40; radius: 1.5
                color: Qt.rgba(1, 1, 1, 0.22)
            }
            background: Item {}
        }

        Column {
            id: _col
            width:   parent.width - 12
            spacing: 2

            // ── Header ──────────────────────────────────────────────────────
            Item {
                width:  parent.width
                height: 20
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    text:           "Active Keybinds (niri / binds.user.kdl)"
                    font.pixelSize: 9
                    font.weight:    Font.Bold
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
                }
            }

            Repeater {
                model: root._binds
                delegate: BindRow {
                    required property var modelData
                    combo: modelData.combo
                    width: _col.width
                    onRebindRequested:  root._applyOps([{ combo: combo, mods: mods, key: key }])
                    onConfirmRequested: root._confirmRebind(combo, mods, key)
                    onUnbindRequested: root._applyOps([{ combo: combo, unbind: true }])
                }
            }

            Item {
                width:  parent.width
                height: 18
                Text {
                    anchors { top: parent.top; topMargin: 10 }
                    width: parent.width
                    text:           "Click a combo pill to rebind, ✕ to unbind. Writes to \u2025/dotfiles/home/config/niri/binds.user.kdl and reloads automatically."
                    font.pixelSize: 9
                    wrapMode:       Text.WordWrap
                    color:          Qt.rgba(1, 1, 1, 0.35)
                }
            }
        }
    }

}
