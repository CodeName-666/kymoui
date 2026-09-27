import QtQuick 6.4
import QtQuick.Dialogs
import Backend 1.0

SettingsUi {
    id: settings_menu

    FileDialog {
        id: saveConfigDialog
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON Config files (*.json)"]
        defaultSuffix: "json"
        onAccepted: settings_menu.saveConfigToFile(selectedFile)
    }

    FileDialog {
        id: loadConfigDialog
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON Config files (*.json)"]
        onAccepted: settings_menu.loadConfigFromFile(selectedFile)
    }

    Component.onCompleted: {
        Logger.log_debug("Settings: Component completed")
    }

    onVisibleChanged: {
        if (visible) {
            Logger.log_debug("Settings: Config Management Dialog opened")
        }
    }

    saveConfigButton.onClicked: {
        Logger.log_info("Settings: Save config button clicked")
        saveConfigDialog.open()
    }

    loadConfigButton.onClicked: {
        Logger.log_info("Settings: Load config button clicked")
        loadConfigDialog.open()
    }

    closeButton.onClicked: {
        Logger.log_debug("Settings: Close button clicked")
        settings_menu.visible = false
    }

    function saveConfigToFile(fileUrl) {
        Logger.log_info("Settings: Saving configuration to " + fileUrl)
        if (Backend.save_configuration_to_file(fileUrl)) {
            Logger.log_info("Settings: Configuration exported successfully")
        } else {
            Logger.log_error("Settings: Configuration export failed")
        }
    }

    function loadConfigFromFile(fileUrl) {
        Logger.log_info("Settings: Loading configuration from " + fileUrl)
        if (Backend.load_configuration_from_file(fileUrl)) {
            Logger.log_info("Settings: Configuration imported successfully")
        } else {
            Logger.log_error("Settings: Configuration import failed")
        }
    }
}
