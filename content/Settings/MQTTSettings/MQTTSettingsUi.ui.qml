import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import SettingsCommon 1.0

Item {
    id: mqttSettings

    property alias hostInput: hostInput
    property alias portInput: portInput
    property alias qosCombo: qosCombo
    property alias rxTopicInput: rxTopicInput
    property alias txTopicInput: txTopicInput
    property alias clientIdInput: clientIdInput
    property alias usernameInput: usernameInput
    property alias passwordInput: passwordInput
    property alias keepAliveInput: keepAliveInput

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: mqttSettings.width
            anchors.margins: SettingsTheme.margins.medium
            spacing: SettingsTheme.spacing.medium

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: SettingsTheme.spacing.medium
                rowSpacing: SettingsTheme.spacing.medium

                Label {
                    text: qsTr("Host")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: hostInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("Broker host")
                }

                Label {
                    text: qsTr("Port")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: portInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("1883")
                    inputMethodHints: Qt.ImhDigitsOnly
                }

                RowLayout {
                    spacing: SettingsTheme.spacing.small

                    Label {
                        text: qsTr("QoS")
                        font.pixelSize: SettingsTheme.fontSize.medium
                        color: SettingsTheme.textLabel
                    }

                    Label {
                        text: "ⓘ"
                        font.pixelSize: SettingsTheme.fontSize.small
                        color: SettingsTheme.textSecondary

                        MouseArea {
                            id: qosTooltipArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        ToolTip {
                            visible: qosTooltipArea.containsMouse
                            text: qsTr("Quality of Service:\nQoS 0: At most once (fire and forget)\nQoS 1: At least once (acknowledged)\nQoS 2: Exactly once (assured)")
                            delay: 500
                        }
                    }
                }

                ComboBox {
                    id: qosCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.combobox
                    model: [
                        { text: qsTr("QoS 0"), value: 0 },
                        { text: qsTr("QoS 1"), value: 1 },
                        { text: qsTr("QoS 2"), value: 2 }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    currentIndex: 0
                }

                Label {
                    text: qsTr("RX Topic")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: rxTopicInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("topic/in")
                }

                Label {
                    text: qsTr("TX Topic")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: txTopicInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("topic/out")
                }

                Label {
                    text: qsTr("Client ID")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: clientIdInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("Client id (optional)")
                }

                Label {
                    text: qsTr("Username")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: usernameInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("Username (optional)")
                }

                Label {
                    text: qsTr("Password")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: passwordInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("Password (optional)")
                    echoMode: TextInput.Password
                }

                Label {
                    text: qsTr("Keepalive (s)")
                    font.pixelSize: SettingsTheme.fontSize.medium
                    color: SettingsTheme.textLabel
                }
                TextField {
                    id: keepAliveInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: SettingsTheme.heights.input
                    placeholderText: qsTr("60")
                    inputMethodHints: Qt.ImhDigitsOnly
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
