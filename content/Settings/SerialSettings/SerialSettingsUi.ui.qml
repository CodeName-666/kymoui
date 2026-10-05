import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import DataModels.SerialDataModels 1.0
import SettingsCommon 1.0

Item {
    id: serial_settings
    property var com_ports: []
    property alias comComboBox: comComboBox
    property alias baudInput: baudInput
    property alias dataSizeComboBox: dataSizeComboBox
    property alias parityComboBox: parityComboBox
    property alias stopBitsCombo: stopBitsCombo

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: SettingsTheme.margins.large
        anchors.leftMargin: SettingsTheme.margins.large
        anchors.rightMargin: SettingsTheme.margins.large
        anchors.bottomMargin: SettingsTheme.margins.medium
        spacing: SettingsTheme.spacing.large

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: SettingsTheme.spacing.extraLarge
            rowSpacing: SettingsTheme.spacing.large

            Label {
                text: qsTr("COM - Port:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: SettingsTheme.heights.label
                Layout.columnSpan: 1
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
            }

            ComboBox {
                id: comComboBox
                model: serial_settings.com_ports
                Layout.fillWidth: true
                Layout.preferredHeight: SettingsTheme.heights.combobox
                font.pixelSize: SettingsTheme.fontSize.medium
            }

            Label {
                text: qsTr("Baudrate:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: SettingsTheme.heights.label
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
            }

            TextField {
                id: baudInput
                Layout.fillWidth: true
                Layout.preferredHeight: SettingsTheme.heights.input
                placeholderText: qsTr("e.g. 9600, 115200")
                inputMethodHints: Qt.ImhDigitsOnly
                font.pixelSize: SettingsTheme.fontSize.medium
            }

            Label {
                text: qsTr("Datasize:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: SettingsTheme.heights.label
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
            }

            ComboBox {
                id: dataSizeComboBox
                textRole: "name"
                valueRole: "value"
                Layout.fillWidth: true
                Layout.preferredHeight: SettingsTheme.heights.combobox
                model: DataSizeModel {}
                font.pixelSize: SettingsTheme.fontSize.medium
            }

            RowLayout {
                spacing: SettingsTheme.spacing.small
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: SettingsTheme.heights.label

                Label {
                    text: qsTr("Parity:")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideNone
                    wrapMode: Text.NoWrap
                }

                Label {
                    text: "ⓘ"
                    font.pixelSize: SettingsTheme.fontSize.small
                    color: SettingsTheme.textSecondary
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        id: parityTooltipArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    ToolTip {
                        visible: parityTooltipArea.containsMouse
                        text: qsTr("Error checking method:\nNone: No parity check\nEven: Even number of 1-bits\nOdd: Odd number of 1-bits")
                        delay: 500
                    }
                }
            }

            ComboBox {
                id: parityComboBox
                Layout.fillWidth: true
                textRole: "name"
                valueRole: "value"
                Layout.preferredHeight: SettingsTheme.heights.combobox
                model: ParityBitsModel {}
                font.pixelSize: SettingsTheme.fontSize.medium
            }

            Label {
                text: qsTr("Stop-Bits:")
                font.pixelSize: SettingsTheme.fontSize.medium
                color: SettingsTheme.textLabel
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: SettingsTheme.heights.label
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
                wrapMode: Text.NoWrap
            }

            ComboBox {
                id: stopBitsCombo
                Layout.fillWidth: true
                textRole: "name"
                valueRole: "value"
                Layout.preferredHeight: SettingsTheme.heights.combobox
                model: StopBitsModel {}
                font.pixelSize: SettingsTheme.fontSize.medium
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
