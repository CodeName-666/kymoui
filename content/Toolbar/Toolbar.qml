import QtQuick 6.4

ToolbarUi {
    signal menuRequested

    menuButton.onClicked: menuRequested()
}
