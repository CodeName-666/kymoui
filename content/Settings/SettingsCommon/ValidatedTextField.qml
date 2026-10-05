import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import SettingsCommon 1.0
import "../../components"

ColumnLayout {
    id: validatedField

    property alias text: textField.text
    property alias placeholderText: textField.placeholderText
    property alias inputMethodHints: textField.inputMethodHints
    property string errorText: ""
    property bool hasError: errorText !== ""
    property var validator: null

    signal textChanged()
    signal editingFinished()

    spacing: SettingsTheme.spacing.small

    AppTextField {
        id: textField
        Layout.fillWidth: true
        Layout.preferredHeight: SettingsTheme.heights.input
        backgroundColor: SettingsTheme.cardBackground
        disabledBackgroundColor: SettingsTheme.interfaceBackground
        borderColor: SettingsTheme.borderColor
        focusBorderColor: SettingsTheme.highlightColor
        errorBorderColor: SettingsTheme.errorColor
        cornerRadius: SettingsTheme.radius.small
        hasError: validatedField.hasError

        onTextChanged: {
            validatedField.textChanged()
            validateInput()
        }

        onEditingFinished: validatedField.editingFinished()
    }

    Label {
        visible: hasError
        text: errorText
        color: SettingsTheme.errorColor
        font.pixelSize: SettingsTheme.fontSize.small
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    function validateInput() {
        if(validator && typeof validator === "function") {
            var result = validator(textField.text)
            errorText = result.valid ? "" : result.error
        }
    }
}
