import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Common 1.0
import Theme 1.0

/**
 * ChartsManager.qml (Tabbed)
 *
 * Right-side management panel:
 * 1) Charts view: chart lines grouped/labelled by chart
 * 2) Signals view: global signal list (add/remove/assign)
 * 3) Charts view: manage charts (add/remove/rename)
 */
Item {
    id: root
    objectName: "chartsManager"

    // Compatibility signals (ChartWindow already listens to these)
    signal lineVisibilityToggled(string lineKey, bool visible)
    signal lineSelected(string lineKey)
    signal collapseToggled()

    // New management requests (handled by ChartWindow)
    signal addSignalRequested()
    signal removeSignalRequested(string uniqueId)
    signal setSignalChartsRequested(string uniqueId, var assignments)
    signal createChartRequested(string chartType, string chartTitle, string chartId)
    signal removeChartRequested(string chartId)
    signal renameChartRequested(string chartId, string chartTitle)

    property bool isCollapsed: false
    property var chartLineModel: null
    property var signalModel: null  // Global signal registry (uniqueId -> metadata)
    property var messageModel: null // Latest messages (uniqueId -> values/timing)
    property var availableCharts: [] // [{chartId, chartTitle, chartType}]

    readonly property color panelBackground: AppTheme.surfaces.interfaceBackground
    readonly property color cardBackground: AppTheme.surfaces.card
    readonly property color dividerColor: AppTheme.borders.subtle
    readonly property color borderColor: AppTheme.borders.primary
    readonly property color textPrimary: AppTheme.text.primary
    readonly property color textSecondary: AppTheme.text.secondary
    readonly property color textMuted: AppTheme.text.placeholder
    readonly property color accent: AppTheme.palette.primary
    readonly property color accentHover: AppTheme.palette.primaryHover
    readonly property color accentPressed: AppTheme.palette.primaryPressed
    readonly property color accentBorder: AppTheme.palette.primaryBorder

    // Internal models
    ListModel { id: signalsModel }
    ListModel { id: chartsModel }
    ListModel { id: assignChartsModel }

    function _isXYChart(chartType) {
        // Compatibility: this is used for enabling/disabling signal assignment per chart type.
        // Support XY + TimeSeries + XYZ for message-based data (x/y/z).
        return chartType === "xy_line" ||
               chartType === "xy_scatter" ||
               chartType === "time_series" ||
               chartType === "xyz_surface" ||
               chartType === "xyz_scatter"
    }

    function _getMessage(uniqueId) {
        if (!root.messageModel || !root.messageModel.getMessage) return null
        return root.messageModel.getMessage(uniqueId)
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

    function _canAssignSignal(chartType, uniqueId) {
        if (chartType === "time_series") return true
        if (chartType === "xy_line" || chartType === "xy_scatter") {
            return _hasMessageX(uniqueId)
        }
        var msg = _getMessage(uniqueId)
        if (chartType === "xyz_surface" || chartType === "xyz_scatter") {
            return !!(msg && msg.x !== null && msg.x !== undefined &&
                msg.z !== null && msg.z !== undefined)
        }
        return false
    }

    function _generateChartId(chartType) {
        return "chart_" + chartType + "_" + Date.now() + "_" + Math.floor(Math.random() * 1000)
    }

    function openCreateChartDialog() {
        createChartDialog.open()
    }

    function _collectAssignments(uniqueId) {
        var assignments = []
        if (!root.chartLineModel) return assignments
        for (var i = 0; i < root.chartLineModel.count; i++) {
            var line = root.chartLineModel.get(i)
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
        var title = (displayName || uniqueId) + (hasX ? " (Cartesian XY)" : " (Time series)")

        root.createChartRequested(chartType, title, chartId)

        var assignments = _collectAssignments(uniqueId)
        var newAssignment = { "chartId": chartId }
        if (!hasX) {
            newAssignment.valueField = "y"
        }
        assignments.push(newAssignment)
        Qt.callLater(function() {
            root.setSignalChartsRequested(uniqueId, assignments)
        })
    }

    function _requestSplitTimeSeries(uniqueId, displayName) {
        if (!_hasMessageX(uniqueId)) return
        var chartIdX = _generateChartId("time_series")
        var chartIdY = _generateChartId("time_series")
        var baseTitle = displayName || uniqueId

        root.createChartRequested("time_series", baseTitle + " (X over time)", chartIdX)
        root.createChartRequested("time_series", baseTitle + " (Y over time)", chartIdY)

        var assignments = _collectAssignments(uniqueId)
        assignments.push({ "chartId": chartIdX, "valueField": "x" })
        assignments.push({ "chartId": chartIdY, "valueField": "y" })
        Qt.callLater(function() {
            root.setSignalChartsRequested(uniqueId, assignments)
        })
    }

    function _refreshSignalsModel() {
        signalsModel.clear()
        if (!root.chartLineModel && !root.signalModel) return

        var map = ({})

        // Seed from global signal registry so signals stay visible even if not assigned to any chart
        if (root.signalModel) {
            for (var s = 0; s < root.signalModel.count; s++) {
                var sig = root.signalModel.get(s)
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

        // Overlay chart assignment info from chartLineModel (and fill gaps if registry is missing entries)
        if (root.chartLineModel) {
            for (var i = 0; i < root.chartLineModel.count; i++) {
                var line = root.chartLineModel.get(i)
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

                // Prefer a main-chart lineKey for editing; otherwise fall back to any existing instance
                if ((line.chartId || "main") === "main") {
                    map[key].lineKey = line.lineKey
                } else if (!map[key].lineKey || map[key].lineKey === "") {
                    map[key].lineKey = line.lineKey
                }

                // Do not expose the internal "main" chart in the UI (signals are still tracked)
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
        var charts = root.availableCharts || []
        for (var i = 0; i < charts.length; i++) {
            var c = charts[i]
            // "main" is an internal chart used for assigning signals; it is not a managed chart window.
            if (!c || c.chartId === "main") continue
            chartsModel.append(c)
        }
    }

    function _countLinesForChart(chartId) {
        if (!root.chartLineModel) return 0
        var c = 0
        for (var i = 0; i < root.chartLineModel.count; i++) {
            if (root.chartLineModel.get(i).chartId === chartId) c++
        }
        return c
    }

    function _isSignalAssignedToChart(uniqueId, chartId, valueField) {
        if (!root.chartLineModel) return false
        return root.chartLineModel.hasLineForChart(uniqueId, chartId, valueField)
    }

    function _openAssignDialog(uniqueId) {
        assignChartsModel.clear()
        var charts = root.availableCharts || []
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
                        enabled: root._isXYChart(chartType) && entry.enabled,
                        checked: root._isSignalAssignedToChart(uniqueId, chartId, entry.valueField)
                    })
                }
            } else {
                assignChartsModel.append({
                    chartId: chartId,
                    chartTitle: c.chartTitle || chartId,
                    chartType: chartType || "",
                    valueField: null,
                    label: (c.chartTitle || chartId) + " (" + chartType + ")",
                    enabled: root._canAssignSignal(chartType, uniqueId),
                    checked: root._isSignalAssignedToChart(uniqueId, chartId)
                })
            }
        }
        assignDialog.uniqueId = uniqueId
        assignDialog.open()
    }

    onChartLineModelChanged: {
        _refreshSignalsModel()
    }

    onSignalModelChanged: {
        _refreshSignalsModel()
    }

    onAvailableChartsChanged: {
        _refreshChartsModel()
    }

    Connections {
        target: root.chartLineModel
        function onModelChanged() {
            root._refreshSignalsModel()
        }
    }

    Connections {
        target: root.signalModel
        function onModelChanged() {
            root._refreshSignalsModel()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.panelBackground
        border.color: root.borderColor
        border.width: 1
        radius: 8

        // Collapsed state - just the button centered
        Button {
            id: collapseButton
            visible: root.isCollapsed
            anchors.centerIn: parent
            width: 40
            height: 40
            text: "◀"
            font.pixelSize: 18
            font.bold: true

            ToolTip.visible: hovered
            ToolTip.text: qsTr("Expand")
            ToolTip.delay: 400

            background: Rectangle {
                color: {
                    if (collapseButton.pressed) return root.accentPressed
                    if (collapseButton.hovered) return root.accentHover
                    return root.accent
                }
                radius: 6
                border.color: root.accentBorder
                border.width: 1
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.collapseToggled()
        }

        // Expanded state - full layout
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            visible: !root.isCollapsed

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: qsTr("Workspace")
                    font.pixelSize: 14
                    font.bold: true
                    color: root.textPrimary
                    Layout.fillWidth: true
                }

                Button {
                    id: detailViewButton
                    text: qsTr("Details")
                    font.pixelSize: 12
                    font.bold: true
                    width: 66
                    height: 32

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Open workspace details in a separate window")
                    ToolTip.delay: 400

                    background: Rectangle {
                        color: {
                            if (detailViewButton.pressed) return root.accentPressed
                            if (detailViewButton.hovered) return root.accentHover
                            return root.accent
                        }
                        radius: 4
                        border.color: root.accentBorder
                        border.width: 1
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: root.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: detailDialog.show()
                }

                Button {
                    id: headerCollapseButton
                    text: "▶"
                    font.pixelSize: 14
                    font.bold: true
                    width: 32
                    height: 32

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Collapse")
                    ToolTip.delay: 400

                    background: Rectangle {
                        color: {
                            if (headerCollapseButton.pressed) return root.accentPressed
                            if (headerCollapseButton.hovered) return root.accentHover
                            return root.accent
                        }
                        radius: 4
                        border.color: root.accentBorder
                        border.width: 1
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.collapseToggled()
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: root.dividerColor }

            TabBar {
                id: tabBar
                Layout.fillWidth: true
                currentIndex: 3

                background: Rectangle {
                    color: root.cardBackground
                    radius: 4
                }

                TabButton {
                    implicitWidth: 80
                    text: qsTr("Lines")

                    background: Rectangle {
                        color: {
                            if (parent.checked) return root.accent
                            if (parent.hovered) return root.dividerColor
                            return "transparent"
                        }
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 12
                        font.bold: parent.checked
                        color: parent.checked ? root.textPrimary : root.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TabButton {
                    implicitWidth: 80
                    text: qsTr("Signals")

                    background: Rectangle {
                        color: {
                            if (parent.checked) return root.accent
                            if (parent.hovered) return root.dividerColor
                            return "transparent"
                        }
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 12
                        font.bold: parent.checked
                        color: parent.checked ? root.textPrimary : root.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TabButton {
                    implicitWidth: 80
                    text: qsTr("Data")

                    background: Rectangle {
                        color: {
                            if (parent.checked) return root.accent
                            if (parent.hovered) return root.dividerColor
                            return "transparent"
                        }
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 12
                        font.bold: parent.checked
                        color: parent.checked ? root.textPrimary : root.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                TabButton {
                    implicitWidth: 80
                    text: qsTr("Charts")

                    background: Rectangle {
                        color: {
                            if (parent.checked) return root.accent
                            if (parent.hovered) return root.dividerColor
                            return "transparent"
                        }
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 12
                        font.bold: parent.checked
                        color: parent.checked ? root.textPrimary : root.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                // ---------------------------------------------------------
                // Tab 1: Chart lines (per chart)
                // ---------------------------------------------------------
                Item {
                    ChartLinesListGrouped {
                        anchors.fill: parent
                        embedded: true
                        chartLineModel: root.chartLineModel

                        onLineVisibilityToggled: function(lineKey, visible) {
                            root.lineVisibilityToggled(lineKey, visible)
                        }
                        onLineSelected: function(lineKey) {
                            root.lineSelected(lineKey)
                        }
                    }
                }

                // ---------------------------------------------------------
                // Tab 2: Signals (global)
                // ---------------------------------------------------------
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                text: qsTr("Add Signal")
                                Layout.preferredHeight: 32

                                background: Rectangle {
                                    color: {
                                        if (parent.pressed) return root.accentPressed
                                        if (parent.hovered) return root.accentHover
                                        return root.accent
                                    }
                                    radius: 4
                                    border.color: root.accentBorder
                                    border.width: 1
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.textPrimary
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: root.addSignalRequested()
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: qsTr("%1 signals").arg(signalsModel.count)
                                color: root.textMuted
                                font.pixelSize: 11
                            }
                        }

                        ListView {
                            id: signalsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: signalsModel
                            reuseItems: true
                            cacheBuffer: 200

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                width: signalsList.width
                                height: 52
                                radius: 6
                                color: root.cardBackground
                                border.color: root.borderColor
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: model.color
                                        border.color: root.borderColor
                                        border.width: 1
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            text: model.displayName
                                            color: root.textPrimary
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Label {
                                            text: model.uniqueId + " · " + model.interfaceType + " · ID:" + model.dataId + " · Charts:" + (model.charts ? model.charts.length : 0)
                                            color: root.textSecondary
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Button {
                                        text: qsTr("Assign")
                                        Layout.preferredHeight: 28

                                        background: Rectangle {
                                            color: {
                                                if (parent.pressed) return AppTheme.surfaces.muted
                                                if (parent.hovered) return AppTheme.surfaces.card
                                                return AppTheme.surfaces.muted
                                            }
                                            radius: 4
                                            border.color: root.dividerColor
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            font.pixelSize: 11
                                            color: root.textSecondary
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: root._openAssignDialog(model.uniqueId)
                                    }

                                    Button {
                                        text: qsTr("Edit")
                                        Layout.preferredHeight: 28
                                        enabled: model.lineKey && model.lineKey !== ""

                                        background: Rectangle {
                                            color: {
                                                if (parent.pressed) return AppTheme.surfaces.muted
                                                if (parent.hovered) return AppTheme.surfaces.card
                                                return AppTheme.surfaces.muted
                                            }
                                            radius: 4
                                            border.color: root.dividerColor
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            font.pixelSize: 11
                                            color: root.textSecondary
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: root.lineSelected(model.lineKey)
                                    }

                                    Button {
                                        text: qsTr("Remove")
                                        Layout.preferredHeight: 28

                                        background: Rectangle {
                                            color: {
                                                if (parent.pressed) return Qt.darker(AppTheme.palette.danger, 1.2)
                                                if (parent.hovered) return AppTheme.palette.danger
                                                return Qt.lighter(AppTheme.palette.danger, 1.35)
                                            }
                                            radius: 4
                                            border.color: Qt.darker(AppTheme.palette.danger, 1.1)
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            font.pixelSize: 11
                                            color: AppTheme.text.primary
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: root.removeSignalRequested(model.uniqueId)
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("No signals")
                                color: root.textMuted
                                font.pixelSize: 12
                                visible: signalsList.count === 0
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // Tab 3: Messages (global)
                // ---------------------------------------------------------
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                text: qsTr("Clear")
                                Layout.preferredHeight: 32
                                enabled: root.messageModel && root.messageModel.count > 0

                                background: Rectangle {
                                    color: parent.enabled ? (parent.hovered ? AppTheme.surfaces.card : AppTheme.surfaces.muted) : AppTheme.states.disabledBackground
                                    radius: 4
                                    border.color: root.dividerColor
                                    border.width: 1
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: parent.enabled ? root.textSecondary : root.textMuted
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    if (root.messageModel && root.messageModel.clearAll) {
                                        root.messageModel.clearAll()
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: qsTr("%1 messages").arg(root.messageModel ? root.messageModel.count : 0)
                                color: root.textMuted
                                font.pixelSize: 11
                            }
                        }

                        ListView {
                            id: messagesList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: root.messageModel ? root.messageModel : []
                            reuseItems: true
                            cacheBuffer: 240

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                id: messageCard
                                width: messagesList.width
                                radius: 8
                                color: root.cardBackground
                                border.color: root.borderColor
                                border.width: 1

                                implicitHeight: contentColumn.implicitHeight + 16
                                property var msg: model

                                ColumnLayout {
                                    id: contentColumn
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: model.expanded ? "▼" : "▶"
                                            color: root.textSecondary
                                            font.pixelSize: 12
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Label {
                                                text: model.displayName || model.uniqueId
                                                color: root.textPrimary
                                                font.pixelSize: 12
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Label {
                                                text: (model.interfaceType || "Unknown") + " · " + model.uniqueId + " · ID:" + model.dataId + " · Count:" + (model.rxCount || 0)
                                                color: root.textSecondary
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        ColumnLayout {
                                            spacing: 2
                                            Layout.alignment: Qt.AlignVCenter

                                            Label {
                                                text: model.cycleTime !== null && model.cycleTime !== undefined ? (Math.round(model.cycleTime * 1000) + " ms") : "—"
                                                color: root.textSecondary
                                                font.pixelSize: 11
                                                horizontalAlignment: Text.AlignRight
                                                Layout.alignment: Qt.AlignRight
                                            }

                                            Label {
                                                text: model.rxTime ? Qt.formatDateTime(new Date(model.rxTime * 1000), "hh:mm:ss.zzz") : "—"
                                                color: root.textMuted
                                                font.pixelSize: 10
                                                horizontalAlignment: Text.AlignRight
                                                Layout.alignment: Qt.AlignRight
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Button {
                                            text: qsTr("Suggested")
                                            Layout.preferredHeight: 26

                                            background: Rectangle {
                                                color: parent.hovered ? AppTheme.surfaces.card : AppTheme.surfaces.muted
                                                radius: 4
                                                border.color: root.dividerColor
                                                border.width: 1
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.accent
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            onClicked: root._requestSuggestedChart(model.uniqueId, model.displayName)
                                        }

                                        Button {
                                            text: qsTr("Assign...")
                                            Layout.preferredHeight: 26

                                            background: Rectangle {
                                                color: parent.hovered ? AppTheme.surfaces.card : AppTheme.surfaces.muted
                                                radius: 4
                                                border.color: root.dividerColor
                                                border.width: 1
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.textSecondary
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            onClicked: root._openAssignDialog(model.uniqueId)
                                        }

                                        Button {
                                            text: qsTr("Split X/Y")
                                            Layout.preferredHeight: 26
                                            visible: root._hasMessageX(model.uniqueId)

                                            background: Rectangle {
                                                color: parent.hovered ? Qt.lighter(AppTheme.palette.warning, 1.3) : Qt.lighter(AppTheme.palette.warning, 1.5)
                                                radius: 4
                                                border.color: AppTheme.palette.warning
                                                border.width: 1
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: AppTheme.palette.warning
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            onClicked: root._requestSplitTimeSeries(model.uniqueId, model.displayName)
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: root.dividerColor
                                        visible: model.expanded
                                    }

                                    // Expanded details: show "signals" inside the message (x/y/z/timestamp)
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        visible: model.expanded

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Label { text: qsTr("Signal"); font.pixelSize: 10; color: root.textMuted; Layout.preferredWidth: 90 }
                                            Label { text: qsTr("Value"); font.pixelSize: 10; color: root.textMuted; Layout.fillWidth: true }
                                            Label { text: qsTr("Cycle"); font.pixelSize: 10; color: root.textMuted; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight }
                                            Label { text: qsTr("Updated"); font.pixelSize: 10; color: root.textMuted; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignRight }
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
                                                spacing: 8

                                                Label {
                                                    text: modelData.name
                                                    font.pixelSize: 12
                                                    color: root.textPrimary
                                                    Layout.preferredWidth: 90
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
                                                    font.pixelSize: 12
                                                    color: root.textSecondary
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Label {
                                                    text: messageCard.msg.cycleTime !== null && messageCard.msg.cycleTime !== undefined ? (Math.round(messageCard.msg.cycleTime * 1000) + " ms") : "—"
                                                    font.pixelSize: 12
                                                    color: root.textSecondary
                                                    horizontalAlignment: Text.AlignRight
                                                    Layout.preferredWidth: 80
                                                }

                                                Label {
                                                    text: messageCard.msg.rxTime ? Qt.formatDateTime(new Date(messageCard.msg.rxTime * 1000), "hh:mm:ss") : "—"
                                                    font.pixelSize: 12
                                                    color: root.textSecondary
                                                    horizontalAlignment: Text.AlignRight
                                                    Layout.preferredWidth: 100
                                                }
                                            }
                                        }
                                    }
                                }

                                TapHandler {
                                    onTapped: {
                                        if (root.messageModel && root.messageModel.toggleExpanded) {
                                            root.messageModel.toggleExpanded(model.uniqueId)
                                        }
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("No messages")
                                color: root.textMuted
                                font.pixelSize: 12
                                visible: messagesList.count === 0
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // Tab 4: Charts (global)
                // ---------------------------------------------------------
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                text: qsTr("Create chart")
                                Layout.preferredHeight: 32

                                background: Rectangle {
                                    color: {
                                        if (parent.pressed) return root.accentPressed
                                        if (parent.hovered) return root.accentHover
                                        return root.accent
                                    }
                                    radius: 4
                                    border.color: root.accentBorder
                                    border.width: 1
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.textPrimary
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: createChartDialog.open()
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: qsTr("%1 charts").arg(chartsModel.count)
                                color: root.textMuted
                                font.pixelSize: 11
                            }
                        }

                        ListView {
                            id: chartsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: chartsModel
                            reuseItems: true
                            cacheBuffer: 200

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                width: chartsList.width
                                height: 54
                                radius: 6
                                color: root.cardBackground
                                border.color: root.borderColor
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            text: model.chartTitle || model.chartId
                                            color: root.textPrimary
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Label {
                                            text: (model.chartType || "") + " · " + model.chartId + " · Lines:" + root._countLinesForChart(model.chartId)
                                            color: root.textSecondary
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Button {
                                        text: qsTr("Rename")
                                        Layout.preferredHeight: 28

                                        background: Rectangle {
                                            color: {
                                                if (parent.pressed) return AppTheme.surfaces.muted
                                                if (parent.hovered) return AppTheme.surfaces.card
                                                return AppTheme.surfaces.muted
                                            }
                                            radius: 4
                                            border.color: root.dividerColor
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            font.pixelSize: 11
                                            color: root.textSecondary
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
                                        Layout.preferredHeight: 28

                                        background: Rectangle {
                                            color: {
                                                if (!parent.enabled) return AppTheme.states.disabledBackground
                                                if (parent.pressed) return Qt.darker(AppTheme.palette.danger, 1.2)
                                                if (parent.hovered) return AppTheme.palette.danger
                                                return Qt.lighter(AppTheme.palette.danger, 1.35)
                                            }
                                            radius: 4
                                            border.color: parent.enabled ? Qt.darker(AppTheme.palette.danger, 1.1) : root.dividerColor
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            font.pixelSize: 11
                                            color: parent.enabled ? root.textPrimary : root.textMuted
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: root.removeChartRequested(model.chartId)
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("No charts")
                                color: root.textMuted
                                font.pixelSize: 12
                                visible: chartsList.count === 0
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------
    // Assign signal dialog (set charts)
    // ---------------------------------------------------------
    Dialog {
        id: assignDialog
        title: qsTr("Assign Signal")
        modal: true
        standardButtons: Dialog.NoButton
        parent: Overlay.overlay
        anchors.centerIn: parent

        property string uniqueId: ""

        readonly property int _maxWidth: 460
        readonly property int _maxHeight: 520
        readonly property int _minWidth: 300
        readonly property int _margin: 24
        readonly property int _availableWidth: Math.max(0, (parent ? parent.width : _maxWidth) - (_margin * 2))
        readonly property int _availableHeight: Math.max(0, (parent ? parent.height : _maxHeight) - (_margin * 2))

        implicitWidth: _maxWidth
        implicitHeight: header.height + contentItem.implicitHeight + footer.height

        width: Math.max(
            Math.min(_maxWidth, _availableWidth),
            Math.min(_minWidth, _availableWidth)
        )
        height: Math.min(_maxHeight, implicitHeight, _availableHeight)

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
            implicitWidth: 420
            implicitHeight: 300

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
                    spacing: 8

                    Label {
                        text: root._hasMessageX(assignDialog.uniqueId)
                            ? qsTr("Suggested: Cartesian XY (protocol X → Y)")
                            : qsTr("Suggested: Time series (time → value)")
                        font.pixelSize: 12
                        color: "#cccccc"
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Create")
                        Layout.preferredWidth: 80

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
                            root._requestSuggestedChart(assignDialog.uniqueId, root._getMessageDisplayName(assignDialog.uniqueId))
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
            root.setSignalChartsRequested(assignDialog.uniqueId, selected)
        }
    }

    // ---------------------------------------------------------
    // Create chart dialog
    // ---------------------------------------------------------
    Dialog {
        id: createChartDialog
        title: qsTr("Create chart")
        modal: true
        standardButtons: Dialog.NoButton
        parent: Overlay.overlay
        anchors.centerIn: parent

        property string titleText: ""
        property string chartType: "time_series"

        readonly property int _maxWidth: 520
        readonly property int _maxHeight: 470
        readonly property int _minWidth: 300
        readonly property int _margin: 24
        readonly property int _availableWidth: Math.max(0, (parent ? parent.width : _maxWidth) - (_margin * 2))
        readonly property int _availableHeight: Math.max(0, (parent ? parent.height : _maxHeight) - (_margin * 2))

        implicitWidth: _maxWidth
        implicitHeight: header.height + contentItem.implicitHeight + footer.height

        width: Math.max(
            Math.min(_maxWidth, _availableWidth),
            Math.min(_minWidth, _availableWidth)
        )
        height: Math.min(_maxHeight, implicitHeight, _availableHeight)

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
            implicitWidth: 480
            implicitHeight: 330

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: qsTr("Chart title") + " *"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    TextField {
                        id: newChartTitle
                        Layout.fillWidth: true
                        placeholderText: qsTr("e.g. Motor temperature")
                        text: ""

                        background: Rectangle {
                            color: "#3d3d3d"
                            border.color: newChartTitle.activeFocus ? "#007AFF" : "#606060"
                            border.width: 1
                            radius: 4
                        }

                        color: "#ffffff"
                        placeholderTextColor: root.textMuted
                        font.pixelSize: 13
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: qsTr("Display mode") + " *"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#ffffff"
                    }

                    ButtonGroup { id: chartTypeGroup }

                    RadioButton {
                        id: timeSeriesMode
                        Layout.fillWidth: true
                        text: qsTr("Time series  —  time vs measured value")
                        checked: true
                        ButtonGroup.group: chartTypeGroup
                        onToggled: if (checked) createChartDialog.chartType = "time_series"
                        contentItem: Text {
                            text: parent.text
                            color: root.textPrimary
                            font.pixelSize: 13
                            leftPadding: parent.indicator.width + parent.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RadioButton {
                        Layout.fillWidth: true
                        text: qsTr("Cartesian XY line  —  protocol X vs protocol Y")
                        ButtonGroup.group: chartTypeGroup
                        onToggled: if (checked) createChartDialog.chartType = "xy_line"
                        contentItem: Text {
                            text: parent.text
                            color: root.textPrimary
                            font.pixelSize: 13
                            leftPadding: parent.indicator.width + parent.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RadioButton {
                        Layout.fillWidth: true
                        text: qsTr("Cartesian XY points  —  protocol X vs protocol Y")
                        ButtonGroup.group: chartTypeGroup
                        onToggled: if (checked) createChartDialog.chartType = "xy_scatter"
                        contentItem: Text {
                            text: parent.text
                            color: root.textPrimary
                            font.pixelSize: 13
                            leftPadding: parent.indicator.width + parent.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RadioButton {
                        Layout.fillWidth: true
                        text: qsTr("3D points  —  protocol X, Y and Z")
                        ButtonGroup.group: chartTypeGroup
                        onToggled: if (checked) createChartDialog.chartType = "xyz_scatter"
                        contentItem: Text {
                            text: parent.text
                            color: root.textPrimary
                            font.pixelSize: 13
                            leftPadding: parent.indicator.width + parent.spacing
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: createChartDialog.chartType === "time_series"
                            ? qsTr("The X axis uses elapsed time. Choose X or Y as the measured value when assigning a signal.")
                            : createChartDialog.chartType === "xyz_scatter"
                                ? qsTr("Uses the transmitted X, Y and Z coordinates.")
                                : qsTr("The X axis uses transmitted X; the Y axis uses transmitted Y. Time is not used for either axis.")
                        color: root.textSecondary
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
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
                    text: qsTr("Create chart")
                    Layout.preferredWidth: 120
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
            root.createChartRequested(createChartDialog.chartType, title, "")
            tabBar.currentIndex = 1
        }

        onAboutToShow: {
            newChartTitle.text = ""
            timeSeriesMode.checked = true
            newChartTitle.forceActiveFocus()
        }
    }

    // ---------------------------------------------------------
    // Rename chart dialog
    // ---------------------------------------------------------
    Dialog {
        id: renameChartDialog
        title: qsTr("Rename Chart")
        modal: true
        standardButtons: Dialog.NoButton

        property string chartId: ""
        property string titleText: ""

        width: 460
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
            implicitWidth: 420
            implicitHeight: 140

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
            root.renameChartRequested(renameChartDialog.chartId, title)
        }

        onAboutToShow: {
            renameField.forceActiveFocus()
        }
    }

    // Detail View Dialog
    ChartManagerDialog {
        id: detailDialog

        chartLineModel: root.chartLineModel
        signalModel: root.signalModel
        messageModel: root.messageModel
        availableCharts: root.availableCharts

        onLineVisibilityToggled: function(lineKey, visible) {
            root.lineVisibilityToggled(lineKey, visible)
        }

        onLineSelected: function(lineKey) {
            root.lineSelected(lineKey)
        }

        onAddSignalRequested: {
            root.addSignalRequested()
        }

        onRemoveSignalRequested: function(uniqueId) {
            root.removeSignalRequested(uniqueId)
        }

        onSetSignalChartsRequested: function(uniqueId, assignments) {
            root.setSignalChartsRequested(uniqueId, assignments)
        }

        onCreateChartRequested: function(chartType, chartTitle, chartId) {
            root.createChartRequested(chartType, chartTitle, chartId)
        }

        onRemoveChartRequested: function(chartId) {
            root.removeChartRequested(chartId)
        }

        onRenameChartRequested: function(chartId, chartTitle) {
            root.renameChartRequested(chartId, chartTitle)
        }
    }
}
