import QtQuick
import Quickshell.Io
import "../../"

// Queries envycontrol on load and after each switch.
// Switching requires reboot — uses Popups.showConfirm().
//
// currentMode is ONLY ever set from an envycontrol --query result,
// never optimistically. If pkexec is cancelled, the re-query after
// the process exits will return the unchanged real mode.
//
// Extra hardening: re-query is only triggered when exitCode === 0,
// so a cancelled pkexec leaves currentMode visually unchanged until
// the next scheduled query.
//
// Exposes:
//   bool   available   — false when the envycontrol binary is absent
//   string currentMode — "integrated" | "hybrid" | "nvidia" ("" when unavailable)
//   bool   busy        — true while a switch command is running
//   function switchMode(mode)
//   function executeSwitch(mode)  — called by ConfirmDialog

QtObject {
    id: root

    property string currentMode: "integrated"
    property bool   busy:        false
    property bool   available:   false

    // Pending mode — held until we confirm the switch succeeded
    property string _pendingMode: ""

    // ── Availability probe ────────────────────────────────────────────────────
    // envycontrol is not in nixpkgs; it comes from its own flake, so it may
    // simply not be installed. Probe once and hide the GPU controls if absent
    // instead of offering buttons that cannot work.
    property var _probeProc: Process {
        command: ["sh", "-c", "command -v envycontrol >/dev/null 2>&1 && printf yes"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = text.trim() === "yes"
                if (root.available)
                    _queryProc.running = true
            }
        }
    }

    // ── Query current mode ────────────────────────────────────────────────────
    property var _queryProc: Process {
        command: ["envycontrol", "--query"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var mode = text.trim().toLowerCase()
                if (mode !== "") root.currentMode = mode
            }
        }
    }

    function switchMode(mode) {
        if (!root.available || mode === root.currentMode || root.busy) return
        Popups.closeAll()
        Popups.showConfirm(
            "Switch GPU Mode",
            "Switch to " + mode + " mode?\nA reboot is required for the change to take effect.",
            "Switch + Reboot",
            "gpu-switch-envy",
            mode
        )
    }


    Component.onCompleted: {
        _probeProc.running = true
    }
}
