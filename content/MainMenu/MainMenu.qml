import QtQuick 6.4

MainMenuUi {
    signal newRequested()
    signal quitRequested()
    signal settingsRequested()
    signal aboutRequested()

    newButton.onTriggered: newRequested()
    closeButton.onTriggered: quitRequested()
    settingsButton.onTriggered: settingsRequested()
    aboutButton.onTriggered: aboutRequested()
}
