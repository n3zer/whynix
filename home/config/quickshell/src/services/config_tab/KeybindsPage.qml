import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../"
import "../../"

// Active niri keybinds (parsed by KeybindService from binds.user.kdl).
// Rows are editable: click the combo pill to record a new combo, ✕ to unbind.
// Changes are written by patch_niri_binds.py to the live + repo copies of
// binds.user.kdl; niri reloads on its own through the include watcher.
//
// Search: the page is a FocusScope that grabs focus while the tab is open, so
// you can simply start typing words — no clicking the field needed. Query
// words are AND'd across combo / mods / key / action / args / comment.
// Escape: first clears the query, second (empty) bubbles up and closes.
FocusScope {
    id: root

    property var _binds: KeybindService._niriBinds
    property string _query: searchInput.text

    Component.onCompleted: KeybindService.loadNiriBinds()

    // Refocus the search field whenever this tab becomes visible, so typing
    // works immediately ("no field to click").
    Connections {
        target: root.parent
        function onVisibleChanged() {
            if (root.parent && root.parent.visible)
                Qt.callLater(function() { searchInput.forceActiveFocus() })
        }
    }

    // Grab keys while the tab is shown but no inner field has focus — after
    // a rebind capture, or a stray click — and route printable keys to search.
    focus: root.parent ? root.parent.visible : false
    Keys.onPressed: function(event) {
        if (searchInput.activeFocus) return
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        if (event.text.length === 1) {
            searchInput.insert(searchInput.cursorPosition, event.text)
            event.accepted = true
            searchInput.forceActiveFocus()
        }
    }

    // ── Filter logic ─────────────────────────────────────────────────────────
    function _matchQuery(b) {
        var words = root._query.trim().toLowerCase().split(/\s+/)
        var hay = [
            b.combo, b.mods, b.key, b.action, b.args, b.comment, b.label
        ].join(" ").toLowerCase()
        for (var i = 0; i < words.length; i++)
            if (words[i] !== "" && hay.indexOf(words[i]) < 0) return false
        return true
    }

    // Reactive filtered view of the binds (recomputes on query/binds change).
    readonly property var _filteredBinds: root._query.trim() === ""
        ? root._binds
        : root._binds.filter(root._matchQuery)

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

    // ── Search bar ───────────────────────────────────────────────────────────
    Rectangle {
        id: _searchWrap
        anchors {
            top:        parent.top
            left:       parent.left
            right:      parent.right
            topMargin:  6
            leftMargin: 12
            rightMargin: 12
        }
        height: 34
        radius: 8
        color: searchInput.activeFocus
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
            : Qt.rgba(1, 1, 1, 0.05)
        border.color: searchInput.activeFocus
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
            : Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter
                      leftMargin: 12 }
            text:           ""
            font.pixelSize: 12
            color: searchInput.activeFocus
                ? Theme.active
                : Qt.rgba(1, 1, 1, 0.35)
        }

        TextField {
            id: searchInput
            anchors {
                left:   parent.left
                right:  _clearBtn.visible ? _clearBtn.left : parent.right
                rightMargin: _clearBtn.visible ? 4 : 12
                verticalCenter: parent.verticalCenter
                leftMargin:    32
            }
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            font { pixelSize: 12; family: "JetBrains Mono" }
            color:          Qt.rgba(1, 1, 1, 0.85)
            selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
            placeholderText:    "Search keybinds — just type…"
            placeholderTextColor: Qt.rgba(1, 1, 1, 0.28)
            selectByMouse:      true
            activeFocusOnTab:   true
            background:         Item {}

            // First Escape clears the query, a second (empty) one bubbles up
            // to Dashboard and closes the popup.
            Keys.onEscapePressed: function(event) {
                if (searchInput.text.length > 0) {
                    searchInput.clear()
                    event.accepted = true
                }
            }
        }

        // ✕ clear button — visible only while there's a query
        Rectangle {
            id: _clearBtn
            anchors {
                right:          parent.right
                rightMargin:    8
                verticalCenter: parent.verticalCenter
            }
            width: 18; height: 18; radius: 5
            visible:      searchInput.text.length > 0
            color:        _clrH.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
            Text {
                anchors.centerIn: parent
                text:           "󰩺"
                font.pixelSize: 9
                color: _clrH.hovered ? Qt.rgba(1,1,1,0.85) : Qt.rgba(1,1,1,0.45)
            }
            HoverHandler { id: _clrH; cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    searchInput.clear()
                    searchInput.forceActiveFocus()
                }
            }
        }
    }

    // ── Scrollable list ───────────────────────────────────────────────────────
    Flickable {
        anchors {
            top:         _searchWrap.bottom
            left:        parent.left
            right:       parent.right
            bottom:      parent.bottom
            leftMargin:  12
            rightMargin: 12
            bottomMargin: 12
            topMargin:   8
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
                    text: {
                        if (root._query.trim() === "")
                            return "Active Keybinds (niri / binds.user.kdl)"
                        return "Active Keybinds (" + root._filteredBinds.length + " of " + root._binds.length + ")"
                    }
                    font.pixelSize: 9
                    font.weight:    Font.Bold
                    color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
                }
            }

            Repeater {
                id: _list
                model: root._filteredBinds
                delegate: BindRow {
                    required property var modelData
                    combo: modelData.combo
                    width: _col.width
                    onRebindRequested:  root._applyOps([{ combo: combo, mods: mods, key: key }])
                    onConfirmRequested: root._confirmRebind(combo, mods, key)
                    onUnbindRequested: root._applyOps([{ combo: combo, unbind: true }])
                }
                onCountChanged: _noMatches.visible = _list.count === 0 && root._query.trim() !== ""
            }

            // Shown when the query filters out every bind
            Item {
                id: _noMatches
                visible: false
                width:  parent.width
                height: 120
                Text {
                    anchors.centerIn: parent
                    text:           "No keybinds match \u201C" + root._query + "\u201D"
                    font.pixelSize: 11
                    font.italic:    true
                    color:          Qt.rgba(1, 1, 1, 0.30)
                }
            }

            Item {
                width:  parent.width
                height: 18
                Text {
                    anchors { top: parent.top; topMargin: 10 }
                    width: parent.width
                    text:           "Click a combo pill to rebind, ✕ to unbind. Start typing to filter. Writes to \u2025/dotfiles/home/config/niri/binds.user.kdl and reloads automatically."
                    font.pixelSize: 9
                    wrapMode:       Text.WordWrap
                    color:          Qt.rgba(1, 1, 1, 0.35)
                }
            }
        }
    }

}