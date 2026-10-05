import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import SettingsCommon 1.0

Item {
    id: telnet_settings
    property alias portInput: portInput
    property alias ipInput: ipInput

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: SettingsTheme.margins.medium
        spacing: SettingsTheme.spacing.medium

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: SettingsTheme.spacing.medium
            rowSpacing: SettingsTheme.spacing.medium

            Label {
                text: qsTr("IP-Address/URL:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
            }

            TextField {
                id: ipInput
                Layout.fillWidth: true
                Layout.preferredHeight: SettingsTheme.heights.input
                placeholderText: qsTr("e.g. 192.168.1.100 or hostname")
            }

            Label {
                text: qsTr("Port:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
            }

            TextField {
                id: portInput
                Layout.fillWidth: true
                Layout.preferredHeight: SettingsTheme.heights.input
                placeholderText: qsTr("e.g. 23")
                inputMethodHints: Qt.ImhDigitsOnly
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
