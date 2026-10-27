import QtQuick
import qs.common
import qs.services
import qs.widgets

// "jack ▴": pick who logs in (or type another name).
Chip {
    id: root

    property string direction: "up"

    visible: Theme.show.users && Config.users.showList && (Users.list.length > 1 || Config.users.allowOther)
    icon: "account"
    tint: Theme.accent2
    text: Users.displayName(Auth.user)
    clickable: true
    trailingChevron: true
    onClicked: menu.toggle()

    Menu {
        id: menu
        anchor: root
        title: "Users"
        direction: root.direction
        model: Users.list.map(u => ({ icon: "account_circle", text: u.real || u.name, sub: u.real ? u.name : "", active: u.name === Auth.user })).concat(Config.users.allowOther ? [{ icon: "account_plus", text: "Someone else…" }] : [])
        onPicked: i => {
            if (i < Users.list.length)
                Auth.selectUser(Users.list[i].name);
            else
                Activity.otherUserRequested();
        }
    }
}
