import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Theme 1.0

// Compact, modern zoom controls that appear on hover
Rectangle {
    id: root

    // Signals for zoom operations
    signal zoomIn()
    signal zoomOut()
    signal zoomReset()
    signal zoomFit()

    property bool expanded: false
    property int buttonSize: 32

    color: Qt.rgba(20 / 255, 26 / 255, 36 / 255, 0.85)
    radius: 6
    border.color: AppTheme.borders.primary
    border.width: 1

    // Auto-hide on mouse exit
    opacity: mouseArea.containsMouse || expanded ? 1.0 : 0.3

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // Size follows content so additional buttons are not clipped
    implicitWidth: controlsRow.implicitWidth + 12
    implicitHeight: controlsRow.implicitHeight + 12
    width: implicitWidth
    height: implicitHeight

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
    }

    RowLayout {
        id: controlsRow
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // Zoom In
        ToolButton {
            id: zoomInBtn
            text: "+"
            font.pixelSize: 18
            font.bold: true
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            ToolTip.visible: hovered
            ToolTip.text: qsTr("Zoom In (X+Y, Ctrl++)")
            ToolTip.delay: 500

            background: Rectangle {
                color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                radius: 4
                border.color: parent.hovered ? AppTheme.borders.subtle : "transparent"
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: AppTheme.text.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.zoomIn()
        }

        // Zoom Out
        ToolButton {
            id: zoomOutBtn
            text: "−"
            font.pixelSize: 18
            font.bold: true
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            ToolTip.visible: hovered
            ToolTip.text: qsTr("Zoom Out (X+Y, Ctrl+−)")
            ToolTip.delay: 500

            background: Rectangle {
                color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                radius: 4
                border.color: parent.hovered ? AppTheme.borders.subtle : "transparent"
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: AppTheme.text.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.zoomOut()
        }

        // Separator
        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: buttonSize - 8
            Layout.alignment: Qt.AlignVCenter
            color: AppTheme.borders.subtle
        }

        // Reset Zoom
        ToolButton {
            id: resetBtn
            text: "⊡"
            font.pixelSize: 16
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            ToolTip.visible: hovered
            ToolTip.text: qsTr("Reset Zoom (Ctrl+0)")
            ToolTip.delay: 500

            background: Rectangle {
                color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                radius: 4
                border.color: parent.hovered ? AppTheme.borders.subtle : "transparent"
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: AppTheme.text.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.zoomReset()
        }

        // Fit to View
        ToolButton {
            id: fitBtn
            text: "⛶"
            font.pixelSize: 14
            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            ToolTip.visible: hovered
            ToolTip.text: qsTr("Fit to View (Ctrl+F)")
            ToolTip.delay: 500

            background: Rectangle {
                color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                radius: 4
                border.color: parent.hovered ? AppTheme.borders.subtle : "transparent"
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: AppTheme.text.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.zoomFit()
        }
    }
}
