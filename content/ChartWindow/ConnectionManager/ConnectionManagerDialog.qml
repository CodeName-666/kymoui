import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0
import Backend 1.0

Dialog {
    id: root

    title: qsTr("Connection Manager")
    modal: true

    width: 700
    height: 500

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

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Label {
                text: root.title
                font.pixelSize: 18
                font.bold: true
                color: "#ffffff"
                Layout.fillWidth: true
            }

            Button {
                text: qsTr("New Connection")
                font.pixelSize: 13

                background: Rectangle {
                    color: parent.pressed ? "#0056b3" : (parent.hovered ? "#007AFF" : "#0066cc")
                    radius: 4
                }

                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }

                onClicked: {
                    newConnectionDialog.open()
                }
            }
        }
    }

    contentItem: Item {
        implicitWidth: 680
        implicitHeight: 400

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Connections List
            ListView {
                id: connectionsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8

                model: ListModel {
                    id: connectionsModel
                }

                delegate: ConnectionItem {
                    width: connectionsList.width

                    connectionId: model.id
                    connectionName: model.name
                    connectionType: model.type
                    connectionStatus: model.status

                    onStartClicked: function(connId) {
                        Backend.start_connection(connId)
                    }

                    onStopClicked: function(connId) {
                        Backend.stop_connection(connId)
                    }

                    onEditClicked: function(connId) {
                        var details = Backend.get_connection_details(connId)
                        if(details && details.id) {
                            editConnectionDialog.loadConnection(
                                details.id,
                                details.name,
                                details.type,
                                details.settings
                            )
                            editConnectionDialog.open()
                        }
                    }

                    onDeleteClicked: function(connId) {
                        deleteConfirmDialog.connectionId = connId
                        deleteConfirmDialog.connectionName = model.name
                        deleteConfirmDialog.open()
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                // Empty state
                Label {
                    anchors.centerIn: parent
                    visible: connectionsList.count === 0
                    text: qsTr("No connections yet.\nClick 'New Connection' to create one.")
                    font.pixelSize: 14
                    color: "#808080"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Status bar
            Rectangle {
                Layout.fillWidth: true
                height: 30
                color: "#3d3d3d"
                radius: 4

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Total connections: %1").arg(connectionsList.count)
                    font.pixelSize: 12
                    color: "#cccccc"
                }
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            text: qsTr("Close")
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole

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

    // New Connection Dialog
    NewConnectionDialog {
        id: newConnectionDialog
        parent: Overlay.overlay
        anchors.centerIn: parent

        onConnectionCreated: function(connectionId) {
            Logger.log_info("Connection created: " + connectionId)
            refreshConnections()
        }
    }

    // Edit Connection Dialog
    EditConnectionDialog {
        id: editConnectionDialog
        parent: Overlay.overlay
        anchors.centerIn: parent

        onConnectionUpdated: function(connectionId) {
            Logger.log_info("Connection updated: " + connectionId)
            refreshConnections()
        }
    }

    // Delete Confirmation Dialog
    Dialog {
        id: deleteConfirmDialog

        property string connectionId: ""
        property string connectionName: ""

        title: qsTr("Delete Connection")
        modal: true
        standardButtons: Dialog.Yes | Dialog.No

        parent: Overlay.overlay
        anchors.centerIn: parent

        background: Rectangle {
            color: "#2d2d2d"
            border.color: "#4d4d4d"
            border.width: 1
            radius: 8
        }

        Label {
            text: qsTr("Are you sure you want to delete connection '%1'?").arg(deleteConfirmDialog.connectionName)
            color: "#ffffff"
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            if(Backend.delete_connection(deleteConfirmDialog.connectionId)) {
                Logger.log_info("Connection deleted: " + deleteConfirmDialog.connectionId)
                refreshConnections()
            }
        }
    }

    // Backend connections
    Connections {
        target: Backend
        function onConnections_changed(connections) {
            refreshConnections()
        }

        function onConnection_status_changed(connectionId, status, details) {
            // Update specific connection in model
            for(var i = 0; i < connectionsModel.count; i++) {
                if(connectionsModel.get(i).id === connectionId) {
                    connectionsModel.setProperty(i, "status", status)
                    break
                }
            }
        }
    }

    // Functions
    function refreshConnections() {
        var connections = Backend.get_connections()
        connectionsModel.clear()

        for(var i = 0; i < connections.length; i++) {
            connectionsModel.append({
                "id": connections[i].id,
                "name": connections[i].name,
                "type": connections[i].type,
                "status": connections[i].status
            })
        }
    }

    /**
     * Open the dialog and directly show edit settings for a specific connection
     * @param connectionId - The ID of the connection to edit
     */
    function openAndEditConnection(connectionId) {
        // Open the main dialog first
        root.open()

        // Wait a frame for dialog to be visible, then open edit dialog
        Qt.callLater(function() {
            var details = Backend.get_connection_details(connectionId)
            if(details && details.id) {
                editConnectionDialog.loadConnection(
                    details.id,
                    details.name,
                    details.type,
                    details.settings
                )
                editConnectionDialog.open()
            } else {
                Logger.log_error("ConnectionManagerDialog: Could not load connection details for " + connectionId)
            }
        })
    }

    onAboutToShow: {
        refreshConnections()
    }
}
