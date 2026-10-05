import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0
import Backend 1.0

Dialog {
    id: root

    title: qsTr("Edit Connection")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    // Properties
    property string connectionId: ""
    property string connectionType: ""

    // Signal
    signal connectionUpdated(string connectionId)

    width: 550
    height: 650

    background: Rectangle {
        color: "#2d2d2d"
        border.color: "#4d4d4d"
        border.width: 1
        radius: 8
    }

    header: Rectangle {
        height: 60
        color: "#353535"
        radius: 8

        Label {
            anchors.centerIn: parent
            text: root.title
            font.pixelSize: 18
            font.bold: true
            color: "#ffffff"
        }
    }

    contentItem: Item {
        implicitWidth: 530
        implicitHeight: 550

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Connection Name
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: qsTr("Connection Name") + " *"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                }

                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Enter connection name")
                    font.pixelSize: 13

                    background: Rectangle {
                        color: "#3d3d3d"
                        border.color: parent.activeFocus ? "#007AFF" : "#606060"
                        border.width: 1
                        radius: 4
                    }

                    color: "#ffffff"
                }
            }

            // Interface Type (read-only)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: qsTr("Interface Type")
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                }

                Label {
                    id: interfaceTypeLabel
                    text: root.connectionType
                    font.pixelSize: 13
                    color: "#b0b0b0"
                }
            }

            // Settings Area (dynamically loaded based on interface type)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#353535"
                radius: 6
                border.color: "#4d4d4d"
                border.width: 1

                Loader {
                    id: settingsLoader
                    anchors.fill: parent
                    anchors.margins: 16
                }
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            text: qsTr("Save")
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled: nameField.text.trim() !== ""

            background: Rectangle {
                color: {
                    if(!parent.enabled) return "#5d5d5d"
                    if(parent.pressed) return "#0056b3"
                    if(parent.hovered) return "#007AFF"
                    return "#0066cc"
                }
                radius: 4
                border.color: parent.enabled ? "#ffffff30" : "transparent"
                border.width: 1
            }

            contentItem: Text {
                text: parent.text
                color: parent.enabled ? "#ffffff" : "#a0a0a0"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: parent.font
            }
        }

        Button {
            text: qsTr("Cancel")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole

            background: Rectangle {
                color: parent.pressed ? "#4d4d4d" : (parent.hovered ? "#5d5d5d" : "#3d3d3d")
                border.color: "#606060"
                border.width: 1
                radius: 4
            }

            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: parent.font
            }
        }

        background: Rectangle {
            color: "#353535"
        }
    }

    onAccepted: {
        updateConnection()
    }

    // Functions
    function loadConnection(connId, connName, connType, connSettings) {
        root.connectionId = connId
        root.connectionType = connType
        nameField.text = connName

        loadSettingsForInterface(connType, connSettings)
    }

    function loadSettingsForInterface(interfaceType, settings) {
        var componentPath = ""

        switch(interfaceType) {
            case "Serial":
                componentPath = "SerialSettings.qml"
                break
            case "MQTT":
                componentPath = "MqttSettings.qml"
                break
            case "Telnet":
                componentPath = "TelnetSettings.qml"
                break
            case "CAN":
                componentPath = "CanSettings.qml"
                break
            case "Test":
                componentPath = "TestSettings.qml"
                break
            default:
                Logger.log_warning("Unknown interface type: " + interfaceType)
                settingsLoader.sourceComponent = null
                return
        }

        settingsLoader.source = componentPath

        // Load current settings into the form
        if(settingsLoader.item && typeof settingsLoader.item.loadDefaults === "function") {
            settingsLoader.item.loadDefaults(settings)
        }
    }

    function updateConnection() {
        var displayName = nameField.text.trim()
        var settings = {}

        // Get settings from loaded component
        if(settingsLoader.item && typeof settingsLoader.item.getSettings === "function") {
            settings = settingsLoader.item.getSettings()
        }

        // Update connection via Backend
        if(Backend.update_connection_settings(root.connectionId, settings)) {
            if(Backend.rename_connection(root.connectionId, displayName)) {
                Logger.log_info("Connection updated: " + root.connectionId)
                root.connectionUpdated(root.connectionId)
            }
        } else {
            Logger.log_error("Failed to update connection")
        }
    }
}
