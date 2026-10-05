import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Backend 1.0
import "../Theme"

Rectangle {
    id: connectionCard

    // Properties
    property string connectionId: ""
    property string interfaceType: ""
    property string displayName: ""
    property string status: "disconnected"  // disconnected, connecting, connected
    property var connectionSettings: ({})

    // Signals
    signal startClicked(string connectionId)
    signal stopClicked(string connectionId)
    signal settingsClicked(string connectionId, string interfaceType)
    signal deleteClicked(string connectionId)

    // Styling
    radius: 6
    color: mouseArea.containsMouse ? Qt.lighter(AppTheme.surfaces.card, 1.08) : AppTheme.surfaces.card
    border.color: status === "connected" ? AppTheme.palette.success : AppTheme.borders.primary
    border.width: status === "connected" ? 2 : 1

    implicitHeight: contentLayout.implicitHeight + 16
    implicitWidth: parent ? parent.width : 300

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: {
            // Allow clicks to propagate to buttons
            mouse.accepted = false
        }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Status Indicator
        Rectangle {
            id: statusIndicator
            Layout.alignment: Qt.AlignVCenter
            width: 12
            height: 12
            radius: 6
            color: {
                switch(status) {
                    case "connected": return AppTheme.palette.success
                    case "connecting": return AppTheme.palette.warning
                    case "disconnected":
                    default: return AppTheme.text.disabled
                }
            }

        }

        // Connection Info
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Label {
                id: nameLabel
                text: displayName
                font.bold: true
                font.pixelSize: 13
                color: AppTheme.text.primary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                id: typeLabel
                text: interfaceType + " · " + (
                    status === "connected" ? qsTr("Connected")
                    : status === "connecting" ? qsTr("Connecting…")
                    : qsTr("Disconnected"))
                font.pixelSize: 10
                color: AppTheme.text.secondary
                visible: interfaceType !== ""
            }
        }

        // Action Buttons
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            // Start/Stop Button
            Button {
                id: actionButton
                text: {
                    switch(status) {
                        case "connected": return qsTr("Stop")
                        case "connecting": return qsTr("Connecting…")
                        case "disconnected":
                        default: return qsTr("Start")
                    }
                }
                enabled: status !== "connecting"
                Layout.preferredWidth: status === "connecting" ? 88 : 60
                Layout.preferredHeight: 28

                onClicked: {
                    if (status === "connected") {
                        stopClicked(connectionId)
                    } else {
                        startClicked(connectionId)
                    }
                }

                background: Rectangle {
                    radius: 4
                    color: {
                        if (!actionButton.enabled) return AppTheme.states.disabledBackground
                        if (actionButton.pressed) return status === "connected" ? Qt.darker(AppTheme.palette.danger, 1.2) : AppTheme.palette.primaryPressed
                        if (actionButton.hovered) return status === "connected" ? Qt.lighter(AppTheme.palette.danger, 1.1) : AppTheme.palette.primaryHover
                        return status === "connected" ? AppTheme.palette.danger : AppTheme.palette.primary
                    }
                    border.color: {
                        if (!actionButton.enabled) return AppTheme.borders.disabled
                        if (actionButton.activeFocus) return AppTheme.borders.focus
                        return status === "connected" ? Qt.darker(AppTheme.palette.danger, 1.2) : AppTheme.palette.primaryBorder
                    }
                    border.width: actionButton.activeFocus ? 2 : 1
                }

                contentItem: Text {
                    text: actionButton.text
                    font: actionButton.font
                    color: actionButton.enabled ? AppTheme.text.primary : AppTheme.text.disabled
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Settings Button
            Button {
                id: settingsButton
                text: qsTr("Edit")
                Layout.preferredWidth: 42
                Layout.preferredHeight: 28
                font.pixelSize: 14

                onClicked: {
                    settingsClicked(connectionId, interfaceType)
                }

                ToolTip.visible: hovered
                ToolTip.text: qsTr("Settings")
                ToolTip.delay: 500
                background: Rectangle {
                    radius: 4
                    color: settingsButton.hovered ? AppTheme.surfaces.muted : "transparent"
                    border.color: settingsButton.activeFocus ? AppTheme.borders.focus
                        : settingsButton.hovered ? AppTheme.borders.primary : AppTheme.borders.subtle
                    border.width: settingsButton.activeFocus ? 2 : 1
                }
            }

            // Delete Button (only visible when disconnected)
            Button {
                id: deleteButton
                text: qsTr("Delete")
                visible: status === "disconnected"
                Layout.preferredWidth: 54
                Layout.preferredHeight: 28
                font.pixelSize: 14

                onClicked: {
                    deleteConfirmDialog.open()
                }

                ToolTip.visible: hovered
                ToolTip.text: qsTr("Delete")
                ToolTip.delay: 500

                background: Rectangle {
                    radius: 4
                    color: {
                        if (deleteButton.pressed) return Qt.darker(AppTheme.palette.danger, 1.2)
                        if (deleteButton.hovered) return AppTheme.palette.danger
                        return "transparent"
                    }
                    border.color: deleteButton.activeFocus ? AppTheme.borders.focus
                        : deleteButton.hovered ? AppTheme.palette.danger : AppTheme.borders.primary
                    border.width: deleteButton.activeFocus ? 2 : 1
                }
            }
        }
    }

    // Delete Confirmation Dialog
    Dialog {
        id: deleteConfirmDialog
        title: qsTr("Delete Connection")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        width: 300
        height: 150

        contentItem: ColumnLayout {
            spacing: 12
            anchors.fill: parent
            anchors.margins: 16

            Label {
                text: qsTr("Are you sure you want to delete this connection?")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: displayName
                font.bold: true
                color: AppTheme.palette.danger
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
            }
        }

        onAccepted: {
            deleteClicked(connectionId)
        }
    }

    Component.onCompleted: {
        Logger.log_debug("ConnectionCard created: " + connectionId + " (" + displayName + ")")
    }
}
