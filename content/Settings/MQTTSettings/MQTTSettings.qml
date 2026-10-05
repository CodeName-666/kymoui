import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0

MQTTSettingsUi {

    /*******************************************************************
     * FUNCTION - Get settings with validation
     ******************************************************************/
    function getSettings()
    {
        if(!Validators.isValid(hostInput))
            return {}

        const host = hostInput.text.trim()
        const portVal = parseInt(portInput.text)
        const qosVal = parseInt(qosCombo.currentValue !== undefined ? qosCombo.currentValue : qosCombo.currentText)
        const keepAliveVal = parseInt(keepAliveInput.text)
        const rxTopic = rxTopicInput.text.trim()
        const txTopic = txTopicInput.text.trim()

        // Validate host
        if(!Validators.isValidHost(host)) {
            Logger.log_error("MQTTSettings: Invalid host address: " + host)
            return {
                "valid": false,
                "error": "Invalid host address. Must be valid IP or hostname."
            }
        }

        // Validate port
        if(!Validators.isValidPort(portVal)) {
            Logger.log_error("MQTTSettings: Invalid port number: " + portInput.text)
            return {
                "valid": false,
                "error": "Invalid port number. Must be between 1 and 65535."
            }
        }

        // Validate MQTT topics
        if(!Validators.isValidMQTTTopic(rxTopic)) {
            Logger.log_error("MQTTSettings: Invalid RX topic: " + rxTopic)
            return {
                "valid": false,
                "error": "Invalid RX topic. Topic cannot be empty."
            }
        }

        if(!Validators.isValidMQTTTopic(txTopic)) {
            Logger.log_error("MQTTSettings: Invalid TX topic: " + txTopic)
            return {
                "valid": false,
                "error": "Invalid TX topic. Topic cannot be empty."
            }
        }

        // Validate QoS (0, 1, or 2)
        if(isNaN(qosVal) || qosVal < 0 || qosVal > 2) {
            Logger.log_error("MQTTSettings: Invalid QoS value: " + qosVal)
            return {
                "valid": false,
                "error": "Invalid QoS. Must be 0, 1, or 2."
            }
        }

        Logger.log_info("MQTTSettings: Valid settings - Host: " + host + ", Port: " + portVal)
        return {
            "host": host,
            "port": portVal,
            "rx_topic": rxTopic,
            "tx_topic": txTopic,
            "client_id": clientIdInput.text,
            "username": usernameInput.text,
            "password": passwordInput.text,
            "qos": qosVal,
            "keepalive": isNaN(keepAliveVal) ? 60 : keepAliveVal,
            "valid": true
        }
    }

    /*******************************************************************
     * FUNCTION
     ******************************************************************/
    function setSettings(settings)
    {
        if(!Validators.isValid(settings) || !Validators.isValid(hostInput))
            return
        hostInput.text = Validators.getProperty(settings, "host", "")
        portInput.text = Validators.getProperty(settings, "port", "1883")
        rxTopicInput.text = Validators.getProperty(settings, "rx_topic", "")
        txTopicInput.text = Validators.getProperty(settings, "tx_topic", "")
        clientIdInput.text = Validators.getProperty(settings, "client_id", "")
        usernameInput.text = Validators.getProperty(settings, "username", "")
        passwordInput.text = Validators.getProperty(settings, "password", "")
        setCombobox(qosCombo, Validators.getProperty(settings, "qos", 0))
        keepAliveInput.text = Validators.getProperty(settings, "keepalive", 60)
    }

    function setCombobox(combobox, value)
    {
        var idx = combobox.find(value, Qt.MatchExactly)
        if(idx >= 0)
            combobox.currentIndex = idx
    }
}
