import QtQuick 6.4
import QtQuick.Controls 6.4
import "../../Theme"

Item {
    id: root

    property alias icon: iconText.text
    property alias backgroundColor: background.color
    property alias iconColor: iconText.color
    property string label: qsTr("New chart")
    property int buttonHeight: 42

    signal clicked()

    width: 124
    height: buttonHeight

    Button {
        id: fabButton
        anchors.fill: parent

        background: Rectangle {
            id: background
            color: fabButton.down ? AppTheme.palette.primaryPressed
                : fabButton.hovered ? AppTheme.palette.primaryHover
                : AppTheme.palette.primary
            radius: AppTheme.radius.medium
            border.color: fabButton.activeFocus ? AppTheme.text.primary : AppTheme.palette.primaryBorder
            border.width: fabButton.activeFocus ? 2 : 1
        }

        contentItem: Row {
            spacing: 8
            anchors.centerIn: parent

            Text {
                id: iconText
                text: "+"
                font.pixelSize: 20
                font.bold: true
                color: AppTheme.text.contrast
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: root.label
                font.pixelSize: AppTheme.fontSize.button
                font.bold: true
                color: AppTheme.text.contrast
                verticalAlignment: Text.AlignVCenter
            }
        }

        onClicked: {
            root.clicked()
        }
    }
}
