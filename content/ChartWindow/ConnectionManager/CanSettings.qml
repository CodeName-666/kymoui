import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15

ScrollView {
    id: root

    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: root.availableWidth
        spacing: 12

        Label {
            text: qsTr("CAN backend") + " *"
            color: "#ffffff"
            font.bold: true
        }

        ComboBox {
            id: interfaceCombo
            Layout.fillWidth: true
            editable: true
            model: ["virtual", "socketcan", "pcan", "vector", "kvaser", "ixxat", "slcan"]
            currentIndex: 0
        }

        Label {
            text: qsTr("Channel") + " *"
            color: "#ffffff"
            font.bold: true
        }

        TextField {
            id: channelField
            Layout.fillWidth: true
            text: "plotter"
            placeholderText: qsTr("e.g. can0, PCAN_USBBUS1 or plotter")
            color: "#ffffff"
        }

        Label {
            text: qsTr("Bitrate")
            color: "#ffffff"
            font.bold: true
        }

        TextField {
            id: bitrateField
            Layout.fillWidth: true
            text: "500000"
            validator: IntValidator { bottom: 1 }
            color: "#ffffff"
        }

        Label {
            text: qsTr("Payload format")
            color: "#ffffff"
            font.bold: true
        }

        ComboBox {
            id: valueFormatCombo
            Layout.fillWidth: true
            model: [
                "auto", "float32_le", "float32_be", "float64_le", "float64_be",
                "uint_le", "uint_be", "int_le", "int_be"
            ]
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 6

            Label { text: qsTr("Scale"); color: "#ffffff" }
            TextField {
                id: scaleField
                Layout.fillWidth: true
                text: "1.0"
                validator: DoubleValidator {}
                color: "#ffffff"
            }

            Label { text: qsTr("Offset"); color: "#ffffff" }
            TextField {
                id: offsetField
                Layout.fillWidth: true
                text: "0.0"
                validator: DoubleValidator {}
                color: "#ffffff"
            }

            Label { text: qsTr("Data ID (optional)"); color: "#ffffff" }
            TextField {
                id: dataIdField
                Layout.fillWidth: true
                placeholderText: qsTr("Otherwise CAN ID modulo 256")
                validator: IntValidator { bottom: 0; top: 255 }
                color: "#ffffff"
            }

            Label { text: qsTr("TX CAN ID (optional)"); color: "#ffffff" }
            TextField {
                id: txIdField
                Layout.fillWidth: true
                placeholderText: qsTr("e.g. 0x123")
                color: "#ffffff"
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Auto decodes 4-byte payloads as Float32, 8-byte payloads as Float64, and other lengths as unsigned integers.")
            color: "#a0a0a0"
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }

    function loadDefaults(defaults) {
        var backendName = defaults.interface || defaults.bustype || "virtual"
        var backendIndex = interfaceCombo.find(backendName)
        if (backendIndex >= 0)
            interfaceCombo.currentIndex = backendIndex
        else
            interfaceCombo.editText = backendName

        if (defaults.channel !== undefined) channelField.text = defaults.channel.toString()
        if (defaults.bitrate !== undefined) bitrateField.text = defaults.bitrate.toString()
        if (defaults.value_format) {
            var formatIndex = valueFormatCombo.find(defaults.value_format)
            if (formatIndex >= 0) valueFormatCombo.currentIndex = formatIndex
        }
        if (defaults.scale !== undefined) scaleField.text = defaults.scale.toString()
        if (defaults.offset !== undefined) offsetField.text = defaults.offset.toString()
        dataIdField.text = defaults.data_id !== undefined && defaults.data_id !== null ? defaults.data_id.toString() : ""
        txIdField.text = defaults.tx_id !== undefined && defaults.tx_id !== null ? defaults.tx_id.toString() : ""
    }

    function getSettings() {
        var settings = {
            "interface": interfaceCombo.currentText.trim(),
            "channel": channelField.text.trim(),
            "bitrate": parseInt(bitrateField.text),
            "value_format": valueFormatCombo.currentText,
            "scale": parseFloat(scaleField.text),
            "offset": parseFloat(offsetField.text)
        }
        if (dataIdField.text.trim() !== "") settings.data_id = parseInt(dataIdField.text)
        if (txIdField.text.trim() !== "") settings.tx_id = txIdField.text.trim()
        return settings
    }
}
