import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import SettingsCommon 1.0

ColumnLayout {
    id: formField

    property alias label: labelText.text
    property alias control: controlLoader.sourceComponent
    property alias controlItem: controlLoader.item
    property string errorText: ""
    property bool hasError: errorText !== ""
    property string tooltipText: ""

    spacing: SettingsTheme.spacing.small

    RowLayout {
        Layout.fillWidth: true
        spacing: SettingsTheme.spacing.small

        Label {
            id: labelText
            font.pixelSize: SettingsTheme.fontSize.medium
            color: hasError ? SettingsTheme.errorColor : SettingsTheme.textLabel
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        // Tooltip icon
        Label {
            visible: tooltipText !== ""
            text: "ⓘ"
            font.pixelSize: SettingsTheme.fontSize.small
            color: SettingsTheme.textSecondary
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                id: tooltipArea
                anchors.fill: parent
                hoverEnabled: true
            }

            ToolTip {
                visible: tooltipArea.containsMouse
                text: tooltipText
                delay: 500
            }
        }
    }

    Loader {
        id: controlLoader
        Layout.fillWidth: true
    }

    // Error message
    Label {
        visible: hasError
        text: errorText
        color: SettingsTheme.errorColor
        font.pixelSize: SettingsTheme.fontSize.small
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
