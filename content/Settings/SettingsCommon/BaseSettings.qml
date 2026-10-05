import QtQuick 6.4
import Common 1.0
import Backend 1.0

Item {
    id: baseSettings

    // All interface settings should implement these functions
    function getSettings() {
        Logger.log_error("BaseSettings: getSettings() not implemented in derived component")
        return {
            "valid": false,
            "error": "Not implemented"
        }
    }

    function setSettings(settings) {
        Logger.log_warning("BaseSettings: setSettings() not implemented in derived component")
    }

    function isValid() {
        var settings = getSettings()
        return settings && settings.valid !== false
    }

    // Helper function: Set combobox by value with optional role
    function setCombobox(combobox, value, role) {
        if(!Validators.isValid(combobox) || value === undefined || value === null)
            return false

        var matchRole = role !== undefined ? role : "text"
        var idx = -1

        // Try to find by role
        if(matchRole === "value" && combobox.valueRole !== undefined) {
            idx = combobox.indexOfValue(value)
        } else {
            idx = combobox.find(value, Qt.MatchExactly)
        }

        if(idx >= 0) {
            combobox.currentIndex = idx
            return true
        }

        Logger.log_warning("BaseSettings: Could not find value '" + value + "' in combobox")
        return false
    }

    // Helper function: Get current value or text from combobox
    function getComboboxValue(combobox, preferValue) {
        if(!Validators.isValid(combobox))
            return undefined

        if(preferValue === true && combobox.currentValue !== undefined) {
            return combobox.currentValue
        }
        return combobox.currentText
    }

    // Helper function: Validate and parse integer
    function parseInteger(text, defaultValue) {
        if(!text || text === "")
            return defaultValue !== undefined ? defaultValue : 0

        var val = parseInt(text)
        return isNaN(val) ? (defaultValue !== undefined ? defaultValue : 0) : val
    }

    // Helper function: Safe property getter
    function getProperty(obj, key, defaultValue) {
        return Validators.getProperty(obj, key, defaultValue)
    }

    // Helper function: Standard settings validation result
    function validationResult(valid, error, settings) {
        var result = settings || {}
        result.valid = valid
        if(!valid && error)
            result.error = error
        return result
    }
}
