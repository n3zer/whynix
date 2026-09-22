import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Rectangle {
    id: root

    // ── niri IPC ────────────────────────────────────────────────────────────
    // Polls `niri msg --json workspaces` on a short timer + on window/workspace
    // events via `niri msg event-stream` (fast refresh), and dispatches
    // focus through `niri msg action focus-workspace`.

    property var wsData: []   // parsed array of workspace objects
    property int  focusedId: -1
    property string focusedName: ""
    property bool isScratchpad: false

    property bool scrollBusy: false

    // --- Primary query: full workspace list ---
    Process {
        id: queryProc
        command: ["niri", "msg", "--json", "workspaces"]
        running: false
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    const obj = JSON.parse(collector.text)
                    if (Array.isArray(obj)) {
                        root.wsData = obj
                        root.focusedId = -1
                        root.focusedName = ""
                        for (const w of obj) {
                            if (w.is_focused) {
                                root.focusedId  = w.id
                                root.focusedName = w.name || ""
                            }
                        }
                        root.isScratchpad = root.focusedName !== "" && root.focusedName !== null
                    }
                } catch (e) {
                    // malformed JSON — keep current value
                }
            }
        }
    }

    // --- Event stream: instantly re-query when anything changes ---
    Process {
        id: eventProc
        command: ["niri", "msg", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf("Workspaces changed") !== -1 ||
                    line.indexOf("Window") !== -1 ||
                    line.indexOf("Overview toggled") !== -1) {
                    if (!queryProc.running) {
                        queryProc.running = false
                        queryProc.running = true
                    }
                }
            }
        }
    }

    // --- Safety-net poll: re-query if event stream missed something ---
    Timer {
        interval: 2000
        running:  true
        repeat:   true
        onTriggered: { if (!queryProc.running) { queryProc.running = false; queryProc.running = true } }
    }

    // --- Dispatch: `niri msg action focus-workspace <REFERENCE>` ---
    Process {
        id: dispatchProc
        command: []
        running: false
    }

    function dispatchWorkspace(wsTarget, isSpecialToggle = false) {
        // niri has no "special workspace" — specials are just named
        // workspaces. A scratchpad toggle in visual terms goes to the
        // named workspace "magic" (created by the user's niri config),
        // matching the original Brain_Shell behaviour.
        if (isSpecialToggle) {
            dispatchProc.command = ["niri", "msg", "action", "focus-workspace", "magic"]
        } else {
            dispatchProc.command = ["niri", "msg", "action", "focus-workspace", String(wsTarget)]
        }
        dispatchProc.running = false
        dispatchProc.running = true
        // Optimistically reflect in UI
        if (isSpecialToggle) {
            root.isScratchpad = !root.isScratchpad
        } else {
            root.focusedId = Number(wsTarget)
        }
    }

    // --- 1. Capsule Container ---
    color: Theme.wsBackground
    radius: Theme.wsRadius

    // Auto-size
    width: workspaceRow.width + (Theme.wsPadding * 2)
    height: Theme.wsDotSize + (Theme.wsPadding * 2)

    Timer {
        id: scrollCooldown
        interval: 300
        repeat:   false
        onTriggered: root.scrollBusy = false
    }

    // ---Wheel: cycle through occupied workspaces ---
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (root.scrollBusy) return // Ignore if still in cooldown
            root.scrollBusy = true
            scrollCooldown.restart()
            let occupied = root.wsData.map(w => w.id).sort((a, b) => a - b)
            if (occupied.length === 0) return // Safety check

            let currentId = root.focusedId !== -1 ? root.focusedId : occupied[0]
            let idx = occupied.indexOf(currentId)
            if (idx === -1) idx = 0 // Fallback if current isn't in the array

            // Inverted scroll logic: Up (>0) goes to Next, Down (<0) goes to Prev
            if (event.angleDelta.y < 0) {
                idx = (idx + 1) % occupied.length
            } else {
                idx = (idx - 1 + occupied.length) % occupied.length
            }

            root.dispatchWorkspace(occupied[idx])
        }
    }

    // --- 3. Workspace Dots ---
    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Theme.wsSpacing

        // Logic: Fade out dots when Scratchpad is active
        opacity: root.isScratchpad ? 0 : 1
        scale:   root.isScratchpad ? 0.8 : 1
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale   { NumberAnimation { duration: 200 } }

        Repeater {
            model: 10
            delegate: Rectangle {
                id: dot

                property var ws: root.wsData.find(w => w.id === index + 1)
                property bool isActive: root.focusedId === (index + 1)
                property bool isOccupied: ws !== undefined && ws.active_window_id !== null
                property bool isUrgent:   ws !== undefined && ws.is_urgent

                height: Theme.wsDotSize
                radius: height / 2
                width: isActive ? Theme.wsActiveWidth : Theme.wsDotSize

                color: {
                    if (isActive)   return Theme.wsActive
                    if (isUrgent)   return Theme.wsUrgent
                    if (isOccupied) return Theme.wsOccupied
                    return Theme.wsEmpty
                }

                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }

                // --- Urgent pulse ---
                SequentialAnimation {
                    running: dot.isUrgent && !dot.isActive
                    loops:   Animation.Infinite

                    NumberAnimation {
                        target:   dot
                        property: "scale"
                        to:       1.35
                        duration: 400
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target:   dot
                        property: "scale"
                        to:       1.0
                        duration: 400
                        easing.type: Easing.InOutSine
                    }
                }

                // Reset scale when no longer urgent
                onIsUrgentChanged: {
                    if (!isUrgent) scale = 1.0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dispatchWorkspace(index + 1)
                }
            }
        }
    }

    // --- 4. Scratchpad Overlay ---
    Rectangle {
        id: overlay
        anchors.fill: parent
        radius: root.radius
        color: Theme.wsOverlay
        z: 99

        // Logic: Fade in overlay when Scratchpad is active
        visible: opacity > 0
        opacity: root.isScratchpad ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: ""
            color: "#FFFFFF"
            font.pixelSize: 14
        }

        MouseArea {
            anchors.fill: parent
            onClicked:  root.dispatchWorkspace("magic", true)
        }
    }
}