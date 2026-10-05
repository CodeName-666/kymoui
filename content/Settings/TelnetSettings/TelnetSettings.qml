import QtQuick 6.4
import QtQuick.Controls 6.4
import Common 1.0

TelnetSettingsUi {


    /*******************************************************************
     * FUNCTION - Get settings with validation
     ******************************************************************/
    function getSettings()
    {
        const host = ipInput.text.trim()
        const port = parseInt(portInput.text)

        // Validate host
        if(!Validators.isValidHost(host)) {
            Logger.log_error("TelnetSettings: Invalid host address: " + host)
            return {
                "host": host,
                "port": isNaN(port) ? 23 : port,
                "valid": false,
                "error": "Invalid host address. Must be valid IP or hostname."
            }
        }

        // Validate port
        if(!Validators.isValidPort(port)) {
            Logger.log_error("TelnetSettings: Invalid port number: " + portInput.text)
            return {
                "host": host,
                "port": port,
                "valid": false,
                "error": "Invalid port number. Must be between 1 and 65535."
            }
        }

        Logger.log_info("TelnetSettings: Valid settings - Host: " + host + ", Port: " + port)
        return {
            "host": host,
            "port": port,
            "valid": true
        }
    }


    /*******************************************************************
     * FUNCTION
     ******************************************************************/
    function setSettings(settings)
    {
        if(!Validators.isValid(settings))
            return
        ipInput.text = Validators.getProperty(settings, "host",
                       Validators.getProperty(settings, "ip", ""))
        portInput.text = Validators.getProperty(settings, "port", "23")
    }
}
