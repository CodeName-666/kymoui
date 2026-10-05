import QtQuick 6.4
import QtQuick.Controls 6.4
import Common 1.0
import SettingsCommon 1.0

TestSettingUi {

    property var baseHelper: BaseSettings {}

    colorDialog.onAccepted: {
        colorView.color = colorDialog.selectedColor
        colorDialog.close()
    }

    colorDialog.onRejected: colorDialog.close()

    colorButton.onClicked: colorDialog.open()

    function getSettings() {
        const name = nameInput.text.trim()
        const color = colorView.color
        const type = typeCombo.currentText

        // Validate name
        if(!name || name === "") {
            Logger.log_error("TestSettings: Name cannot be empty")
            return baseHelper.validationResult(false, "Please enter a name for the test")
        }

        // Validate color (check if it's a valid color)
        if(!color || color.toString() === "#00000000" || color.toString() === "#00ffffff") {
            Logger.log_error("TestSettings: Invalid color selected")
            return baseHelper.validationResult(false, "Please select a color")
        }

        // Validate type
        if(!type || type === "") {
            Logger.log_error("TestSettings: No line type selected")
            return baseHelper.validationResult(false, "Please select a line type")
        }

        Logger.log_info("TestSettings: Valid settings - Name: " + name + ", Type: " + type)
        return baseHelper.validationResult(true, "", {
            "name": name,
            "color": color,
            "type": type
        })
    }

    function setSettings(settings) {
        if(!Validators.isValid(settings))
            return

        nameInput.text = baseHelper.getProperty(settings, "name", "")
        var settingsColor = baseHelper.getProperty(settings, "color", "#ff4444")
        colorView.color = settingsColor
        baseHelper.setCombobox(typeCombo, baseHelper.getProperty(settings, "type", "Multi"), "text")
    }

    function isValid() {
        var settings = getSettings()
        return settings.valid === true
    }
}
