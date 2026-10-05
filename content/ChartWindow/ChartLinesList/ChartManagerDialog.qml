import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Common 1.0

/**
 * ChartManagerDialog.qml
 *
 * Extended Chart Manager Dialog with larger view for detailed management
 * Opens as a separate window/dialog for better overview and control
 */
Window {
    id: dialogWindow

    title: qsTr("Chart Manager - Detailed View")
    width: 900
    height: 700
    minimumWidth: 700
    minimumHeight: 500
    modality: Qt.ApplicationModal
    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint

    // Signals forwarded to ChartWindow
    signal lineVisibilityToggled(string lineKey, bool visible)
    signal lineSelected(string lineKey)
    signal addSignalRequested()
    signal removeSignalRequested(string uniqueId)
    signal setSignalChartsRequested(string uniqueId, var assignments)
    signal createChartRequested(string chartType, string chartTitle, string chartId)
    signal removeChartRequested(string chartId)
    signal renameChartRequested(string chartId, string chartTitle)

    // Properties passed from ChartsManager
    property var chartLineModel: null
    property var signalModel: null
    property var messageModel: null
    property var availableCharts: []

    // Internal models
    ListModel { id: signalsModel }
    ListModel { id: chartsModel }
    ListModel { id: assignChartsModel }

    function _isXYChart(chartType) {
        // Used for enabling/disabling signal assignment per chart type
        return chartType === "xy_line" ||
               chartType === "xy_scatter" ||
               chartType === "time_series" ||
               chartType === "xyz_surface" ||
               chartType === "xyz_scatter"
    }

    function _getMessage(uniqueId) {
        if (!dialogWindow.messageModel || !dialogWindow.messageModel.getMessage) return null
        return dialogWindow.messageModel.getMessage(uniqueId)
    }

    function _getMessageDisplayName(uniqueId) {
        var msg = _getMessage(uniqueId)
        if (!msg) return uniqueId
        return msg.displayName || msg.uniqueId || uniqueId
    }

    function _hasMessageX(uniqueId) {
        var msg = _getMessage(uniqueId)
        return !!(msg && msg.x !== null && msg.x !== undefined)
    }

    function _generateChartId(chartType) {
        return "chart_" + chartType + "_" + Date.now() + "_" + Math.floor(Math.random() * 1000)
    }

    function _collectAssignments(uniqueId) {
        var assignments = []
        if (!dialogWindow.chartLineModel) return assignments
        for (var i = 0; i < dialogWindow.chartLineModel.count; i++) {
            var line = dialogWindow.chartLineModel.get(i)
            if (line.uniqueId !== uniqueId) continue
            if ((line.chartId || "main") === "main") continue
            var assignment = { "chartId": line.chartId }
            if (line.valueField) assignment.valueField = line.valueField
            assignments.push(assignment)
        }
        return assignments
    }

    function _requestSuggestedChart(uniqueId, displayName) {
        var hasX = _hasMessageX(uniqueId)
        var chartType = hasX ? "xy_line" : "time_series"
        var chartId = _generateChartId(chartType)
        var title = (displayName || uniqueId) + (hasX ? " (XY)" : " (Time Series)")

        dialogWindow.createChartRequested(chartType, title, chartId)

        var assignments = _collectAssignments(uniqueId)
        var newAssignment = { "chartId": chartId }
        if (!hasX) {
            newAssignment.valueField = "y"
        }
        assignments.push(newAssignment)
        Qt.callLater(function() {
            dialogWindow.setSignalChartsRequested(uniqueId, assignments)
        })
    }

    function _requestSplitTimeSeries(uniqueId, displayName) {
        if (!_hasMessageX(uniqueId)) return
        var chartIdX = _generateChartId("time_series")
        var chartIdY = _generateChartId("time_series")
        var baseTitle = displayName || uniqueId

        dialogWindow.createChartRequested("time_series", baseTitle + " (X over time)", chartIdX)
        dialogWindow.createChartRequested("time_series", baseTitle + " (Y over time)", chartIdY)

        var assignments = _collectAssignments(uniqueId)
        assignments.push({ "chartId": chartIdX, "valueField": "x" })
        assignments.push({ "chartId": chartIdY, "valueField": "y" })
        Qt.callLater(function() {
            dialogWindow.setSignalChartsRequested(uniqueId, assignments)
        })
    }

    function _refreshSignalsModel() {
        signalsModel.clear()
        if (!dialogWindow.chartLineModel && !dialogWindow.signalModel) return

        var map = ({})

        // Seed from global signal registry
        if (dialogWindow.signalModel) {
            for (var s = 0; s < dialogWindow.signalModel.count; s++) {
                var sig = dialogWindow.signalModel.get(s)
                if (!sig || !sig.uniqueId) continue
                map[sig.uniqueId] = {
                    uniqueId: sig.uniqueId,
                    lineKey: "",
                    displayName: sig.displayName,
                    color: sig.color,
                    interfaceType: sig.interfaceType,
                    dataId: sig.dataId,
                    charts: []
                }
            }
        }

        // Overlay chart assignment info
        if (dialogWindow.chartLineModel) {
            for (var i = 0; i < dialogWindow.chartLineModel.count; i++) {
                var line = dialogWindow.chartLineModel.get(i)
                var key = line.uniqueId
                if (!map[key]) {
                    map[key] = {
                        uniqueId: line.uniqueId,
                        lineKey: "",
                        displayName: line.displayName,
                        color: line.color,
                        interfaceType: line.interfaceType,
                        dataId: line.dataId,
                        charts: []
                    }
                }

                if ((line.chartId || "main") === "main") {
                    map[key].lineKey = line.lineKey
                } else if (!map[key].lineKey || map[key].lineKey === "") {
                    map[key].lineKey = line.lineKey
                }

                if ((line.chartId || "main") !== "main") {
                    var titleSuffix = line.valueField ? (" (" + String(line.valueField).toUpperCase() + ")") : ""
                    map[key].charts.push({
                        chartId: line.chartId,
                        chartTitle: (line.chartTitle || line.chartId) + titleSuffix
                    })
                }
            }
        }

        var keys = Object.keys(map).sort()
        for (var k = 0; k < keys.length; k++) {
            signalsModel.append(map[keys[k]])
        }
    }

    function _refreshChartsModel() {
        chartsModel.clear()
        var charts = dialogWindow.availableCharts || []
        for (var i = 0; i < charts.length; i++) {
            var c = charts[i]
            if (!c || c.chartId === "main") continue
            chartsModel.append(c)
        }
    }

    function _countLinesForChart(chartId) {
        if (!dialogWindow.chartLineModel) return 0
        var c = 0
        for (var i = 0; i < dialogWindow.chartLineModel.count; i++) {
            if (dialogWindow.chartLineModel.get(i).chartId === chartId) c++
        }
        return c
    }

    function _isSignalAssignedToChart(uniqueId, chartId, valueField) {
        if (!dialogWindow.chartLineModel) return false
        return dialogWindow.chartLineModel.hasLineForChart(uniqueId, chartId, valueField)
    }

    function _openAssignDialog(uniqueId) {
        assignChartsModel.clear()
        var charts = dialogWindow.availableCharts || []
        var hasX = _hasMessageX(uniqueId)
        for (var i = 0; i < charts.length; i++) {
            var c = charts[i]
            if (!c || c.chartId === "main") continue
            var chartId = c.chartId
            var chartType = c.chartType
            if (chartType === "time_series") {
                var entries = [
                    { "valueField": "y", "label": "Y", "enabled": true },
                    { "valueField": "x", "label": "X", "enabled": hasX }
                ]
                for (var v = 0; v < entries.length; v++) {
                    var entry = entries[v]
                    assignChartsModel.append({
                        chartId: chartId,
                        chartTitle: c.chartTitle || chartId,
                        chartType: chartType || "",
                        valueField: entry.valueField,
                        label: (c.chartTitle || chartId) + " (" + chartType + " · " + entry.label + ")",
                        enabled: dialogWindow._isXYChart(chartType) && entry.enabled,
                        checked: dialogWindow._isSignalAssignedToChart(uniqueId, chartId, entry.valueField)
                    })
                }
            } else {
                assignChartsModel.append({
                    chartId: chartId,
                    chartTitle: c.chartTitle || chartId,
                    chartType: chartType || "",
                    valueField: null,
                    label: (c.chartTitle || chartId) + " (" + chartType + ")",
                    enabled: dialogWindow._isXYChart(chartType),
                    checked: dialogWindow._isSignalAssignedToChart(uniqueId, chartId)
                })
            }
        }
        assignDialog.uniqueId = uniqueId
        assignDialog.open()
    }

    onChartLineModelChanged: _refreshSignalsModel()
    onSignalModelChanged: _refreshSignalsModel()
    onAvailableChartsChanged: _refreshChartsModel()

    Connections {
        target: dialogWindow.chartLineModel
        function onModelChanged() { dialogWindow._refreshSignalsModel() }
    }

    Connections {
        target: dialogWindow.signalModel
        function onModelChanged() { dialogWindow._refreshSignalsModel() }
    }

    onVisibleChanged: {
        if (visible) {
            _refreshSignalsModel()
            _refreshChartsModel()
        }
    }

    // Main background
    Rectangle {
        anchors.fill: parent
        color: "#f0f0f0"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "#ffffff"
                radius: 8
                border.color: "#d0d0d0"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16

                    Label {
                        text: qsTr("Chart Manager - Detailed View")
                        font.pixelSize: 18
                        font.bold: true
                        color: "#222"
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Close")
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 36

                        background: Rectangle {
                            color: {
                                if (parent.pressed) return "#c62828"
                                if (parent.hovered) return "#d32f2f"
                                return "#e53935"
                            }
                            radius: 6
                            border.color: "#c62828"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 13
                            font.bold: true
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: dialogWindow.close()
                    }
                }
            }

            // Tab Bar
            TabBar {
                id: tabBar
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                background: Rectangle {
                    color: "#ffffff"
                    radius: 8
                    border.color: "#d0d0d0"
                    border.width: 1
                }

                TabButton {
                    text: qsTr("Charts View")
                    height: 48

                    background: Rectangle {
                        color: {
                            if (parent.checked) return "#2196f3"
                            if (parent.hovered) return "#e8e8e8"
                            return "transparent"
                        }
                        radius: 6
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        font.bold: parent.checked
                        color: parent.checked ? "white" : "#444"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TabButton {
                    text: qsTr("Signals Management")
                    height: 48

                    background: Rectangle {
                        color: {
                            if (parent.checked) return "#2196f3"
                            if (parent.hovered) return "#e8e8e8"
                            return "transparent"
                        }
                        radius: 6
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        font.bold: parent.checked
                        color: parent.checked ? "white" : "#444"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TabButton {
                    text: qsTr("Messages")
                    height: 48

                    background: Rectangle {
                        color: {
                            if (parent.checked) return "#2196f3"
                            if (parent.hovered) return "#e8e8e8"
                            return "transparent"
                        }
                        radius: 6
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        font.bold: parent.checked
                        color: parent.checked ? "white" : "#444"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TabButton {
                    text: qsTr("Charts Management")
                    height: 48

                    background: Rectangle {
                        color: {
                            if (parent.checked) return "#2196f3"
                            if (parent.hovered) return "#e8e8e8"
                            return "transparent"
                        }
                        radius: 6
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        font.bold: parent.checked
                        color: parent.checked ? "white" : "#444"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Content Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ffffff"
                radius: 8
                border.color: "#d0d0d0"
                border.width: 1

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    currentIndex: tabBar.currentIndex

                    // Tab 1: Charts View (grouped lines)
                    Item {
                        ChartLinesListGrouped {
                            anchors.fill: parent
                            embedded: true
                            chartLineModel: dialogWindow.chartLineModel

                            onLineVisibilityToggled: function(lineKey, visible) {
                                dialogWindow.lineVisibilityToggled(lineKey, visible)
                            }
                            onLineSelected: function(lineKey) {
                                dialogWindow.lineSelected(lineKey)
                            }
                        }
                    }

                    // Tab 2: Signals Management
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Header with Add button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Label {
                                    text: qsTr("Signal List")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#222"
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: qsTr("%1 signals total").arg(signalsModel.count)
                                    color: "#666"
                                    font.pixelSize: 13
                                }

                                Button {
                                    text: qsTr("Add Signal")
                                    Layout.preferredHeight: 36

                                    background: Rectangle {
                                        color: {
                                            if (parent.pressed) return "#1565c0"
                                            if (parent.hovered) return "#1976d2"
                                            return "#2196f3"
                                        }
                                        radius: 6
                                        border.color: "#1565c0"
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: dialogWindow.addSignalRequested()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#e0e0e0"
                            }

                            // Signals List
                            ListView {
                                id: signalsList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 8
                                model: signalsModel

                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                delegate: Rectangle {
                                    width: signalsList.width
                                    height: 80
                                    radius: 8
                                    color: "#fafafa"
                                    border.color: "#e0e0e0"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 16

                                        // Color indicator
                                        Rectangle {
                                            width: 32
                                            height: 32
                                            radius: 16
                                            color: model.color
                                            border.color: "#ffffff"
                                            border.width: 2
                                            Layout.alignment: Qt.AlignVCenter

                                            Label {
                                                anchors.centerIn: parent
                                                text: model.dataId
                                                color: "#ffffff"
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }

                                        // Signal info
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 4

                                            Label {
                                                text: model.displayName
                                                color: "#222"
                                                font.pixelSize: 14
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Label {
                                                text: qsTr("ID: %1").arg(model.uniqueId)
                                                color: "#666"
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Label {
                                                text: qsTr("Interface: %1 · Data ID: %2 · Assigned to %3 charts").arg(model.interfaceType).arg(model.dataId).arg(model.charts ? model.charts.length : 0)
                                                color: "#888"
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // Action buttons
                                        RowLayout {
                                            spacing: 8
                                            Layout.alignment: Qt.AlignVCenter

                                            Button {
                                                text: qsTr("Assign to Charts")
                                                Layout.preferredHeight: 32
                                                Layout.preferredWidth: 120

                                                background: Rectangle {
                                                    color: {
                                                        if (parent.pressed) return "#e0e0e0"
                                                        if (parent.hovered) return "#eeeeee"
                                                        return "#f5f5f5"
                                                    }
                                                    radius: 4
                                                    border.color: "#d0d0d0"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 11
                                                    color: "#444"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: dialogWindow._openAssignDialog(model.uniqueId)
                                            }

                                            Button {
                                                text: qsTr("Edit")
                                                Layout.preferredHeight: 32
                                                Layout.preferredWidth: 80
                                                enabled: model.lineKey && model.lineKey !== ""

                                                background: Rectangle {
                                                    color: {
                                                        if (!parent.enabled) return "#f0f0f0"
                                                        if (parent.pressed) return "#e0e0e0"
                                                        if (parent.hovered) return "#eeeeee"
                                                        return "#f5f5f5"
                                                    }
                                                    radius: 4
                                                    border.color: parent.enabled ? "#d0d0d0" : "#e0e0e0"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 11
                                                    color: parent.enabled ? "#444" : "#999"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: dialogWindow.lineSelected(model.lineKey)
                                            }

                                            Button {
                                                text: qsTr("Remove")
                                                Layout.preferredHeight: 32
                                                Layout.preferredWidth: 80

                                                background: Rectangle {
                                                    color: {
                                                        if (parent.pressed) return "#ffb0b0"
                                                        if (parent.hovered) return "#ffd6d6"
                                                        return "#ffecec"
                                                    }
                                                    radius: 4
                                                    border.color: "#ffaaaa"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 11
                                                    color: "#c62828"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: dialogWindow.removeSignalRequested(model.uniqueId)
                                            }
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: qsTr("No signals available")
                                    color: "#999"
                                    font.pixelSize: 14
                                    visible: signalsList.count === 0
                                }
                            }
                        }
                    }

                    // Tab 3: Messages
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Label {
                                    text: qsTr("Message List")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#222"
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: qsTr("%1 messages total").arg(dialogWindow.messageModel ? dialogWindow.messageModel.count : 0)
                                    color: "#666"
                                    font.pixelSize: 13
                                }

                                Button {
                                    text: qsTr("Clear")
                                    Layout.preferredHeight: 36
                                    enabled: dialogWindow.messageModel && dialogWindow.messageModel.count > 0

                                    background: Rectangle {
                                        color: {
                                            if (!parent.enabled) return "#f0f0f0"
                                            if (parent.pressed) return "#e0e0e0"
                                            if (parent.hovered) return "#eeeeee"
                                            return "#f5f5f5"
                                        }
                                        radius: 6
                                        border.color: parent.enabled ? "#d0d0d0" : "#e0e0e0"
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: parent.enabled ? "#444" : "#999"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        if (dialogWindow.messageModel && dialogWindow.messageModel.clearAll) {
                                            dialogWindow.messageModel.clearAll()
                                        }
                                    }
                                }
                            }

                            ListView {
                                id: messagesList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 8
                                model: dialogWindow.messageModel ? dialogWindow.messageModel : []

                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                delegate: Rectangle {
                                    id: messageCard
                                    width: messagesList.width
                                    radius: 8
                                    color: "#ffffff"
                                    border.color: "#d0d0d0"
                                    border.width: 1

                                    implicitHeight: contentColumn.implicitHeight + 16
                                    property var msg: model

                                    ColumnLayout {
                                        id: contentColumn
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: model.expanded ? "▼" : "▶"
                                                color: "#666"
                                                font.pixelSize: 12
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                spacing: 3

                                                Label {
                                                    text: model.displayName || model.uniqueId
                                                    color: "#222"
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Label {
                                                    text: (model.interfaceType || "Unknown") + " · " + model.uniqueId + " · ID:" + model.dataId + " · Count:" + (model.rxCount || 0)
                                                    color: "#777"
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 2
                                                Layout.alignment: Qt.AlignVCenter

                                                Label {
                                                    text: model.cycleTime !== null && model.cycleTime !== undefined ? (Math.round(model.cycleTime * 1000) + " ms") : "—"
                                                    color: "#444"
                                                    font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignRight
                                                    Layout.alignment: Qt.AlignRight
                                                }

                                                Label {
                                                    text: model.rxTime ? Qt.formatDateTime(new Date(model.rxTime * 1000), "hh:mm:ss.zzz") : "—"
                                                    color: "#777"
                                                    font.pixelSize: 11
                                                    horizontalAlignment: Text.AlignRight
                                                    Layout.alignment: Qt.AlignRight
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Button {
                                                text: qsTr("Suggested")
                                                Layout.preferredHeight: 28

                                                background: Rectangle {
                                                    color: parent.hovered ? "#e3f2fd" : "#f5f5f5"
                                                    radius: 5
                                                    border.color: "#cfd8dc"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: "#1565c0"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: dialogWindow._requestSuggestedChart(model.uniqueId, model.displayName)
                                            }

                                            Button {
                                                text: qsTr("Assign...")
                                                Layout.preferredHeight: 28

                                                background: Rectangle {
                                                    color: parent.hovered ? "#eeeeee" : "#f5f5f5"
                                                    radius: 5
                                                    border.color: "#d0d0d0"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: "#444"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: dialogWindow._openAssignDialog(model.uniqueId)
                                            }

                                            Button {
                                                text: qsTr("Split X/Y")
                                                Layout.preferredHeight: 28
                                                visible: dialogWindow._hasMessageX(model.uniqueId)

                                                background: Rectangle {
                                                    color: parent.hovered ? "#fff3e0" : "#fff8e1"
                                                    radius: 5
                                                    border.color: "#ffe0b2"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: "#ef6c00"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: dialogWindow._requestSplitTimeSeries(model.uniqueId, model.displayName)
                                            }

                                            Item { Layout.fillWidth: true }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 1
                                            color: "#eeeeee"
                                            visible: model.expanded
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            visible: model.expanded

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                Label { text: qsTr("Signal"); font.pixelSize: 11; color: "#666"; Layout.preferredWidth: 100 }
                                                Label { text: qsTr("Value"); font.pixelSize: 11; color: "#666"; Layout.fillWidth: true }
                                                Label { text: qsTr("Cycle"); font.pixelSize: 11; color: "#666"; Layout.preferredWidth: 90; horizontalAlignment: Text.AlignRight }
                                                Label { text: qsTr("Updated"); font.pixelSize: 11; color: "#666"; Layout.preferredWidth: 120; horizontalAlignment: Text.AlignRight }
                                            }

                                            Repeater {
                                                model: [
                                                    { "name": "x", "value": messageCard.msg.x },
                                                    { "name": "y", "value": messageCard.msg.y },
                                                    { "name": "z", "value": messageCard.msg.z },
                                                    { "name": "timestamp", "value": messageCard.msg.timestamp, "t": messageCard.msg.t }
                                                ]

                                                delegate: RowLayout {
                                                    width: parent ? parent.width : messagesList.width
                                                    spacing: 10

                                                    Label {
                                                        text: modelData.name
                                                        font.pixelSize: 13
                                                        color: "#222"
                                                        Layout.preferredWidth: 100
                                                    }

                                                    Label {
                                                        text: {
                                                            if (modelData.name === "timestamp") {
                                                                if (modelData.value === null || modelData.value === undefined) return "—"
                                                                var base = Number(modelData.value).toFixed(6)
                                                                if (modelData.t === null || modelData.t === undefined) return base
                                                                return base + " (t=" + Number(modelData.t).toFixed(3) + "s)"
                                                            }
                                                            if (modelData.value === null || modelData.value === undefined) return "—"
                                                            return Number(modelData.value).toFixed(6)
                                                        }
                                                        font.pixelSize: 13
                                                        color: "#444"
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }

                                                    Label {
                                                        text: messageCard.msg.cycleTime !== null && messageCard.msg.cycleTime !== undefined ? (Math.round(messageCard.msg.cycleTime * 1000) + " ms") : "—"
                                                        font.pixelSize: 13
                                                        color: "#444"
                                                        horizontalAlignment: Text.AlignRight
                                                        Layout.preferredWidth: 90
                                                    }

                                                    Label {
                                                        text: messageCard.msg.rxTime ? Qt.formatDateTime(new Date(messageCard.msg.rxTime * 1000), "hh:mm:ss") : "—"
                                                        font.pixelSize: 13
                                                        color: "#444"
                                                        horizontalAlignment: Text.AlignRight
                                                        Layout.preferredWidth: 120
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    TapHandler {
                                        onTapped: {
                                            if (dialogWindow.messageModel && dialogWindow.messageModel.toggleExpanded) {
                                                dialogWindow.messageModel.toggleExpanded(model.uniqueId)
                                            }
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: qsTr("No messages available")
                                    color: "#999"
                                    font.pixelSize: 14
                                    visible: messagesList.count === 0
                                }
                            }
                        }
                    }

                    // Tab 4: Charts Management
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Header with Add button
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Label {
                                    text: qsTr("Chart List")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#222"
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: qsTr("%1 charts total").arg(chartsModel.count)
                                    color: "#666"
                                    font.pixelSize: 13
                                }

                                Button {
                                    text: qsTr("Add Chart")
                                    Layout.preferredHeight: 36

                                    background: Rectangle {
                                        color: {
                                            if (parent.pressed) return "#1565c0"
                                            if (parent.hovered) return "#1976d2"
                                            return "#2196f3"
                                        }
                                        radius: 6
                                        border.color: "#1565c0"
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: createChartDialog.open()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#e0e0e0"
                            }

                            // Charts List
                            ListView {
                                id: chartsList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 8
                                model: chartsModel

                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                delegate: Rectangle {
                                    width: chartsList.width
                                    height: 80
                                    radius: 8
                                    color: "#fafafa"
                                    border.color: "#e0e0e0"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 16

                                        // Chart icon
                                        Rectangle {
                                            width: 48
                                            height: 48
                                            radius: 8
                                            color: "#2196f3"
                                            Layout.alignment: Qt.AlignVCenter

                                            Label {
                                                anchors.centerIn: parent
                                                text: "📊"
                                                font.pixelSize: 24
                                            }
                                        }

                                        // Chart info
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 4

                                            Label {
                                                text: model.chartTitle || model.chartId
                                                color: "#222"
                                                font.pixelSize: 14
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Label {
                                                text: qsTr("ID: %1").arg(model.chartId)
                                                color: "#666"
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Label {
                                                text: qsTr("Type: %1 · Lines: %2").arg(model.chartType || "unknown").arg(dialogWindow._countLinesForChart(model.chartId))
                                                color: "#888"
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // Action buttons
                                        RowLayout {
                                            spacing: 8
                                            Layout.alignment: Qt.AlignVCenter

                                            Button {
                                                text: qsTr("Rename")
                                                Layout.preferredHeight: 32
                                                Layout.preferredWidth: 100

                                                background: Rectangle {
                                                    color: {
                                                        if (parent.pressed) return "#e0e0e0"
                                                        if (parent.hovered) return "#eeeeee"
                                                        return "#f5f5f5"
                                                    }
                                                    radius: 4
                                                    border.color: "#d0d0d0"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 11
                                                    color: "#444"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: {
                                                    renameChartDialog.chartId = model.chartId
                                                    renameChartDialog.titleText = model.chartTitle || model.chartId
                                                    renameChartDialog.open()
                                                }
                                            }

                                            Button {
                                                text: qsTr("Remove")
                                                enabled: model.chartId !== "main"
                                                Layout.preferredHeight: 32
                                                Layout.preferredWidth: 100

                                                background: Rectangle {
                                                    color: {
                                                        if (!parent.enabled) return "#f0f0f0"
                                                        if (parent.pressed) return "#ffb0b0"
                                                        if (parent.hovered) return "#ffd6d6"
                                                        return "#ffecec"
                                                    }
                                                    radius: 4
                                                    border.color: parent.enabled ? "#ffaaaa" : "#e0e0e0"
                                                    border.width: 1
                                                }

                                                contentItem: Text {
                                                    text: parent.text
                                                    font.pixelSize: 11
                                                    color: parent.enabled ? "#c62828" : "#999"
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: dialogWindow.removeChartRequested(model.chartId)
                                            }
                                        }
                                    }
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: qsTr("No charts available")
                                    color: "#999"
                                    font.pixelSize: 14
                                    visible: chartsList.count === 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dialog components (reused from ChartsManager)

    // Assign signal dialog
    Dialog {
        id: assignDialog
        title: qsTr("Assign Signal to Charts")
        modal: true
        standardButtons: Dialog.NoButton
        parent: Overlay.overlay
        anchors.centerIn: parent

        property string uniqueId: ""

        width: 500
        height: 600

        background: Rectangle {
            color: "#2d2d2d"
            border.color: "#4d4d4d"
            border.width: 1
            radius: 8
        }

        header: Rectangle {
            height: 60
            color: "#353535"
            radius: 8

            Label {
                anchors.centerIn: parent
                text: assignDialog.title
                font.pixelSize: 18
                font.bold: true
                color: "#ffffff"
            }
        }

        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Label {
                    text: assignDialog.uniqueId
                    font.pixelSize: 11
                    color: "#888888"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#4d4d4d"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: dialogWindow._hasMessageX(assignDialog.uniqueId)
                            ? qsTr("Recommended: XY Chart")
                            : qsTr("Recommended: Time Series")
                        font.pixelSize: 12
                        color: "#cccccc"
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Create")
                        Layout.preferredWidth: 90

                        background: Rectangle {
                            color: parent.hovered ? "#0066CC" : "#007AFF"
                            radius: 4
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            font.bold: true
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            dialogWindow._requestSuggestedChart(assignDialog.uniqueId, dialogWindow._getMessageDisplayName(assignDialog.uniqueId))
                            assignDialog.close()
                        }
                    }
                }

                ScrollView {
                    id: assignScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        width: assignScrollView.availableWidth
                        spacing: 8

                        Repeater {
                            model: assignChartsModel
                            delegate: CheckBox {
                                text: model.label || (model.chartTitle + " (" + model.chartType + ")")
                                enabled: model.enabled
                                checked: model.checked
                                Layout.fillWidth: true

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 13
                                    color: parent.enabled ? "#ffffff" : "#888888"
                                    leftPadding: parent.indicator.width + parent.spacing
                                    rightPadding: 8
                                    elide: Text.ElideRight
                                    width: parent.width
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onToggled: {
                                    assignChartsModel.setProperty(index, "checked", checked)
                                }
                            }
                        }
                    }
                }
            }
        }

        footer: Rectangle {
            height: 60
            color: "#353535"
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    Layout.preferredWidth: 100

                    background: Rectangle {
                        color: parent.hovered ? "#4d4d4d" : "#3d3d3d"
                        border.color: "#606060"
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: assignDialog.reject()
                }

                Button {
                    text: qsTr("Apply")
                    Layout.preferredWidth: 100

                    background: Rectangle {
                        color: parent.enabled ? (parent.hovered ? "#0066CC" : "#007AFF") : "#4d4d4d"
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.bold: true
                        color: parent.enabled ? "#ffffff" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: assignDialog.accept()
                }
            }
        }

        onAccepted: {
            var selected = []
            for (var i = 0; i < assignChartsModel.count; i++) {
                var c = assignChartsModel.get(i)
                if (c.checked) {
                    var assignment = { "chartId": c.chartId }
                    if (c.valueField) assignment.valueField = c.valueField
                    selected.push(assignment)
                }
            }
            dialogWindow.setSignalChartsRequested(assignDialog.uniqueId, selected)
        }
    }

    // Create chart dialog
    Dialog {
        id: createChartDialog
        title: qsTr("Add Chart")
        modal: true
        standardButtons: Dialog.NoButton
        parent: Overlay.overlay
        anchors.centerIn: parent

        property string titleText: ""
        property string chartType: "xy_line"

        width: 500
        height: 320

        background: Rectangle {
            color: "#2d2d2d"
            border.color: "#4d4d4d"
            border.width: 1
            radius: 8
        }

        header: Rectangle {
            height: 60
            color: "#353535"
            radius: 8

            Label {
                anchors.centerIn: parent
                text: createChartDialog.title
                font.pixelSize: 18
                font.bold: true
                color: "#ffffff"
            }
        }

        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: qsTr("Chart Title") + " *"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    TextField {
                        id: newChartTitle
                        Layout.fillWidth: true
                        placeholderText: qsTr("e.g., Temperature Chart")
                        text: ""

                        background: Rectangle {
                            color: "#3d3d3d"
                            border.color: newChartTitle.activeFocus ? "#007AFF" : "#606060"
                            border.width: 1
                            radius: 4
                        }

                        color: "#ffffff"
                        font.pixelSize: 13
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: qsTr("Chart Type") + " *"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    ComboBox {
                        id: chartTypeCombo
                        Layout.fillWidth: true
                        model: [
                            {"text":"XY Line", "value":"xy_line"},
                            {"text":"XY Scatter", "value":"xy_scatter"},
                            {"text":"XYZ Scatter", "value":"xyz_scatter"}
                        ]
                        textRole: "text"

                        background: Rectangle {
                            color: "#3d3d3d"
                            border.color: chartTypeCombo.activeFocus ? "#007AFF" : "#606060"
                            border.width: 1
                            radius: 4
                        }

                        contentItem: Text {
                            text: chartTypeCombo.displayText
                            font: chartTypeCombo.font
                            color: "#ffffff"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }

                        delegate: ItemDelegate {
                            width: chartTypeCombo.width

                            contentItem: Text {
                                text: modelData ? modelData.text : ""
                                color: "#ffffff"
                                font: chartTypeCombo.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: parent.hovered ? "#4d4d4d" : "#3d3d3d"
                            }
                        }

                        onCurrentIndexChanged: {
                            var item = model[currentIndex]
                            createChartDialog.chartType = item ? item.value : "xy_line"
                        }
                    }
                }
            }
        }

        footer: Rectangle {
            height: 60
            color: "#353535"
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    Layout.preferredWidth: 100

                    background: Rectangle {
                        color: parent.hovered ? "#4d4d4d" : "#3d3d3d"
                        border.color: "#606060"
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: createChartDialog.reject()
                }

                Button {
                    text: qsTr("Add Chart")
                    Layout.preferredWidth: 100
                    enabled: newChartTitle.text.length > 0

                    background: Rectangle {
                        color: parent.enabled ? (parent.hovered ? "#0066CC" : "#007AFF") : "#4d4d4d"
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.bold: true
                        color: parent.enabled ? "#ffffff" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: createChartDialog.accept()
                }
            }
        }

        onAccepted: {
            var title = newChartTitle.text && newChartTitle.text.length > 0 ? newChartTitle.text : ("Chart " + Date.now())
            dialogWindow.createChartRequested(createChartDialog.chartType, title, "")
        }

        onAboutToShow: {
            newChartTitle.text = ""
            chartTypeCombo.currentIndex = 0
        }
    }

    // Rename chart dialog
    Dialog {
        id: renameChartDialog
        title: qsTr("Rename Chart")
        modal: true
        standardButtons: Dialog.NoButton
        parent: Overlay.overlay
        anchors.centerIn: parent

        property string chartId: ""
        property string titleText: ""

        width: 500
        height: 280

        background: Rectangle {
            color: "#2d2d2d"
            border.color: "#4d4d4d"
            border.width: 1
            radius: 8
        }

        header: Rectangle {
            height: 60
            color: "#353535"
            radius: 8

            Label {
                anchors.centerIn: parent
                text: renameChartDialog.title
                font.pixelSize: 18
                font.bold: true
                color: "#ffffff"
            }
        }

        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Label {
                    text: renameChartDialog.chartId
                    color: "#888888"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#4d4d4d"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: qsTr("New Title") + " *"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    TextField {
                        id: renameField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Enter new chart title")
                        text: renameChartDialog.titleText

                        background: Rectangle {
                            color: "#3d3d3d"
                            border.color: renameField.activeFocus ? "#007AFF" : "#606060"
                            border.width: 1
                            radius: 4
                        }

                        color: "#ffffff"
                        font.pixelSize: 13
                    }
                }
            }
        }

        footer: Rectangle {
            height: 60
            color: "#353535"
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    Layout.preferredWidth: 100

                    background: Rectangle {
                        color: parent.hovered ? "#4d4d4d" : "#3d3d3d"
                        border.color: "#606060"
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: renameChartDialog.reject()
                }

                Button {
                    text: qsTr("Rename")
                    Layout.preferredWidth: 100
                    enabled: renameField.text.length > 0

                    background: Rectangle {
                        color: parent.enabled ? (parent.hovered ? "#0066CC" : "#007AFF") : "#4d4d4d"
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.bold: true
                        color: parent.enabled ? "#ffffff" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: renameChartDialog.accept()
                }
            }
        }

        onAccepted: {
            var title = renameField.text
            if (!title || title.length === 0) return
            dialogWindow.renameChartRequested(renameChartDialog.chartId, title)
        }

        onAboutToShow: {
            renameField.forceActiveFocus()
        }
    }
}
