import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Backend 1.0
import Common 1.0

/**
 * @deprecated This component is deprecated and will be removed in a future release.
 * Use ConnectionManagerDialog (from ChartWindow/ConnectionManager) instead.
 * ConnectionManagerDialog provides a unified connection management interface
 * with support for creating, editing, and managing multiple connections.
 */
Dialog {
    id: connectionSettingsDialog

    // Properties
    property string connectionId: ""
    property string interfaceType: ""
    property string connectionName: ""

    // Internal state
    property var originalSettings: ({})
    property bool settingsLoaded: false

    title: qsTr("Settings: ") + connectionName
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.NoButton

    width: 600
    height: 500

    background: Rectangle {
        color: "#f5f5f5"
        border.color: "#d0d0d0"
        border.width: 1
        radius: 8
    }

    contentItem: ColumnLayout {
        spacing: 16
        anchors.fill: parent
        anchors.margins: 20

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                text: qsTr("Connection Settings")
                font.pixelSize: 18
                font.bold: true
                color: "#333"
                Layout.fillWidth: true
            }

            Label {
                text: interfaceType
                font.pixelSize: 12
                color: "#666"
                padding: 6
                background: Rectangle {
                    color: "#e3f2fd"
                    radius: 4
                    border.color: "#2196f3"
                    border.width: 1
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#e0e0e0"
        }

        // Settings Content Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: "white"
            border.color: "#e0e0e0"
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: 12
                clip: true

                Loader {
                    id: settingsLoader
                    width: parent.width

                    sourceComponent: {
                        switch(interfaceType) {
                            case "Serial": return serialComponent
                            case "Telnet": return telnetComponent
                            case "MQTT": return mqttComponent
                            case "Test": return testComponent
                            default: return null
                        }
                    }

                    onLoaded: {
                        Logger.log_debug("ConnectionSettingsDialog: Loader completed for " + interfaceType)
                        if (settingsLoaded) {
                            loadConnectionSettings()
                        }
                    }
                }
            }
        }

        // Status Message
        Label {
            id: statusMessageLabel
            text: ""
            font.pixelSize: 11
            color: "#f44336"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            visible: text !== ""
        }

        // Validation Indicator
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: settingsLoader.item !== null

            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: isValid() ? "#4caf50" : "#f44336"
            }

            Label {
                text: isValid() ? qsTr("Settings are valid") : qsTr("Settings have errors")
                font.pixelSize: 11
                color: isValid() ? "#4caf50" : "#f44336"
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#e0e0e0"
        }

        // Buttons
        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: qsTr("Cancel")
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36

                onClicked: {
                    Logger.log_info("ConnectionSettingsDialog: Cancelled")
                    restoreOriginalSettings()
                    connectionSettingsDialog.close()
                }

                background: Rectangle {
                    radius: 4
                    color: {
                        if (parent.pressed) return "#bdbdbd"
                        if (parent.hovered) return "#e0e0e0"
                        return "#f5f5f5"
                    }
                    border.color: "#bdbdbd"
                    border.width: 1
                }
            }

            Button {
                id: saveButton
                text: qsTr("Save")
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36
                enabled: isValid()

                onClicked: {
                    Logger.log_info("ConnectionSettingsDialog: Saving settings")
                    if (saveConnectionSettings()) {
                        connectionSettingsDialog.close()
                    }
                }

                background: Rectangle {
                    radius: 4
                    color: {
                        if (!saveButton.enabled) return "#e0e0e0"
                        if (saveButton.pressed) return "#1565c0"
                        if (saveButton.hovered) return "#1976d2"
                        return "#2196f3"
                    }
                    border.color: saveButton.enabled ? "#1565c0" : "#bdbdbd"
                    border.width: 1

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                contentItem: Text {
                    text: saveButton.text
                    font: saveButton.font
                    color: saveButton.enabled ? "white" : "#999"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // Settings Components
    Component {
        id: serialComponent
        Loader {
            source: "../Settings/SerialSettings/SerialSettings.qml"
            asynchronous: false
        }
    }

    Component {
        id: telnetComponent
        Loader {
            source: "../Settings/TelnetSettings/TelnetSettings.qml"
            asynchronous: false
        }
    }

    Component {
        id: mqttComponent
        Loader {
            source: "../Settings/MQTTSettings/MQTTSettings.qml"
            asynchronous: false
        }
    }

    Component {
        id: testComponent
        Loader {
            source: "../Settings/TestSettings/TestSettings.qml"
            asynchronous: false
        }
    }

    // Event Handlers
    onAboutToShow: {
        Logger.log_info("ConnectionSettingsDialog: About to show for connection " + connectionId)
        settingsLoaded = true
        loadConnectionSettings()
    }

    onAboutToHide: {
        Logger.log_debug("ConnectionSettingsDialog: About to hide")
        settingsLoaded = false
    }

    // Functions
    function loadConnectionSettings() {
        if (!connectionId || connectionId === "") {
            Logger.log_error("ConnectionSettingsDialog: No connection ID set")
            statusMessageLabel.text = qsTr("Error: No connection ID")
            return
        }

        // Wait for loader to be ready
        if (!settingsLoader.item) {
            Logger.log_debug("ConnectionSettingsDialog: Loader not ready yet, waiting...")
            return
        }

        Logger.log_debug("ConnectionSettingsDialog: Loading settings for connection " + connectionId)

        var details = Backend.get_connection_details(connectionId)
        if (!details || !details.settings) {
            Logger.log_error("ConnectionSettingsDialog: Could not get connection details for " + connectionId)
            statusMessageLabel.text = qsTr("Error: Could not load connection settings")
            return
        }

        Logger.log_debug("ConnectionSettingsDialog: Got settings: " + JSON.stringify(details.settings))

        // Store original settings for cancel operation
        originalSettings = JSON.parse(JSON.stringify(details.settings))

        // Apply settings to the loaded component
        var actualItem = settingsLoader.item

        // Handle nested Loader (if component returns a Loader)
        if (actualItem && actualItem.item) {
            actualItem = actualItem.item
        }

        if (actualItem && typeof actualItem.setSettings === "function") {
            actualItem.setSettings(details.settings)
            Logger.log_info("ConnectionSettingsDialog: Settings loaded successfully")
            statusMessageLabel.text = ""
        } else {
            Logger.log_error("ConnectionSettingsDialog: Loaded item does not have setSettings function")
            statusMessageLabel.text = qsTr("Error: Settings component not ready")
        }
    }

    function saveConnectionSettings() {
        if (!settingsLoader.item) {
            Logger.log_error("ConnectionSettingsDialog: No settings item loaded")
            statusMessageLabel.text = qsTr("Error: Settings not loaded")
            return false
        }

        var actualItem = settingsLoader.item

        // Handle nested Loader
        if (actualItem && actualItem.item) {
            actualItem = actualItem.item
        }

        if (!actualItem || typeof actualItem.getSettings !== "function") {
            Logger.log_error("ConnectionSettingsDialog: Settings item does not have getSettings function")
            statusMessageLabel.text = qsTr("Error: Cannot retrieve settings")
            return false
        }

        var settingsResult = actualItem.getSettings()

        if (!settingsResult || settingsResult.valid === false) {
            Logger.log_error("ConnectionSettingsDialog: Settings validation failed")
            statusMessageLabel.text = settingsResult && settingsResult.message ?
                settingsResult.message : qsTr("Settings validation failed")
            return false
        }

        // Extract actual settings (remove validation metadata)
        var settings = {}
        for (var key in settingsResult) {
            if (key !== "valid" && key !== "message") {
                settings[key] = settingsResult[key]
            }
        }

        Logger.log_info("ConnectionSettingsDialog: Saving settings: " + JSON.stringify(settings))

        var success = Backend.update_connection_settings(connectionId, settings)

        if (success) {
            Logger.log_info("ConnectionSettingsDialog: Settings saved successfully")
            statusMessageLabel.text = ""
            return true
        } else {
            Logger.log_error("ConnectionSettingsDialog: Failed to save settings")
            statusMessageLabel.text = qsTr("Failed to save settings. Check logs for details.")
            return false
        }
    }

    function restoreOriginalSettings() {
        if (!settingsLoader.item || !originalSettings) {
            return
        }

        var actualItem = settingsLoader.item

        // Handle nested Loader
        if (actualItem && actualItem.item) {
            actualItem = actualItem.item
        }

        if (actualItem && typeof actualItem.setSettings === "function") {
            actualItem.setSettings(originalSettings)
            Logger.log_debug("ConnectionSettingsDialog: Restored original settings")
        }
    }

    function isValid() {
        if (!settingsLoader.item) {
            return false
        }

        var actualItem = settingsLoader.item

        // Handle nested Loader
        if (actualItem && actualItem.item) {
            actualItem = actualItem.item
        }

        if (actualItem && typeof actualItem.isValid === "function") {
            return actualItem.isValid()
        }

        return false
    }

    // Connect to settings changes for real-time validation
    Connections {
        target: settingsLoader.item
        ignoreUnknownSignals: true

        function onTextChanged() {
            // Trigger validation update
            saveButton.enabled = Qt.binding(function() { return isValid() })
        }
    }
}
