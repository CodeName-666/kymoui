import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.11

import PlotterUi 1.0
import DataModels.SerialDataModels 1.0
import Common 1.0
import Theme 1.0


ToolBar {

    property alias menuButton: menuButton

    width: Constants.width
    height: 52

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: AppTheme.surfaces.interfaceBackground }
            GradientStop { position: 1.0; color: AppTheme.surfaces.card }
        }
        border.color: AppTheme.borders.primary
        border.width: 1
    }

    RowLayout {
        id: rlayout
        anchors.fill: parent
        spacing: 0

        ToolButton {
            id: menuButton
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: 56
            text: "\u2630" // simple menu glyph
            font.pixelSize: 18

            ToolTip.visible: hovered
            ToolTip.text: qsTr("Data sources and application menu")
            ToolTip.delay: 400

            background: Rectangle {
                radius: 10
                color: menuButton.pressed ? AppTheme.palette.primaryPressed :
                       menuButton.hovered ? AppTheme.palette.primaryHover :
                       "transparent"
                border.color: menuButton.activeFocus ? AppTheme.borders.focus
                    : menuButton.hovered ? AppTheme.palette.primaryBorder : "transparent"
                border.width: menuButton.activeFocus ? 2 : 1
            }

            contentItem: Text {
                text: menuButton.text
                font: menuButton.font
                color: AppTheme.text.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        Label {
            Layout.fillWidth: true
            text: qsTr(Constants.title)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: 16
            color: AppTheme.text.primary
        }
    }
}



