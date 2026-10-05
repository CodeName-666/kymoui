import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0

Rectangle {
    id: root

    // Properties
    property string connectionId: ""
    property string connectionName: "Unknown Connection"
    property string connectionType: "Unknown"
    property string connectionStatus: "disconnected"  // disconnected, connecting, connected

    // Signals
    signal startClicked(string connectionId)
    signal stopClicked(string connectionId)
    signal editClicked(string connectionId)
    signal deleteClicked(string connectionId)

    height: 70
    color: "#3d3d3d"
    radius: 6
    border.color: connectionStatus === "connected" ? "#28a745" : (connectionStatus === "connecting" ? "#ffc107" : "#606060")
    border.width: 2

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Status Indicator
        Rectangle {
            width: 12
            height: 12
            radius: 6
            color: {
                switch(root.connectionStatus) {
                    case "connected": return "#28a745"
                    case "connecting": return "#ffc107"
                    case "disconnected": return "#dc3545"
                    default: return "#808080"
                }
            }

            SequentialAnimation on opacity {
                running: root.connectionStatus === "connecting"
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.3; duration: 500 }
                NumberAnimation { from: 0.3; to: 1.0; duration: 500 }
            }
        }

        // Connection Info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                text: root.connectionName
                font.pixelSize: 14
                font.bold: true
                color: "#ffffff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("%1 - %2").arg(root.connectionType).arg(getStatusText())
                font.pixelSize: 11
                color: "#b0b0b0"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Control Buttons
        RowLayout {
            spacing: 8

            // Start/Stop Button
            Button {
                id: toggleButton
                width: 80
                height: 32

                text: root.connectionStatus === "connected" ? qsTr("Stop") : qsTr("Start")
                enabled: root.connectionStatus !== "connecting"

                background: Rectangle {
                    color: {
                        if(!parent.enabled) return "#5d5d5d"
                        if(parent.pressed) return root.connectionStatus === "connected" ? "#c82333" : "#0056b3"
                        if(parent.hovered) return root.connectionStatus === "connected" ? "#dc3545" : "#007AFF"
                        return root.connectionStatus === "connected" ? "#bd2130" : "#0066cc"
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

                onClicked: {
                    if(root.connectionStatus === "connected") {
                        root.stopClicked(root.connectionId)
                    } else {
                        root.startClicked(root.connectionId)
                    }
                }
            }

            // Edit Button
            Button {
                width: 32
                height: 32

                background: Rectangle {
                    color: parent.pressed ? "#4d4d4d" : (parent.hovered ? "#5d5d5d" : "#3d3d3d")
                    radius: 4
                    border.color: "#606060"
                    border.width: 1
                }

                contentItem: Text {
                    text: "\u270E"  // Pencil icon
                    color: "#ffffff"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                ToolTip.visible: hovered
                ToolTip.text: qsTr("Edit Connection")
                ToolTip.delay: 500

                onClicked: {
                    root.editClicked(root.connectionId)
                }
            }

            // Delete Button
            Button {
                width: 32
                height: 32
                enabled: root.connectionStatus === "disconnected"

                background: Rectangle {
                    color: {
                        if(!parent.enabled) return "#5d5d5d"
                        if(parent.pressed) return "#a71d2a"
                        if(parent.hovered) return "#c82333"
                        return "#bd2130"
                    }
                    radius: 4
                    border.color: parent.enabled ? "#ffffff30" : "transparent"
                    border.width: 1
                }

                contentItem: Text {
                    text: "\u2715"  // X icon
                    color: parent.enabled ? "#ffffff" : "#a0a0a0"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                ToolTip.visible: hovered
                ToolTip.text: qsTr("Delete Connection")
                ToolTip.delay: 500

                onClicked: {
                    root.deleteClicked(root.connectionId)
                }
            }
        }
    }

    // Helper function to get status text
    function getStatusText() {
        switch(root.connectionStatus) {
            case "connected": return qsTr("Connected")
            case "connecting": return qsTr("Connecting...")
            case "disconnected": return qsTr("Disconnected")
            default: return qsTr("Unknown")
        }
    }
}
