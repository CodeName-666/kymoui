import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import SettingsCommon 1.0

Item {
    property alias colorDialog: colorDialog
    property alias colorView: colorView
    property alias colorButton: colorButton
    property alias nameInput: nameInput
    property alias typeCombo: typeCombo

    ColorDialog {
        id: colorDialog
        title: "Please choose a color"
    }

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
                text: qsTr("Name:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
            }
            TextField {
                id: nameInput
                Layout.fillWidth: true
                Layout.preferredHeight: SettingsTheme.heights.input
                placeholderText: qsTr("Test name")
            }

            Label {
                id: colorText
                text: qsTr("Color:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
            }

            Rectangle {
                id: colorView
                color: "#00ffffff"
                border.width: 2
                border.color: SettingsTheme.borderColor
                Layout.preferredHeight: SettingsTheme.heights.input
                Layout.fillWidth: true
                radius: SettingsTheme.radius.small
                MouseArea {
                    id: colorButton
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Label {
                text: qsTr("Line Type:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
            }

            ComboBox {
                id: typeCombo
                Layout.fillWidth: true
                Layout.preferredHeight: SettingsTheme.heights.combobox
                model: ["Sinus", "Rectangle", "Ramp", "Line", "Random", "Multi"]
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
