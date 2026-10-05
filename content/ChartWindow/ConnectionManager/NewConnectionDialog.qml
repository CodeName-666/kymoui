import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0
import Backend 1.0

Dialog {
    id: root

    title: qsTr("New Connection")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    // Signal
    signal connectionCreated(string connectionId)

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
                    text: qsTr("Connection Name")
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                }

                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Enter connection name (optional)")
                    font.pixelSize: 13

                    background: Rectangle {
                        color: "#3d3d3d"
                        border.color: parent.activeFocus ? "#007AFF" : "#606060"
                        border.width: 1
                        radius: 4
                    }

                    color: "#ffffff"
                }

                Label {
                    text: qsTr("Leave empty to auto-generate name")
                    font.pixelSize: 11
                    color: "#808080"
                }
            }

            // Interface Type Selection
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: qsTr("Interface Type") + " *"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                }

                ComboBox {
                    id: interfaceTypeCombo
                    Layout.fillWidth: true
                    model: ListModel {
                        id: interfaceTypesModel
                    }
                    textRole: "type"
                    font.pixelSize: 13

                    background: Rectangle {
                        color: "#3d3d3d"
                        border.color: parent.activeFocus ? "#007AFF" : "#606060"
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.displayText
                        font: parent.font
                        color: "#ffffff"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }

                    onCurrentIndexChanged: {
                        loadSettingsForInterface(currentIndex)
                    }
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
            text: qsTr("Create")
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled: interfaceTypeCombo.currentIndex >= 0

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
        createConnection()
    }

    onAboutToShow: {
        loadInterfaceTypes()
        nameField.text = ""
        if(interfaceTypeCombo.count > 0) {
            interfaceTypeCombo.currentIndex = 0
        }
    }

    // Functions
    function loadInterfaceTypes() {
        var types = Backend.get_interface_types()
        interfaceTypesModel.clear()

        for(var i = 0; i < types.length; i++) {
            interfaceTypesModel.append({
                "type": types[i].type,
                "defaults": types[i].defaults
            })
        }

        if(interfaceTypesModel.count > 0) {
            interfaceTypeCombo.currentIndex = 0
        }
    }

    function loadSettingsForInterface(index) {
        if(index < 0 || index >= interfaceTypesModel.count) {
            settingsLoader.sourceComponent = null
            return
        }

        var interfaceType = interfaceTypesModel.get(index).type
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

        // Load default settings into the form
        if(settingsLoader.item && interfaceTypesModel.get(index).defaults) {
            settingsLoader.item.loadDefaults(interfaceTypesModel.get(index).defaults)
        }
    }

    function createConnection() {
        var interfaceType = interfaceTypesModel.get(interfaceTypeCombo.currentIndex).type
        var displayName = nameField.text.trim()
        var settings = {}

        // Get settings from loaded component
        if(settingsLoader.item && typeof settingsLoader.item.getSettings === "function") {
            settings = settingsLoader.item.getSettings()
        }

        // Create connection via Backend
        var connectionId = Backend.create_connection(interfaceType, displayName, settings)

        if(connectionId && connectionId !== "") {
            Logger.log_info("Connection created: " + connectionId)
            root.connectionCreated(connectionId)
        } else {
            Logger.log_error("Failed to create connection")
        }
    }
}
