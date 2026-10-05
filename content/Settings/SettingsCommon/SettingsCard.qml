import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import SettingsCommon 1.0

Rectangle {
    id: settingsCard

    color: SettingsTheme.interfaceBackground
    radius: SettingsTheme.radius.medium

    property alias content: contentLoader.sourceComponent
    property int contentMargins: SettingsTheme.margins.medium

    Loader {
        id: contentLoader
        anchors.fill: parent
        anchors.margins: contentMargins
    }
}
