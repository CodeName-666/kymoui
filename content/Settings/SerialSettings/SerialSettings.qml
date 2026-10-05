import QtQuick 6.4
import QtQuick.Controls 6.4
import Backend 1.0
import Common 1.0
import SettingsCommon 1.0

SerialSettingsUi {

    // Inherit from BaseSettings via property
    property var baseHelper: BaseSettings {}

    function getSettings() {
        const port = comComboBox.currentText
        const baud = baseHelper.parseInteger(baudInput.text, 0)
        const size = baseHelper.getComboboxValue(dataSizeComboBox, true)
        const parity = baseHelper.getComboboxValue(parityComboBox, true)
        const stopBits = baseHelper.getComboboxValue(stopBitsCombo, true)

        // Validate port
        if(!port || port === "") {
            Logger.log_error("SerialSettings: No COM port selected")
            return baseHelper.validationResult(false, "Please select a COM port")
        }

        // Validate baudrate
        if(baud <= 0 || baud > 921600) {
            Logger.log_error("SerialSettings: Invalid baudrate: " + baud)
            return baseHelper.validationResult(false, "Baudrate must be between 1 and 921600")
        }

        // Check common baudrates
        var commonBaudrates = [300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]
        if(commonBaudrates.indexOf(baud) === -1) {
            Logger.log_warning("SerialSettings: Unusual baudrate: " + baud)
        }

        Logger.log_info("SerialSettings: Valid settings - Port: " + port + ", Baud: " + baud)
        return baseHelper.validationResult(true, "", {
            "port": port,
            "baud": baud,
            "size": size,
            "parity": parity,
            "stop_bits": stopBits
        })
    }

    function setSettings(settings) {
        if(!Validators.isValid(settings))
            return

        baseHelper.setCombobox(comComboBox, baseHelper.getProperty(settings, "port", ""), "text")
        baudInput.text = baseHelper.getProperty(settings, "baud", "9600")
        baseHelper.setCombobox(dataSizeComboBox, baseHelper.getProperty(settings, "size", 8), "value")
        baseHelper.setCombobox(parityComboBox, baseHelper.getProperty(settings, "parity", 0), "value")
        baseHelper.setCombobox(stopBitsCombo, baseHelper.getProperty(settings, "stop_bits",
                                                baseHelper.getProperty(settings, "stop", 1)), "value")
    }

    function isValid() {
        var settings = getSettings()
        return settings.valid === true
    }
}
