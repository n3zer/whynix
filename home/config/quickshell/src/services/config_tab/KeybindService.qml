pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"

// niri source of truth: binds.kdl includes a writable user file
// (~/.local/state/niri/binds.user.kdl) seeded by home.activation from
// ~/dotfiles/home/config/niri/binds.user.kdl. niri reloads it automatically
// through the include watcher.
QtObject {
    id: root

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string _niriLivePath: root.homeDir + "/.local/state/niri/binds.user.kdl"
    readonly property string _niriRepoPath: (Quickshell.env("DOTFILES_DIR") || (root.homeDir + "/dotfiles")) + "/home/config/niri/binds.user.kdl"

    // ── niri binds cache ──────────────────────────────────────────────────────
    // Parsed from the live niri config by list_niri_binds.py.
    property var _niriBinds: []

    property var _niriLoadProc: Process {
        command: ["python3",
                  Quickshell.shellDir + "/src/scripts/list_niri_binds.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(text.trim()) || []
                    root._niriBinds = arr
                    var snap = {}
                    for (var i = 0; i < arr.length; i++) {
                        var id = arr[i].combo
                        if (id) snap[id] = arr[i]
                    }
                    root._niriOrig = snap
                    root._rebuildById()
                } catch (e) {}
            }
        }
    }

    // Stable lookups keyed by the live combo token ("Mod+Shift+T").
    // Rebuilt after every load — must not be a one-shot computation.
    property var _niriById: ({})

    function _rebuildById() {
        var m = {}
        var a = root._niriBinds
        for (var i = 0; i < a.length; i++) {
            var b = a[i]
            if (b.combo) m[b.combo] = b
        }
        root._niriById = m
    }

    // Snapshot of the original combos — lets ops restore/rebind knowing the
    // original token (which may carry flags like allow-when-locked).
    property var _niriOrig: ({})

    function loadNiriBinds() {
        _niriLoadProc.running = false
        _niriLoadProc.running = true
    }

    // Apply a set of ops atomically via patch_niri_binds.py (writes live +
    // repo copy, niri reloads on its own). Op schema:
    //   {"combo":"Mod+T","mods":"SUPER","key":"L"}  → rebind to new combo
    //   {"combo":"Mod+T","unbind":true}             → remove binding
    //   {"combo":"Mod+T","restoreCombo":"Mod+U"}    → restore original combo
    property var _applyNiriProc: Process { command: []; running: false }

    function applyNiriOps(ops) {
        var json = JSON.stringify(ops)
        _applyNiriProc.command = ["python3",
            Quickshell.shellDir + "/src/scripts/patch_niri_binds.py",
            "--live",  root._niriLivePath,
            "--repo",  root._niriRepoPath,
            json]
        _applyNiriProc.running = false
        _applyNiriProc.running = true
    }

    // Returns a short description of the conflicting niri bind, or "".
    // Own shell binds (arg contains "qs ipc"/"quickshell ipc") are filtered out.
    function wouldConflictNiri(mods, key) {
        var norm = function(s) {
            return (s || "").toUpperCase().replace(/\s*\+\s*/g, "+").trim()
        }
        var target = norm(mods) + "+" + norm(key)
        for (var i = 0; i < root._niriBinds.length; i++) {
            var b = root._niriBinds[i]
            if (b.args && (b.args.indexOf("quickshell ipc") >= 0 ||
                           b.args.indexOf("qs ipc") >= 0)) continue  // our own shell binds
            var combo = norm(b.mods) + "+" + norm(b.key)
            if (combo === target) {
                var desc = b.action || ""
                if (b.comment) desc += " — " + b.comment.substring(0, 36)
                return desc || "niri bind"
            }
        }
        return ""
    }

    Component.onCompleted: loadNiriBinds()
}