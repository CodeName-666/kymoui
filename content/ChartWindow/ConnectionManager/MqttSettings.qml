import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0

ScrollView {
    id: root

    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: root.availableWidth
        spacing: 12

        // Host
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Host") + " *"
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
            }

            TextField {
                id: hostField
                Layout.fillWidth: true
                placeholderText: qsTr("e.g., localhost or 192.168.1.100")
                text: "localhost"
                font.pixelSize: 12

                background: Rectangle {
                    color: "#3d3d3d"
                    border.color: parent.activeFocus ? "#007AFF" : "#606060"
                    border.width: 1
                    radius: 4
                }

                color: "#ffffff"
            }
        }

        // Port
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Port") + " *"
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
            }

            TextField {
                id: portField
                Layout.fillWidth: true
                placeholderText: qsTr("Default: 1883")
                text: "1883"
                font.pixelSize: 12
                validator: IntValidator { bottom: 1; top: 65535 }

                background: Rectangle {
                    color: "#3d3d3d"
                    border.color: parent.activeFocus ? "#007AFF" : "#606060"
                    border.width: 1
                    radius: 4
                }

                color: "#ffffff"
            }
        }

        // RX Topic
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Receive Topic") + " *"
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
            }

            TextField {
                id: rxTopicField
                Layout.fillWidth: true
                placeholderText: qsTr("e.g., sensor/data")
                text: "sensor/data"
                font.pixelSize: 12

                background: Rectangle {
                    color: "#3d3d3d"
                    border.color: parent.activeFocus ? "#007AFF" : "#606060"
                    border.width: 1
                    radius: 4
                }

                color: "#ffffff"
            }
        }

        // TX Topic
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Transmit Topic")
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
            }

            TextField {
                id: txTopicField
                Layout.fillWidth: true
                placeholderText: qsTr("e.g., sensor/command")
                text: "sensor/command"
                font.pixelSize: 12

                background: Rectangle {
                    color: "#3d3d3d"
                    border.color: parent.activeFocus ? "#007AFF" : "#606060"
                    border.width: 1
                    radius: 4
                }

                color: "#ffffff"
            }
        }

        // Client ID
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Client ID")
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
            }

            TextField {
                id: clientIdField
                Layout.fillWidth: true
                placeholderText: qsTr("Leave empty for auto-generated")
                font.pixelSize: 12

                background: Rectangle {
                    color: "#3d3d3d"
                    border.color: parent.activeFocus ? "#007AFF" : "#606060"
                    border.width: 1
                    radius: 4
                }

                color: "#ffffff"
            }

            Label {
                text: qsTr("Auto-generated if left empty")
                font.pixelSize: 10
                color: "#808080"
            }
        }

        // Username
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Username (optional)")
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
            }

            TextField {
                id: usernameField
                Layout.fillWidth: true
                placeholderText: qsTr("Leave empty if no authentication")
                font.pixelSize: 12

                background: Rectangle {
                    color: "#3d3d3d"
                    border.color: parent.activeFocus ? "#007AFF" : "#606060"
                    border.width: 1
                    radius: 4
                }

                color: "#ffffff"
            }
        }

        // Password
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Password (optional)")
                font.pixelSize: 12
                font.bold: true
                color: "#ffffff"
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: qsTr("Leave empty if no authentication")
                echoMode: TextInput.Password
                font.pixelSize: 12

                background: Rectangle {
                    color: "#3d3d3d"
                    border.color: parent.activeFocus ? "#007AFF" : "#606060"
                    border.width: 1
                    radius: 4
                }

                color: "#ffffff"
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    // Functions
    function loadDefaults(defaults) {
        if(defaults.host) hostField.text = defaults.host
        if(defaults.port) portField.text = defaults.port.toString()
        if(defaults.rx_topic) rxTopicField.text = defaults.rx_topic
        if(defaults.tx_topic) txTopicField.text = defaults.tx_topic
        if(defaults.client_id) clientIdField.text = defaults.client_id
        if(defaults.username) usernameField.text = defaults.username
        if(defaults.password) passwordField.text = defaults.password
    }

    function getSettings() {
        return {
            "host": hostField.text,
            "port": parseInt(portField.text),
            "rx_topic": rxTopicField.text,
            "tx_topic": txTopicField.text,
            "client_id": clientIdField.text,
            "username": usernameField.text,
            "password": passwordField.text
        }
    }
}
