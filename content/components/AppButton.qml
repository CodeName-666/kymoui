import QtQuick 6.4
import QtQuick.Controls 6.4
import "../Theme"

Button {
    id: control

    property color backgroundColor: AppTheme.palette.primary
    property color hoverBackgroundColor: AppTheme.palette.primaryHover
    property color pressedBackgroundColor: AppTheme.palette.primaryPressed
    property color disabledBackgroundColor: AppTheme.states.disabledBackground

    property color textColor: AppTheme.text.contrast
    property color disabledTextColor: AppTheme.text.disabled

    property color borderColor: AppTheme.palette.primaryBorder
    property color disabledBorderColor: AppTheme.borders.disabled

    property int cornerRadius: AppTheme.radius.small
    property real borderWidth: 1
    property int fontPixelSize: AppTheme.fontSize.button
    property bool boldText: true

    implicitHeight: Math.max(implicitBackgroundHeight + topPadding + bottomPadding, 38)
    focusPolicy: Qt.TabFocus
    padding: 12
    topPadding: 8
    bottomPadding: 8

    background: Rectangle {
        radius: control.cornerRadius
        color: !control.enabled ? control.disabledBackgroundColor
              : control.down ? control.pressedBackgroundColor
              : control.hovered ? control.hoverBackgroundColor
              : control.backgroundColor
        border.color: !control.enabled ? control.disabledBorderColor
            : control.activeFocus ? AppTheme.borders.focus
            : control.borderColor
        border.width: control.activeFocus ? Math.max(2, control.borderWidth) : control.borderWidth
    }

    contentItem: Label {
        text: control.text
        font.family: control.font.family
        font.bold: control.font.bold ? control.font.bold : control.boldText
        font.pixelSize: control.font.pixelSize > 0 ? control.font.pixelSize : control.fontPixelSize
        color: control.enabled ? control.textColor : control.disabledTextColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
