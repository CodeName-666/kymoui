import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import "../StatusIndicator"
import "../Theme"

Rectangle {
    color: AppTheme.surfaces.card
    border.color: AppTheme.borders.primary
    height: 38

    property alias keepAliveStatus: keepAliveStatus
    property alias keepAliveInfoText: keepAliveInfo.text

    function showStatus(level, message) {
        if(message !== undefined)
            keepAliveInfo.text = message
        var lvl = level !== undefined ? level.toLowerCase() : "info"
        switch(lvl) {
        case "error":
            keepAliveStatus.set_status(keepAliveStatus.Status.DISCONNECTED)
            break
        case "warning":
            keepAliveStatus.set_status(keepAliveStatus.Status.WAITING)
            break
        case "success":
        case "info":
            keepAliveStatus.set_status(keepAliveStatus.Status.CONNECTED)
            break
        default:
            keepAliveStatus.set_status(keepAliveStatus.Status.OFF)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Label {
            id: keepAliveInfo
            Layout.fillHeight: true
            text: "Ready"
            color: AppTheme.text.secondary
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Item { Layout.fillWidth: true }

        StatusIndicator {
            id: keepAliveStatus
            Layout.preferredHeight: 20
            Layout.preferredWidth: 20
        }
    }
}
