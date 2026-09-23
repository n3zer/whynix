import QtQuick
import "../../components"
import "../../"

IconBtn {
		text: "󱄅" 
		textColor: "#5277C3"
		onClicked: {
        var next = !Popups.nixMenuOpen
        Popups.closeAll()
        Popups.nixMenuOpen = next
    }
}
