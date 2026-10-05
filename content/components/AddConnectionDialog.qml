import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import DataModels.SerialDataModels 1.0
import Backend 1.0

Dialog {
    id: addConnectionDialog

    // Signals
    signal connectionCreated(string connectionId)

    title: qsTr("Add New Connection")
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.NoButton

    width: 400
    height: 280

    background: Rectangle {
        color: "#f5f5f5"
        border.color: "#d0d0d0"
        border.width: 1
        radius: 8
    }

    contentItem: ColumnLayout {
        spacing: 16
        anchors.fill: parent
        anchors.margins: 20

        // Header
        Label {
            text: qsTr("Create a new connection")
            font.pixelSize: 16
            font.bold: true
            color: "#333"
            Layout.fillWidth: true
        }

        // Interface Type Selection
        ColumnLayout {
            spacing: 8
            Layout.fillWidth: true

            Label {
                text: qsTr("Interface Type:")
                font.pixelSize: 12
                color: "#666"
            }

            ComboBox {
                id: interfaceTypeCombo
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                model: ConnectionModel {}
                textRole: "name"
                valueRole: "val"

                onCurrentTextChanged: {
                    updateSuggestedName()
                }

                Component.onCompleted: {
                    if (model && model.count > 0) {
                        currentIndex = 0
                    }
                }
            }
        }

        // Connection Name Input
        ColumnLayout {
            spacing: 8
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: qsTr("Connection Name:")
                    font.pixelSize: 12
                    color: "#666"
                }

                Label {
                    text: qsTr("(optional)")
                    font.pixelSize: 10
                    font.italic: true
                    color: "#999"
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            TextField {
                id: connectionNameField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: suggestedNameLabel.text

                background: Rectangle {
                    radius: 4
                    color: connectionNameField.enabled ? "white" : "#f0f0f0"
                    border.color: connectionNameField.activeFocus ? "#2196f3" : "#d0d0d0"
                    border.width: connectionNameField.activeFocus ? 2 : 1
                }
            }

            // Suggested Name Preview
            Label {
                id: suggestedNameLabel
                text: ""
                font.pixelSize: 10
                font.italic: true
                color: "#999"
                visible: connectionNameField.text.trim() === ""
                Layout.fillWidth: true

                Component.onCompleted: {
                    updateSuggestedName()
                }
            }
        }

        // Info Text
        Label {
            text: qsTr("Leave name empty to use auto-generated name based on connection settings.")
            font.pixelSize: 10
            color: "#777"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Spacer
        Item {
            Layout.fillHeight: true
        }

        // Status Message
        Label {
            id: statusMessageLabel
            text: ""
            font.pixelSize: 11
            color: "#f44336"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            visible: text !== ""
        }

        // Buttons
        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: qsTr("Cancel")
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36

                onClicked: {
                    addConnectionDialog.close()
                }
            }

            Button {
                id: createButton
                text: qsTr("Create")
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36
                enabled: interfaceTypeCombo.currentText !== ""

                background: Rectangle {
                    radius: 4
                    color: {
                        if (!createButton.enabled) return "#e0e0e0"
                        if (createButton.pressed) return "#1565c0"
                        if (createButton.hovered) return "#1976d2"
                        return "#2196f3"
                    }
                    border.color: createButton.enabled ? "#1565c0" : "#bdbdbd"
                    border.width: 1

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                contentItem: Text {
                    text: createButton.text
                    font: createButton.font
                    color: createButton.enabled ? "white" : "#999"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    createConnection()
                }
            }
        }
    }

    function updateSuggestedName() {
        var interfaceType = interfaceTypeCombo.currentText
        if (interfaceType) {
            // This will be replaced by actual auto-generated name from backend
            suggestedNameLabel.text = qsTr("Suggested: %1 #%2").arg(interfaceType).arg("?")
        }
    }

    function createConnection() {
        var interfaceType = interfaceTypeCombo.currentText
        var displayName = connectionNameField.text.trim()

        if (!interfaceType) {
            statusMessageLabel.text = qsTr("Please select an interface type")
            return
        }

        Logger.log_info("AddConnectionDialog: Creating connection - Type: " + interfaceType + ", Name: " + displayName)

        // Create connection with empty settings (backend will use defaults)
        var connectionId = Backend.create_connection(interfaceType, displayName, {})

        if (connectionId && connectionId !== "") {
            Logger.log_info("AddConnectionDialog: Connection created successfully: " + connectionId)
            connectionCreated(connectionId)
            resetDialog()
            addConnectionDialog.close()
        } else {
            statusMessageLabel.text = qsTr("Failed to create connection. Check logs for details.")
            Logger.log_error("AddConnectionDialog: Failed to create connection")
        }
    }

    function resetDialog() {
        connectionNameField.text = ""
        statusMessageLabel.text = ""
        if (interfaceTypeCombo.model && interfaceTypeCombo.model.count > 0) {
            interfaceTypeCombo.currentIndex = 0
        }
    }

    onAboutToShow: {
        resetDialog()
    }
}
