import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0

ColumnLayout {
    id: root

    spacing: 12

    // Mode Selection
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Label {
            text: qsTr("Mode") + " *"
            font.pixelSize: 12
            font.bold: true
            color: "#ffffff"
        }

        ComboBox {
            id: modeCombo
            Layout.fillWidth: true
            font.pixelSize: 12

            model: ["Client", "Server"]
            currentIndex: 0

            background: Rectangle {
                color: "#3d3d3d"
                border.color: parent.activeFocus ? "#007AFF" : "#606060"
                border.width: 1
                radius: 4
            }

            contentItem: Text {
                text: modeCombo.displayText
                font: modeCombo.font
                color: "#ffffff"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
            }
        }

        Label {
            text: qsTr("Client: Connect to remote server\nServer: Accept incoming connections")
            font.pixelSize: 10
            color: "#808080"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // Host (only for Client mode)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: modeCombo.currentText === "Client"

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
            placeholderText: qsTr("Default: 23")
            text: "23"
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

    // Reconnect Delay (only for Client mode)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: modeCombo.currentText === "Client"

        Label {
            text: qsTr("Reconnect Delay (seconds)")
            font.pixelSize: 12
            font.bold: true
            color: "#ffffff"
        }

        SpinBox {
            id: reconnectSpinBox
            Layout.fillWidth: true
            from: 0
            to: 60
            value: 5
            editable: true
            font.pixelSize: 12

            background: Rectangle {
                color: "#3d3d3d"
                border.color: parent.activeFocus ? "#007AFF" : "#606060"
                border.width: 1
                radius: 4
            }

            contentItem: TextInput {
                text: reconnectSpinBox.textFromValue(reconnectSpinBox.value, reconnectSpinBox.locale)
                font: reconnectSpinBox.font
                color: "#ffffff"
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                readOnly: !reconnectSpinBox.editable
                validator: reconnectSpinBox.validator
            }

            up.indicator: Rectangle {
                x: reconnectSpinBox.width - width
                height: parent.height / 2
                color: reconnectSpinBox.up.pressed ? "#5d5d5d" : "#4d4d4d"
                border.color: "#606060"

                Text {
                    text: "+"
                    font.pixelSize: 14
                    color: "#ffffff"
                    anchors.centerIn: parent
                }
            }

            down.indicator: Rectangle {
                x: reconnectSpinBox.width - width
                y: parent.height / 2
                height: parent.height / 2
                color: reconnectSpinBox.down.pressed ? "#5d5d5d" : "#4d4d4d"
                border.color: "#606060"

                Text {
                    text: "-"
                    font.pixelSize: 14
                    color: "#ffffff"
                    anchors.centerIn: parent
                }
            }
        }

        Label {
            text: qsTr("0 = No automatic reconnection")
            font.pixelSize: 10
            color: "#808080"
        }
    }

    Item {
        Layout.fillHeight: true
    }

    // Functions
    function loadDefaults(defaults) {
        if(defaults.mode) {
            var modeIndex = modeCombo.model.indexOf(defaults.mode)
            if(modeIndex >= 0) {
                modeCombo.currentIndex = modeIndex
            }
        }
        if(defaults.host) hostField.text = defaults.host
        if(defaults.port) portField.text = defaults.port.toString()
        if(defaults.reconnect_delay !== undefined) {
            reconnectSpinBox.value = defaults.reconnect_delay
        }
    }

    function getSettings() {
        var settings = {
            "mode": modeCombo.currentText,
            "port": parseInt(portField.text)
        }

        if(modeCombo.currentText === "Client") {
            settings.host = hostField.text
            settings.reconnect_delay = reconnectSpinBox.value
        }

        return settings
    }
}
