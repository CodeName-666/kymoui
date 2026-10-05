import QtQuick 6.4
import QtQuick.Controls 6.4
import "../Theme"

TextField {
    id: control

    property color backgroundColor: AppTheme.inputs.background
    property color disabledBackgroundColor: AppTheme.inputs.disabledBackground
    property color borderColor: AppTheme.borders.primary
    property color focusBorderColor: AppTheme.borders.focus
    property color errorBorderColor: AppTheme.borders.danger
    property bool hasError: false

    property color textColor: AppTheme.text.primary
    property color placeholderTextColor: AppTheme.text.placeholder
    property int cornerRadius: AppTheme.radius.small
    property real baseBorderWidth: 1

    color: textColor
    leftPadding: 10
    rightPadding: 10
    topPadding: 8
    bottomPadding: 8
    font.pixelSize: 14

    background: Rectangle {
        radius: control.cornerRadius
        color: control.enabled ? control.backgroundColor : control.disabledBackgroundColor
        border.color: control.hasError ? control.errorBorderColor
                     : control.activeFocus ? control.focusBorderColor
                     : control.borderColor
        border.width: control.hasError || control.activeFocus ? control.baseBorderWidth + 1 : control.baseBorderWidth
    }

    placeholderTextColor: control.placeholderTextColor
}
