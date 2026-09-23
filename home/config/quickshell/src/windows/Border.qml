import Quickshell
import QtQuick
import "../"
import "../services/"

PanelWindow {
    id: root

    property string edge: "bottom"
    property bool isBarEnabled: Theme.barEnabled
    property int thickness: Theme.borderWidth      
    property int radius: Theme.cornerRadius        
    property color fillColor: Theme.background 
    
    implicitWidth: (edge === "left" || edge === "right") ? radius : 0
    implicitHeight: (edge === "bottom") ? radius : 0

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: (edge === "left" || edge === "bottom")
        right: (edge === "right" || edge === "bottom")
        bottom: true
        top: (edge !== "bottom")
    }

    margins {
        top: (edge !== "bottom") ? ShellState.focusMode ? Theme.borderWidth : Theme.notchHeight: 0
        Behavior on top { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }}
        
        bottom: (edge !== "bottom") ? radius : 0
    }

    Item {
        anchors.fill: parent

        // ── Left border — hover opens NixMenu ───────────────────────────────────
        Item {
            visible: root.edge === "left"
            anchors{
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }
            height: 300
            HoverHandler {
                enabled: root.edge === "left"
                onHoveredChanged: Popups.nixMenuTriggerHovered = hovered
            }
        }

        // ── Right border — hover opens AudioPopup ─────────────────────────────
        Item {
            visible: root.edge === "right"
            anchors{
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }
            height: 300
            HoverHandler {
                enabled: root.edge === "right"
                onHoveredChanged: {
                    Popups.quickTriggerHovered = hovered  
                    Popups.audioTriggerHovered = hovered
                }
            }
        }

        // ── Bottom border — centered 420px zone: wallpaper hover + tap ────────
        Item {
            visible:                  root.edge === "bottom"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.bottom:           parent.bottom
            width:                    420

            HoverHandler {
                onHoveredChanged: Popups.wallpaperTriggerHovered = hovered
            }

            TapHandler {
                onTapped: {
                    var next = !Popups.wallpaperOpen
                    Popups.closeAll()
                    Popups.wallpaperOpen = next
                }
            }
        }

        // ── Bottom border — right corner 80px zone: clipboard tap ─────────────
        Item {
            visible:        root.edge === "bottom"
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          80

            TapHandler {
                onTapped: {
                    var next = !Popups.clipboardOpen
                    Popups.closeAll()
                    Popups.clipboardOpen = next
                }
            }
        }
    }
}
