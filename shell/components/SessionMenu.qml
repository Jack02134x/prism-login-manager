import QtQuick
import qs.common
import qs.services
import qs.widgets

// Which desktop to start.
Chip {
    id: root

    property string direction: "up"

    visible: Theme.show.sessions && Sessions.list.length > 0
    icon: Sessions.icon(Auth.sessionInfo)
    tint: Theme.accent1
    text: Auth.sessionInfo?.name ?? "No session"
    clickable: true
    trailingChevron: true
    onClicked: menu.toggle()

    Menu {
        id: menu
        anchor: root
        title: "Session"
        direction: root.direction
        menuWidth: 320
        model: Sessions.list.map(s => ({ icon: Sessions.icon(s), text: s.name, sub: s.type === "x11" ? "X11 · " + (s.comment || s.id) : s.comment, active: s.id === Auth.session }))
        onPicked: i => Auth.selectSession(Sessions.list[i].id)
    }
}
