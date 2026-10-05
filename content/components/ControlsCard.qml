import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import DataModels.SerialDataModels 1.0
import Backend 1.0

Rectangle {
    id: controlsCard
    radius: 6
    color: "#f4f4f4"
    border.color: "#d0d0d0"
    implicitHeight: contentLayout.implicitHeight + 20

    signal interfaceChanged(string iface)
    property alias startButton: startButton
    property alias stopButton: stopButton
    property alias sourceCombo: sourceCombo
    property var appController: null

    Component.onCompleted: {
        Logger.log_debug("ControlsCard completed. appController is: " + (appController ? "available" : "null"))
        updateInterfaceSettings()
    }

    onAppControllerChanged: {
        Logger.log_debug("ControlsCard: appController changed. Is now: " + (appController ? "available" : "null"))
        updateInterfaceSettings()
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: qsTr("Connection")
            font.bold: true
            color: "#444"
            Layout.fillWidth: true
        }
        Button {
            id: startButton
            text: qsTr("Start")
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            enabled: controlsCard.appController !== null && sourceCombo.currentIndex >= 0
            onClicked: {
                if (!controlsCard.appController.connect())
                    Logger.log_warning("ControlsCard: Could not start selected interface")
            }
        }
        Button {
            id: stopButton
            text: qsTr("Stop")
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            enabled: controlsCard.appController !== null && sourceCombo.currentIndex >= 0
            onClicked: {
                if (!controlsCard.appController.disconnect())
                    Logger.log_warning("ControlsCard: Could not stop selected interface")
            }
        }
        ComboBox {
            id: sourceCombo
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            model: ConnectionModel {}
            textRole: "name"
            valueRole: "val"
            currentIndex: model && model.count > 0 ? 0 : -1
            onCurrentIndexChanged: {
                if(sourceCombo.currentText !== undefined) {
                    Logger.log_debug("ControlsCard: Interface changed to: " + sourceCombo.currentText)
                    updateInterfaceSettings()
                }
            }
            Component.onCompleted: {
                Logger.log_debug("ControlsCard ComboBox completed. Current: " + sourceCombo.currentText + ", Model count: " + model.count)
            }
        }
    }

    // Central function to update interface settings - eliminates code duplication
    function updateInterfaceSettings() {
        if(!sourceCombo.currentText) {
            return
        }

        var interfaceName = sourceCombo.currentText

        // Set current_interface in appController
        if(appController) {
            appController.current_interface = interfaceName
            Logger.log_info("ControlsCard: Set appController.current_interface to: " + interfaceName)
        } else {
            Logger.log_warning("ControlsCard: appController is null, cannot set current_interface")
            return
        }

        // Emit signal for other listeners
        controlsCard.interfaceChanged(interfaceName)

        // Auto-set default settings for Test interface
        if(interfaceName === "Test") {
            Logger.log_debug("ControlsCard: Setting default Test settings")
            setDefaultTestSettings()
        }
    }

    function setDefaultTestSettings() {
        Logger.log_debug("ControlsCard: setDefaultTestSettings called")
        if(appController && typeof appController.set_settings === "function") {
            var defaultTestSettings = {
                "name": "Multi Test",
                "color": "#ff4444",
                "type": "Multi",
                "use_timestamp": true,
                "sample_ms": 50
            }
            Logger.log_info("ControlsCard: Setting Test interface with default settings: " + JSON.stringify(defaultTestSettings))
            appController.set_settings("Test", defaultTestSettings)
        } else {
            Logger.log_warning("ControlsCard: Cannot set Test settings - appController not available")
        }
    }
}
