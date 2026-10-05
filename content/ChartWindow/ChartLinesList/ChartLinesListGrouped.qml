import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0
import Backend 1.0
import Theme 1.0

/**
 * ChartLinesListGrouped.qml
 *
 * Grouped chart lines list that shows lines organized by chart.
 * Each chart gets its own collapsible box with its lines.
 */
Item {
    id: root

    // Signals
    signal lineVisibilityToggled(string uniqueId, bool visible)
    signal lineSelected(string uniqueId)
    signal collapseToggled()

    // Properties
    property alias scrollView: scrollView
    property var chartLineModel: null
    property bool isCollapsed: false
    property bool embedded: false

    readonly property color panelBackground: AppTheme.surfaces.interfaceBackground
    readonly property color cardBackground: AppTheme.surfaces.card
    readonly property color borderColor: AppTheme.borders.primary
    readonly property color dividerColor: AppTheme.borders.subtle
    readonly property color textPrimary: AppTheme.text.primary
    readonly property color textSecondary: AppTheme.text.secondary
    readonly property color textMuted: AppTheme.text.placeholder
    readonly property color accent: AppTheme.palette.primary
    readonly property color accentHover: AppTheme.palette.primaryHover
    readonly property color accentPressed: AppTheme.palette.primaryPressed
    readonly property color accentBorder: AppTheme.palette.primaryBorder

    // Internal: Track which chart groups are collapsed
    property var collapsedCharts: ({})

    // Internal: Track delegates that need updating
    property int updateTrigger: 0

    Rectangle {
        anchors.fill: parent
        color: root.panelBackground
        border.color: root.borderColor
        border.width: 1
        radius: 8

        // Collapsed state - just the button centered
        Button {
            id: collapseButton
            visible: root.isCollapsed && !root.embedded
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
            anchors.margins: root.embedded ? 0 : 8
            spacing: 8
            visible: root.embedded ? true : !root.isCollapsed

            // Header with collapse button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: !root.embedded

                Label {
                    id: headerLabel
                    text: qsTr("Chart Lines")
                    font.pixelSize: 14
                    font.bold: true
                    color: root.textPrimary
                    Layout.fillWidth: true
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

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.dividerColor
                visible: !root.embedded
            }

            // Scrollable area with grouped chart boxes
            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                ColumnLayout {
                    width: scrollView.availableWidth
                    spacing: 12

                    Repeater {
                        id: chartGroupRepeater
                        model: ListModel { id: chartsListModel }

                        // Each chart group box
                        delegate: Rectangle {
                            id: chartDelegate
                            Layout.fillWidth: true
                            // Use implicitHeight to avoid a binding loop with anchors.fill
                            Layout.preferredHeight: chartGroupColumn.implicitHeight + 20
                            color: root.cardBackground
                            border.color: root.borderColor
                            border.width: 1
                            radius: 6

                            // ListModel for this chart's lines
                            ListModel {
                                id: chartLinesModel
                            }

                            // Store chartId for access in Connections
                            property string currentChartId: model.chartId

                            Component.onCompleted: {
                                root.updateLinesModel(chartLinesModel, currentChartId)
                            }

                            // Update when global trigger changes
                            Connections {
                                target: root
                                function onUpdateTriggerChanged() {
                                    root.updateLinesModel(chartLinesModel, chartDelegate.currentChartId)
                                }
                            }

                            ColumnLayout {
                                id: chartGroupColumn
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                // Chart header
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Collapse/Expand button for this chart group
                                    ToolButton {
                                        id: chartCollapseBtn
                                        text: isChartCollapsed(model.chartId) ? "▶" : "▼"
                                        font.pixelSize: 10
                                        width: 24
                                        height: 24

                                        background: Rectangle {
                                            color: parent.hovered ? root.dividerColor : "transparent"
                                            radius: 3
                                        }

                                        onClicked: toggleChartCollapse(model.chartId)
                                    }

                                    // Chart title
                                    Label {
                                        text: shortenChartTitle(model.chartTitle || "Unknown Chart")
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Line count badge
                                    Rectangle {
                                        width: countLabel.width + 12
                                        height: 20
                                        radius: 10
                                        color: AppTheme.surfaces.muted
                                        border.color: root.accentBorder
                                        border.width: 1

                                        Label {
                                            id: countLabel
                                            anchors.centerIn: parent
                                            text: model.lineCount.toString()
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.accent
                                        }
                                    }
                                }

                                // Separator
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: root.dividerColor
                                    visible: !isChartCollapsed(model.chartId)
                                }

                                // Lines for this chart
                                Repeater {
                                    model: chartLinesModel

                                    delegate: Item {
                                        id: lineItem
                                        visible: !isChartCollapsed(chartDelegate.currentChartId)
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40

                                        // Required properties for ListModel delegate
                                        required property string uniqueId
                                        required property string lineKey
                                        required property string displayName
                                        required property string color
                                        required property bool lineVisible
                                        required property string dataId
                                        required property string interfaceType

                                        Rectangle {
                                            anchors.fill: parent
                                            color: mouseArea.containsMouse ? AppTheme.surfaces.muted : "transparent"
                                            radius: 4
                                            border.color: lineItem.lineVisible ? root.accentBorder : "transparent"
                                            border.width: lineItem.lineVisible ? 1 : 0

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 8

                                                // Color indicator
                                                Rectangle {
                                                    width: 20
                                                    height: 20
                                                    radius: 10
                                                    color: lineItem.color
                                                    border.color: root.borderColor
                                                    border.width: 1
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                // Display name
                                                Label {
                                                    text: lineItem.displayName
                                                    color: lineItem.lineVisible ? root.textPrimary : root.textMuted
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                // Data ID badge
                                                Rectangle {
                                                    width: idLabel.width + 12
                                                    height: 20
                                                    radius: 3
                                                    color: AppTheme.surfaces.muted
                                                    Layout.alignment: Qt.AlignVCenter
                                                    visible: lineItem.dataId !== undefined && lineItem.dataId !== ""

                                                    Label {
                                                        id: idLabel
                                                        anchors.centerIn: parent
                                                        text: "ID:" + lineItem.dataId
                                                        color: root.textSecondary
                                                        font.pixelSize: 10
                                                    }
                                                }

                                                // Interface type badge
                                                Rectangle {
                                                    width: typeLabel.width + 12
                                                    height: 20
                                                    radius: 3
                                                    color: AppTheme.surfaces.muted
                                                    Layout.alignment: Qt.AlignVCenter

                                                    Label {
                                                        id: typeLabel
                                                        anchors.centerIn: parent
                                                        text: lineItem.interfaceType
                                                        color: root.textSecondary
                                                        font.pixelSize: 10
                                                    }
                                                }

                                                // Visibility toggle button
                                                Button {
                                                    id: visibilityButton
                                                    width: 30
                                                    height: 30
                                                    Layout.alignment: Qt.AlignVCenter

                                                    background: Rectangle {
                                                        color: visibilityButton.hovered ? AppTheme.surfaces.muted : "transparent"
                                                        radius: 3
                                                    }

                                                    contentItem: Text {
                                                        text: lineItem.lineVisible ? "\u{1F441}" : "\u{1F441}\u{FE0F}"
                                                        font.pixelSize: 16
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                        color: lineItem.lineVisible ? root.accent : root.textMuted
                                                    }

                                                        onClicked: {
                                                            Logger.log_debug("ChartLinesListGrouped: Toggling visibility for " + lineItem.lineKey)
                                                            root.lineVisibilityToggled(lineItem.lineKey, !lineItem.lineVisible)
                                                        }
                                                    }
                                            }

                                            MouseArea {
                                                id: mouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: true
                                                z: -1

                                                onClicked: {
                                                    Logger.log_debug("ChartLinesListGrouped: Line selected: " + lineItem.lineKey)
                                                    root.lineSelected(lineItem.lineKey)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Empty state for this chart
                                Label {
                                    text: qsTr("No lines in this chart")
                                    color: root.textMuted
                                    font.pixelSize: 11
                                    font.italic: true
                                    Layout.fillWidth: true
                                    Layout.topMargin: 8
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: !isChartCollapsed(model.chartId) && model.lineCount === 0
                                }
                            }
                        }
                    }

                    // Global empty state
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: chartGroupRepeater.count === 0

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("No chart lines")
                            color: root.textMuted
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    /*******************************************************************
     * FUNCTIONS - Chart Grouping Logic
     ******************************************************************/

    /**
     * Shorten chart title by removing/abbreviating long timestamp numbers
     * Examples:
     *   "Test 2D Chart 1765920838229" -> "Test 2D #229"
     *   "Main Chart" -> "Main Chart"
     *   "Float XY 1765920838229" -> "Float XY #229"
     */
    function shortenChartTitle(title) {
        if (!title) return "Unknown"

        // Pattern: Extract text before long number and last 3 digits
        var match = title.match(/^(.+?)\s*(\d{10,})$/)
        if (match) {
            var prefix = match[1].trim()
            var number = match[2]
            var shortNum = number.slice(-3)  // Last 3 digits
            return prefix + " #" + shortNum
        }

        return title
    }

    /**
     * Update a specific chart's line model
     */
    function updateLinesModel(linesModel, chartId) {
        if (!root.chartLineModel || !linesModel) return

        linesModel.clear()
        for (var i = 0; i < root.chartLineModel.count; i++) {
            var line = root.chartLineModel.get(i)
            if ((line.chartId || "main") === chartId) {
                linesModel.append({
                    lineKey: line.lineKey,
                    uniqueId: line.uniqueId,
                    displayName: line.displayName,
                    color: line.color,
                    lineVisible: line.visible,
                    dataId: line.dataId,
                    interfaceType: line.interfaceType
                })
            }
        }
    }

    /**
     * Update the charts list model
     */
    function updateChartsList() {
        if (!root.chartLineModel) return

        // Build chart info map
        var charts = {}
        for (var i = 0; i < root.chartLineModel.count; i++) {
            var line = root.chartLineModel.get(i)
            var chartId = line.chartId || "main"
            if (chartId === "main") continue

            if (!charts[chartId]) {
                charts[chartId] = {
                    chartId: chartId,
                    chartTitle: line.chartTitle || "Main Chart",
                    lineCount: 0
                }
            }
            charts[chartId].lineCount++
        }

        // Convert to sorted array
        var chartArray = []
        for (var id in charts) {
            chartArray.push(charts[id])
        }

        // Sort alphabetically by title
        chartArray.sort(function(a, b) {
            return a.chartTitle.localeCompare(b.chartTitle)
        })

        // Update ListModel
        chartsListModel.clear()
        for (var j = 0; j < chartArray.length; j++) {
            chartsListModel.append(chartArray[j])
        }

        // Trigger update of line models in all delegates
        root.updateTrigger++
    }

    /**
     * Get all lines for a specific chart
     */
    function getLinesForChart(chartId) {
        if (!root.chartLineModel) return []

        var lines = []
        for (var i = 0; i < root.chartLineModel.count; i++) {
            var line = root.chartLineModel.get(i)
            if ((line.chartId || "main") === chartId) {
                lines.push(line)
            }
        }
        return lines
    }

    /**
     * Check if a chart group is collapsed
     */
    function isChartCollapsed(chartId) {
        return root.collapsedCharts[chartId] === true
    }

    /**
     * Toggle collapse state of a chart group
     */
    function toggleChartCollapse(chartId) {
        var newState = !isChartCollapsed(chartId)
        var newCollapsed = Object.assign({}, root.collapsedCharts)
        newCollapsed[chartId] = newState
        root.collapsedCharts = newCollapsed

        Logger.log_debug("ChartLinesListGrouped: Chart " + chartId + " collapsed: " + newState)
    }

    // Monitor model changes to refresh view
    Connections {
        target: root.chartLineModel
        function onCountChanged() {
            updateChartsList()
        }
        function onModelChanged() {
            updateChartsList()
        }
    }

    // Monitor chartLineModel property changes
    onChartLineModelChanged: {
        updateChartsList()
    }

    Component.onCompleted: {
        updateChartsList()
    }
}
