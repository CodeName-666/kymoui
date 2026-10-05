import QtQuick 6.4
import QtQuick.Controls 6.4
import QtCharts 2.3
import Backend 1.0
import KymoUi 1.0
import Common 1.0
import "../Models"
import "AddChartLineDialog"
import "EditChartLineDialog"
import "ConnectionManager"



ChartWindowUi{
    id: chartWindow
    objectName: "chartWindow"

    property var appController: App.get_app()
    property var appRoot: null  // Will be set by App.qml on Component.onCompleted
    property var _graphs: ({})  // Legacy: keeping for backward compatibility during transition
    property var chartLineModel: ChartLineModel {}  // New model-based line management
    property var signalModel: SignalModel {}  // Global registry of signals (uniqueId -> metadata)
    property var messageModel: MessageModel {}  // Latest message values/timing (for Messages table)
    property var availableCharts: []
    // The multi-window workspace uses this instance only as a model/controller.
    // Standalone ChartWindow users keep the visible legacy chart by default.
    property bool dataRenderingEnabled: true
    property alias addChartLineDialog: addChartLineDialog
    property alias editChartLineDialog: editChartLineDialog
    property alias connectionManagerDialog: connectionManagerDialog
    property real initialXMin: 0
    property real initialXMax: 10
    property real initialYMin: 0
    property real initialYMax: 10

    // Debug: Monitor chartLinesListCollapsed changes
    onChartLinesListCollapsedChanged: {
        Logger.log_debug("ChartWindow: chartLinesListCollapsed changed to: " + chartLinesListCollapsed)
        Logger.log_debug("ChartWindow: chartLinesList.isCollapsed = " + chartLinesList.isCollapsed)
    }

    onAppRootChanged: {
        refreshAvailableCharts()
    }

    /*******************************************************************
     * EVENT - Chart Controls
     ******************************************************************/
    chartControls.onZoomIn: zoomChart(0.8)      // Zoom in 20%
    chartControls.onZoomOut: zoomChart(1.25)    // Zoom out 25%
    chartControls.onZoomReset: resetZoom()
    chartControls.onZoomFit: fitToData()

    /*******************************************************************
     * EVENT - Y-Axis Controls
     ******************************************************************/
    Connections {
        target: yAxisControls
        function onZoomYIn() {
            zoomYAxis(0.8)  // Zoom Y axis in 20%
        }
        function onZoomYOut() {
            zoomYAxis(1.25)  // Zoom Y axis out 25%
        }
    }

    /*******************************************************************
     * EVENT - Chart Lines List
     ******************************************************************/
    chartLinesList.chartLineModel: chartLineModel
    chartLinesList.signalModel: signalModel

    Connections {
        target: chartLinesList
        function onLineVisibilityToggled(lineKey, visible) {
            Logger.log_info("ChartWindow: Toggle visibility for " + lineKey + " to " + visible)
            chartLineModel.toggleVisibility(lineKey, visible)
        }
        function onLineSelected(lineKey) {
            Logger.log_info("ChartWindow: Line selected: " + lineKey)
            var line = chartLineModel.getLineByKey(lineKey)
            if(line) {
                editChartLineDialog.loadChartLine(lineKey, line.uniqueId, line.displayName, line.color, line.interfaceType, line.dataId, line.chartTitle)
                editChartLineDialog.open()
            }
        }
        function onCollapseToggled() {
            Logger.log_debug("ChartWindow: Collapse button clicked")
            Logger.log_debug("ChartWindow: Current state = " + chartLinesListCollapsed)
            chartLinesListCollapsed = !chartLinesListCollapsed
            Logger.log_debug("ChartWindow: New state = " + chartLinesListCollapsed)
            Logger.log_debug("ChartWindow: isCollapsed in UI = " + chartLinesList.isCollapsed)
        }

        function onAddSignalRequested() {
            addChartLineDialog.open()
        }

        function onRemoveSignalRequested(uniqueId) {
            removeSignal(uniqueId)
        }

        function onSetSignalChartsRequested(uniqueId, assignments) {
            setSignalCharts(uniqueId, assignments)
        }

        function onCreateChartRequested(chartType, chartTitle, chartId) {
            createManagedChart(chartType, chartTitle, chartId)
        }

        function onRemoveChartRequested(chartId) {
            removeManagedChart(chartId)
        }

        function onRenameChartRequested(chartId, chartTitle) {
            renameManagedChart(chartId, chartTitle)
        }
    }

    Connections {
        target: (typeof WindowManager !== "undefined") ? WindowManager : null
        function onWindowCreated(chartId) {
            Qt.callLater(function() { refreshAvailableCharts() })
        }
        function onWindowRemoved(chartId) {
            Qt.callLater(function() { refreshAvailableCharts() })
        }
    }

    /*******************************************************************
     * EVENT - Floating Action Button
     ******************************************************************/
    Connections {
        target: fabButton
        function onClicked() {
            Logger.log_info("ChartWindow: FAB clicked - opening add line dialog")
            addChartLineDialog.open()
        }
    }

    /*******************************************************************
     * EVENT - Backend Connections Changed
     ******************************************************************/
    Connections {
        target: Backend
        function onConnections_changed(connections) {
            Logger.log_debug("ChartWindow: Connections changed - dialog will refresh on next open")
            // No need to do anything here - dialog refreshes on open automatically
        }
    }

    Connections {
        target: chartLineModel
        function onModelChanged() {
            chartWindow._syncSignalModelFromLines()
        }
    }

    /*******************************************************************
     * COMPONENT - Add Chart Line Dialog
     ******************************************************************/
    AddChartLineDialog {
        id: addChartLineDialog
        parent: Overlay.overlay
        anchors.centerIn: parent

        // Note: These are initial values only - dialog refreshes on open
        availableConnections: getAvailableConnections()
        usedDataIds: getUsedDataIds()

        onAboutToShow: {
            // Refresh connection list when dialog opens
            refreshConnectionsList(getAvailableConnections(), getUsedDataIds())
        }

        onChartLineAdded: function(uniqueId, displayName, lineColor, connectionId, dataId, interfaceSettings) {
            Logger.log_info("ChartWindow: Chart line added via dialog: " + uniqueId)

            // Get connection details to retrieve interface type
            var connDetails = Backend.get_connection_details(connectionId)
            var interfaceType = connDetails ? connDetails.type : "Unknown"

            if (signalModel && signalModel.addOrUpdate) {
                signalModel.addOrUpdate(uniqueId, displayName, lineColor, interfaceType, dataId, interfaceSettings)
            }

            // Add to model
            var graph = createGraph(displayName, lineColor)
            chartLineModel.addLine(uniqueId, displayName, lineColor, interfaceType, dataId, interfaceSettings, graph, "main", "Main Chart")

            // Register with backend
            var controller = appController !== undefined && appController !== null ? appController : App.get_app()
            if(controller !== undefined && controller !== null) {
                controller.add_graph(uniqueId, graph)
            }

            // Store in legacy _graphs object
            _graphs[uniqueId] = graph

            Logger.log_info("Chart line successfully added: " + displayName)
        }
    }

    /*******************************************************************
     * COMPONENT - Edit Chart Line Dialog
     ******************************************************************/
    EditChartLineDialog {
        id: editChartLineDialog
        parent: Overlay.overlay
        anchors.centerIn: parent

        onChartLineUpdated: function(lineKey, displayName, lineColor) {
            Logger.log_info("ChartWindow: Chart line updated: " + lineKey)

            var line = chartLineModel.getLineByKey(lineKey)
            if (!line) {
                Logger.log_warning("ChartWindow: Cannot update - line not found: " + lineKey)
                return
            }
            var uniqueId = line.uniqueId

            // Update model
            chartLineModel.updateLinesByUniqueId(uniqueId, {
                "displayName": displayName,
                "color": lineColor
            })

            // Update all series refs for this signal across charts
            for (var i = 0; i < chartLineModel.count; i++) {
                var inst = chartLineModel.get(i)
                if (inst.uniqueId !== uniqueId) continue
                if (!inst.seriesRef) continue
                if (inst.seriesRef.name !== undefined) inst.seriesRef.name = displayName
                if (inst.seriesRef.color !== undefined) inst.seriesRef.color = lineColor
            }

            // Update backend
            var controller = appController !== undefined && appController !== null ? appController : App.get_app()
            if(controller !== undefined && controller !== null) {
                controller.update_chart_line(uniqueId, displayName, lineColor.toString())
            }

            if (signalModel && signalModel.addOrUpdate) {
                signalModel.addOrUpdate(uniqueId, displayName, lineColor, line.interfaceType, line.dataId, line.interfaceSettings)
            }

            Logger.log_info("Chart line successfully updated: " + displayName)
        }

        onChartLineDeleted: function(lineKey) {
            Logger.log_info("ChartWindow: Chart line deleted: " + lineKey)
            removeChartLine(lineKey)
        }
    }

    /*******************************************************************
     * COMPONENT - Connection Manager Dialog
     ******************************************************************/
    ConnectionManagerDialog {
        id: connectionManagerDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
    }


    /*******************************************************************
     * EVENT - Mouse Interactions
     ******************************************************************/
    chartMouseArea.onMouseYChanged: scrollVertical()
    chartMouseArea.onMouseXChanged: scrollHorizontal()
    chartMouseArea.onPressed: scrollButtonClicked()

    /*******************************************************************
     * FUNCTION - Zoom chart by factor (proportional zoom)
     ******************************************************************/
    function zoomAxis(axis, factor) {
        var range = axis.max - axis.min
        var center = (axis.max + axis.min) / 2
        var newRange = range * factor

        axis.min = center - newRange / 2
        axis.max = center + newRange / 2
    }

    function zoomChart(factor) {
        zoomAxis(xAxis, factor)
        zoomAxis(yAxis, factor)
    }

    /*******************************************************************
     * FUNCTION - Zoom only Y axis by factor (proportional zoom)
     ******************************************************************/
    function zoomYAxis(factor) {
        zoomAxis(yAxis, factor)
    }

    /*******************************************************************
     * FUNCTION - Reset zoom to initial view
     ******************************************************************/
    function resetZoom() {
        xAxis.min = initialXMin
        xAxis.max = initialXMax
        yAxis.min = initialYMin
        yAxis.max = initialYMax
    }

    /*******************************************************************
     * FUNCTION - Fit zoom to actual data range
     ******************************************************************/
    function fitToData() {
        // Find data bounds across all graphs
        var minX = Infinity, maxX = -Infinity
        var minY = Infinity, maxY = -Infinity

        for(var graphName in _graphs) {
            var series = _graphs[graphName]
            for(var i = 0; i < series.count; i++) {
                var point = series.at(i)
                minX = Math.min(minX, point.x)
                maxX = Math.max(maxX, point.x)
                minY = Math.min(minY, point.y)
                maxY = Math.max(maxY, point.y)
            }
        }

        // Add 10% padding
        if(minX !== Infinity && maxX !== -Infinity) {
            var xPadding = (maxX - minX) * 0.1
            xAxis.min = minX - xPadding
            xAxis.max = maxX + xPadding
        }

        if(minY !== Infinity && maxY !== -Infinity) {
            var yPadding = (maxY - minY) * 0.1
            yAxis.min = minY - yPadding
            yAxis.max = maxY + yPadding
        }
    }

    /*******************************************************************
     * FUNCTION - Mouse wheel zoom (centered on mouse position)
     ******************************************************************/
    chartMouseArea.onWheel: function(wheel) {
        var factor = wheel.angleDelta.y > 0 ? 0.9 : 1.1

        // Calculate mouse position in chart coordinates
        var plotArea = chart.plotArea
        if (plotArea.width <= 0 || plotArea.height <= 0) {
            return
        }
        var mouseXRatio = (chartMouseArea.mouseX - plotArea.x) / plotArea.width
        var mouseYRatio = (chartMouseArea.mouseY - plotArea.y) / plotArea.height

        var xRange = xAxis.max - xAxis.min
        var yRange = yAxis.max - yAxis.min

        var mouseXValue = xAxis.min + mouseXRatio * xRange
        var mouseYValue = yAxis.max - mouseYRatio * yRange

        var newXRange = xRange * factor
        var newYRange = yRange * factor

        // Zoom centered on mouse position
        xAxis.min = mouseXValue - mouseXRatio * newXRange
        xAxis.max = mouseXValue + (1 - mouseXRatio) * newXRange
        yAxis.min = mouseYValue - (1 - mouseYRatio) * newYRange
        yAxis.max = mouseYValue + mouseYRatio * newYRange
    }

    Component.onCompleted:  {
        var controller = appController !== undefined && appController !== null ? appController : App.get_app()
        if(controller !== undefined && controller !== null)
        {
            var events = controller.events()
            if(events !== undefined && events !== null)
            {
                events.newGraph.connect(newGraph)
                if (chartWindow.dataRenderingEnabled) {
                    events.append_graph_point.connect(appendGraphPoint)
                    events.append_graph_points_batch.connect(appendGraphPointsBatch)
                    events.scrollRight.connect(chart.scrollRight)
                }
                if (events.message_received) {
                    events.message_received.connect(onMessageReceived)
                }
                if (events.signals_removed) {
                    events.signals_removed.connect(onSignalsRemoved)
                }
            }
            if (chartWindow.dataRenderingEnabled) {
                controller.set_plot_area(chart.plotArea)
                controller.set_axis(xAxis,yAxis)
            }
        }
        refreshAvailableCharts()
        _syncSignalModelFromLines()
        Logger.log_debug("CHARTVIEW Completed");
    }

    function onMessageReceived(message) {
        if (!messageModel || !messageModel.addOrUpdateFromBackend) return
        messageModel.addOrUpdateFromBackend(message)
    }

    function onSignalsRemoved(uniqueIds) {
        if (!uniqueIds) return
        for (var i = 0; i < uniqueIds.length; i++) {
            var uniqueId = uniqueIds[i]
            var lineKeys = []
            for (var j = 0; j < chartLineModel.count; j++) {
                var line = chartLineModel.get(j)
                if (line.uniqueId === uniqueId) lineKeys.push(line.lineKey)
            }
            for (var k = 0; k < lineKeys.length; k++) removeChartLine(lineKeys[k])
            if (signalModel && signalModel.removeSignal) signalModel.removeSignal(uniqueId)
            if (messageModel && messageModel.removeMessage) messageModel.removeMessage(uniqueId)

            var controller = appController !== undefined && appController !== null ? appController : App.get_app()
            if (controller !== undefined && controller !== null) controller.remove_chart_line(uniqueId)
        }
    }

    function _extractDataIdFromUniqueId(uniqueId) {
        var parts = uniqueId.split("_")
        var dataId = parts.length > 0 ? parseInt(parts[parts.length - 1]) : 0
        if (isNaN(dataId)) dataId = 0
        return dataId
    }

    function _syncSignalModelFromLines() {
        if (!signalModel || !signalModel.addOrUpdate) return
        for (var i = 0; i < chartLineModel.count; i++) {
            var line = chartLineModel.get(i)
            signalModel.addOrUpdate(line.uniqueId, line.displayName, line.color, line.interfaceType, line.dataId, line.interfaceSettings)
        }
    }

    /*******************************************************************
     * FUNCTION - Create new graph (updated for ID-based system)
     *
     * @param uniqueId - Unique identifier (format: "interface_dataId")
     * @param displayName - User-friendly name
     * @param color - Line color (int or hex string)
     * @param interfaceType - Interface type (Serial, MQTT, etc.)
     ******************************************************************/
    function newGraph(uniqueId, displayName, color, interfaceType) {
        var dataId = _extractDataIdFromUniqueId(uniqueId)
        if (signalModel && signalModel.addOrUpdate) {
            signalModel.addOrUpdate(uniqueId, displayName, color, interfaceType, dataId, {})
        }

        if (!chartWindow.dataRenderingEnabled) {
            return
        }

        // If this uniqueId is already assigned to another chart, don't create it on the main chart.
        if (chartLineModel.hasLineForChart(uniqueId, "main")) {
            Logger.log_debug("ChartWindow.newGraph: Skipping already-registered main line: " + uniqueId)
            return
        }
        if (chartLineModel.hasAnyLine(uniqueId)) {
            Logger.log_debug("ChartWindow.newGraph: Skipping auto-add to main (already assigned elsewhere): " + uniqueId)
            return
        }

        // Create the chart series
        var graph = createGraph(displayName, color);
        Logger.log_info("New Graph created: ID = " + uniqueId + " | Name = " + displayName + " | Color = " + color);

        // Store in legacy _graphs object (for backward compatibility)
        _graphs[uniqueId] = graph

        // Add to new model
        chartLineModel.addLine(uniqueId, displayName, color, interfaceType, dataId, {}, graph, "main", "Main Chart")

        // Register with backend controller
        var controller = appController !== undefined && appController !== null ? appController : App.get_app()
        if(controller !== undefined && controller !== null)
        {
            controller.add_graph(uniqueId, graph);
        }
    }

    /*******************************************************************
     * FUNCTION - Append point to graph (updated for ID-based system)
     *
     * @param uniqueId - Unique identifier of the graph line
     * @param point - Point object with x and y coordinates
     ******************************************************************/
    function appendGraphPoint(uniqueId, point)
    {
        if(!_graphs[uniqueId])
        {
            // Not assigned to the main chart (may be shown in floating windows).
            if (chartLineModel.hasLineForChart(uniqueId, "main")) {
                Logger.log_warning("appendGraphPoint: graph not found for " + uniqueId)
            }
            return
        }
        if(point === undefined)
            return
        var x = point.x !== undefined ? point.x : (point["x"] !== undefined ? point["x"] : 0)
        var y = point.y !== undefined ? point.y : (point["y"] !== undefined ? point["y"] : 0)

        // Check if line is visible before appending
        var line = chartLineModel.getLineForChart(uniqueId, "main")
        if(line && line.visible) {
            var series = _graphs[uniqueId]

            // Performance: Limit maximum points per series
            var maxPoints = 10000
            if(series.count >= maxPoints) {
                // Remove oldest 100 points when limit reached
                series.removePoints(0, 100)
            }

            series.append(x, y)
        }
    }

    /*******************************************************************
     * FUNCTION - Append multiple points at once (BATCH UPDATE)
     *
     * This is much faster than calling appendGraphPoint multiple times
     * as it reduces QML/JavaScript overhead significantly.
     *
     * @param uniqueId - Unique identifier of the graph line
     * @param points - Array of [x, y] tuples
     ******************************************************************/
    function appendGraphPointsBatch(uniqueId, points)
    {
        if(!_graphs[uniqueId])
        {
            // Not assigned to the main chart (may be shown in floating windows).
            if (chartLineModel.hasLineForChart(uniqueId, "main")) {
                Logger.log_warning("appendGraphPointsBatch: graph not found for " + uniqueId)
            }
            return
        }
        if(!points || points.length === 0)
            return

        // Check if line is visible before appending
        var line = chartLineModel.getLineForChart(uniqueId, "main")
        if(line && line.visible) {
            var series = _graphs[uniqueId]
            var maxPoints = 10000

            // Check if we need to remove old points
            var totalAfterAdd = series.count + points.length
            if(totalAfterAdd > maxPoints) {
                var toRemove = totalAfterAdd - maxPoints
                series.removePoints(0, toRemove)
            }

            // Batch append - much faster!
            for(var i = 0; i < points.length; i++) {
                var x = points[i][0]
                var y = points[i][1]
                series.append(x, y)
            }
        }
    }


    /*******************************************************************
     * FUNCTION
     ******************************************************************/
    function createGraph(name, color = undefined) {

        var line = chart.createSeries(ChartView.SeriesTypeLine,
                                              name, xAxis, yAxis)
        if (color === undefined) {
            color = Random.getRandomInt(0xFFFFFF)
        }

        Logger.log_info("Create Graph - Name: " + name + " - Color: " + color);
        return line
    }

    /*******************************************************************
     * @brief: Scroll Horizontal
     *
     * This function use the as key the left mouse button to identify if
     * it should be scrolled or not.
     *
     * To scrool a pixel need to be provided. To do this, a rectangle (horizontalScrollMask)
     * will be used.
     *
     * Used Events:
     * onPressed: Backup current mouse postion an intialize the horizontalScrollMask with it.
     * onMouseXChanged: Calculate the delta beteen the stored horizontalScrollMask position and the current mouse postion.
     *                  This delta value represents the scrolled pixels.After this calculation, update the
     *                  horizontalScrollMask whit the new position for the next delta calculation.
     *
     ******************************************************************/
    function scrollHorizontal() {
        if ((chartMouseArea.pressedButtons & Qt.LeftButton) === Qt.LeftButton) {
            chart.scrollLeft(chartMouseArea.mouseX - horizontalScrollMask.x)

            horizontalScrollMask.x = chartMouseArea.mouseX
        }
    }

    /*******************************************************************
     * @brief: Scroll Vertical
     *
     * This function use the as key the left mouse button to identify if
     * it should be scrolled or not.
     *
     * To scrool a pixel need to be provided. To do this, a rectangle (verticalScrollMask)
     * will be used.
     *
     * Used Events:
     * onPressed: Backup current mouse postion an intialize the verticalScrollMask with it.
     * onMouseYChanged: Calculate the delta beteen the stored verticalScrollMask position and the current mouse postion.
     *                  This delta value represents the scrolled pixels.After this calculation, update the
     *                  verticalScrollMask whit the new position for the next delta calculation.
     *
     ******************************************************************/
    function scrollVertical() {
        if ((chartMouseArea.pressedButtons & Qt.LeftButton) === Qt.LeftButton) {
            chart.scrollUp(chartMouseArea.mouseY - verticalScrollMask.y)
            verticalScrollMask.y = chartMouseArea.mouseY
        }
    }

    /*******************************************************************
     * @brief: Scroll Button Clicked
     *
     * This function use the as key the left mouse button to identify if
     * it should be scrolled or not.
     *
     * To scrool a pixel need to be provided. To do this, a rectangle (verticalScrollMask)
     * will be used.
     *
     * Used Events:
     * onPressed: Backup current mouse postion an intialize the verticalScrollMask with it.
     * onMouseXChanged: Calculate the delta beteen the stored verticalScrollMask position and the current mouse postion.
     *                  This delta value represents the scrolled pixels.After this calculation, update the
     *                  verticalScrollMask whit the new position for the next delta calculation.
     *
     ******************************************************************/
    function scrollButtonClicked() {
        if (chartMouseArea.pressedButtons === Qt.LeftButton) {
            horizontalScrollMask.x = chartMouseArea.mouseX
            verticalScrollMask.y = chartMouseArea.mouseY
        }
    }

    /*******************************************************************
     * FUNCTION - Get available connections from backend
     ******************************************************************/
    function getAvailableConnections() {
        // Get available connections from backend
        if (!Backend) {
            Logger.log_warning("ChartWindow: Backend not available yet")
            return []
        }

        var connections = Backend.get_connections()
        var availableConnections = []

        for (var i = 0; i < connections.length; i++) {
            var conn = connections[i]
            availableConnections.push({
                "id": conn.id,
                "name": conn.name,
                "type": conn.type,
                "status": conn.status
            })
        }

        Logger.log_debug("ChartWindow: Found " + availableConnections.length + " available connections")
        return availableConnections
    }

    /*******************************************************************
     * FUNCTION - Get list of used data IDs (uniqueId format)
     ******************************************************************/
    function getUsedDataIds() {
        return chartLineModel.getAllUniqueIds()
    }

    /*******************************************************************
     * FUNCTION - Remove chart line completely
     ******************************************************************/
    function removeChartLine(lineKey) {
        Logger.log_info("ChartWindow: Removing chart line instance: " + lineKey)

        var line = chartLineModel.getLineByKey(lineKey)
        if (!line) {
            Logger.log_warning("ChartWindow: Cannot remove - line not found: " + lineKey)
            return
        }

        // Remove series from the owning chart
        if (line.chartId === "main") {
            if (line.seriesRef) {
                chart.removeSeries(line.seriesRef)
            }
            if (_graphs[line.uniqueId]) {
                delete _graphs[line.uniqueId]
            }
            chartLineModel.removeLine(lineKey)
            Logger.log_info("ChartWindow: Removed line instance: " + lineKey)
            return
        } else if (chartWindow.appRoot && chartWindow.appRoot.floatingWindowsContainer) {
            var win = chartWindow.appRoot.floatingWindowsContainer.activeWindows[line.chartId]
            if (win && win.unassignSignal) {
                win.unassignSignal(line.uniqueId, line.valueField)
                Logger.log_info("ChartWindow: Removed line instance via chart renderer: " + lineKey)
                return
            }
        }

        // Fallback: remove from model (do NOT remove from backend; other charts may still use it)
        chartLineModel.removeLine(lineKey)
        Logger.log_info("ChartWindow: Removed line instance: " + lineKey)
    }

    /*******************************************************************
     * FUNCTION
     ******************************************************************/
    function setup(settings) {

    }

    function refreshAvailableCharts() {
        var charts = []

        if (chartWindow.dataRenderingEnabled) {
            charts.push({
                "chartId": "main",
                "chartTitle": "Main Chart",
                "chartType": "xy_line"
            })
        }

        if (chartWindow.appRoot && chartWindow.appRoot.floatingWindowsContainer) {
            var wins = chartWindow.appRoot.floatingWindowsContainer.activeWindows
            for (var id in wins) {
                var w = wins[id]
                if (!w) continue
                charts.push({
                    "chartId": id,
                    "chartTitle": w.chartTitle || id,
                    "chartType": w.chartType || "xy_line"
                })
            }
        }

        availableCharts = charts
        if (chartLinesList && chartLinesList.availableCharts !== undefined) {
            chartLinesList.availableCharts = charts
        }
    }

    function removeSignal(uniqueId) {
        Logger.log_info("ChartWindow: Removing signal (ignore): " + uniqueId)

        // Hide on all charts first (remove series + model instances)
        var instances = []
        for (var i = 0; i < chartLineModel.count; i++) {
            var inst = chartLineModel.get(i)
            if (inst.uniqueId === uniqueId) instances.push(inst.lineKey)
        }
        for (var j = 0; j < instances.length; j++) {
            removeChartLine(instances[j])
        }

        // Tell backend to ignore this signal so it doesn't auto-reappear
        if (Backend.set_signal_ignored) {
            Backend.set_signal_ignored(uniqueId, true)
        }

        if (signalModel && signalModel.removeSignal) {
            signalModel.removeSignal(uniqueId)
        }

        var controller = appController !== undefined && appController !== null ? appController : App.get_app()
        if (controller !== undefined && controller !== null) {
            controller.remove_chart_line(uniqueId)
        }
    }

    function _getChartTypeForId(chartId) {
        for (var i = 0; i < availableCharts.length; i++) {
            if (availableCharts[i].chartId === chartId) {
                return availableCharts[i].chartType || ""
            }
        }
        return ""
    }

    function _buildAssignmentKey(chartId, chartType, valueField) {
        if (chartType === "time_series" || (valueField !== undefined && valueField !== null && valueField !== "")) {
            return chartId + "::" + (valueField || "y")
        }
        return chartId
    }

    function setSignalCharts(uniqueId, assignments) {
        Logger.log_info("ChartWindow: Setting signal charts for " + uniqueId + " -> " + JSON.stringify(assignments))

        if (Backend.set_signal_ignored) {
            Backend.set_signal_ignored(uniqueId, false)
        }

        if (!assignments) {
            assignments = []
        }

        if (assignments.length > 0 && typeof assignments[0] === "string") {
            var converted = []
            for (var c = 0; c < assignments.length; c++) {
                converted.push({ "chartId": assignments[c] })
            }
            assignments = converted
        }

        var desired = ({})
        for (var i = 0; i < assignments.length; i++) {
            var assign = assignments[i]
            if (!assign || !assign.chartId) continue
            var chartId = assign.chartId
            if (chartId === "main" && !chartWindow.dataRenderingEnabled) continue
            var chartType = assign.chartType || _getChartTypeForId(chartId)
            var valueField = assign.valueField
            if (!chartType && valueField) {
                chartType = "time_series"
            }
            if (chartType === "time_series") {
                valueField = valueField || "y"
            } else {
                valueField = null
            }
            var key = _buildAssignmentKey(chartId, chartType, valueField)
            desired[key] = {
                chartId: chartId,
                chartType: chartType,
                valueField: valueField
            }
        }

        // Unassign from charts that are no longer selected
        var toRemove = []
        for (var j = 0; j < chartLineModel.count; j++) {
            var inst = chartLineModel.get(j)
            if (inst.uniqueId !== uniqueId) continue
            var instType = _getChartTypeForId(inst.chartId)
            var instKey = _buildAssignmentKey(inst.chartId, instType, inst.valueField)
            if (!desired[instKey]) toRemove.push(inst.lineKey)
        }
        for (var r = 0; r < toRemove.length; r++) {
            removeChartLine(toRemove[r])
        }

        // Need a template line (name/color/interface/dataId) to assign to new charts
        var baseLine = chartLineModel.getLine(uniqueId)
        if (!baseLine && signalModel && signalModel.getSignal) {
            baseLine = signalModel.getSignal(uniqueId)
        }
        if (!baseLine) {
            Logger.log_warning("ChartWindow: Cannot assign unknown signal (create it first): " + uniqueId)
            return
        }

        // Assign to newly selected charts
        for (var desiredKey in desired) {
            var assignment = desired[desiredKey]
            var chartId = assignment.chartId
            var chartType = assignment.chartType
            var valueField = assignment.valueField
            if (chartLineModel.hasLineForChart(uniqueId, chartId, valueField)) continue

            if (chartId === "main") {
                var graph = createGraph(baseLine.displayName, baseLine.color)
                _graphs[uniqueId] = graph
                chartLineModel.addLine(uniqueId, baseLine.displayName, baseLine.color, baseLine.interfaceType, baseLine.dataId, baseLine.interfaceSettings, graph, "main", "Main Chart")

                var controller = appController !== undefined && appController !== null ? appController : App.get_app()
                if (controller !== undefined && controller !== null) {
                    controller.add_graph(uniqueId, graph)
                }
                continue
            }

            if (chartWindow.appRoot && chartWindow.appRoot.floatingWindowsContainer) {
                var win = chartWindow.appRoot.floatingWindowsContainer.activeWindows[chartId]
                if (win && win.assignSignal) {
                    win.assignSignal(uniqueId, baseLine.displayName, baseLine.color, baseLine.interfaceType, baseLine.dataId, valueField)
                }
            }
        }
    }

    function createManagedChart(chartType, chartTitle, chartId) {
        if (!chartWindow.appRoot || !chartWindow.appRoot.createFloatingWindow) return
        var resolvedId = chartId && chartId !== "" ? chartId : ("chart_" + chartType + "_" + Date.now())
        chartWindow.appRoot.createFloatingWindow(resolvedId, chartType, chartTitle, 140, 140, 800, 600)
        refreshAvailableCharts()
    }

    function removeManagedChart(chartId) {
        if (chartId === "main") return
        if (!chartWindow.appRoot || !chartWindow.appRoot.removeFloatingWindow) return
        chartWindow.appRoot.removeFloatingWindow(chartId)
        refreshAvailableCharts()
    }

    function renameManagedChart(chartId, chartTitle) {
        if (chartId === "main") return
        if (chartWindow.appRoot && chartWindow.appRoot.floatingWindowsContainer) {
            var win = chartWindow.appRoot.floatingWindowsContainer.activeWindows[chartId]
            if (win) win.chartTitle = chartTitle
        }
        if (chartLineModel.updateChartTitle) {
            chartLineModel.updateChartTitle(chartId, chartTitle)
        }
        refreshAvailableCharts()
    }

    /*******************************************************************
     * FUNCTION - Test Floating Window System
     ******************************************************************/
    function testFloatingWindow() {
        Logger.log_info("ChartWindow: Starting Test 2D flow (backend Test interface -> chart -> signals)")

        // Get App instance to call createFloatingWindow
        var app = chartWindow.appRoot

        // Fallback: Try parent search if appRoot not set
        if (app === null) {
            var p = parent
            while (p !== null) {
                if (p.createFloatingWindow !== undefined) {
                    app = p
                    break
                }
                p = p.parent
            }
        }

        if (app === null || app.createFloatingWindow === undefined) {
            Logger.log_error("ChartWindow: Cannot find App.createFloatingWindow function")
            Logger.log_error("ChartWindow: Please ensure chartWindow.appRoot is set by App.qml")
            return
        }

        Logger.log_debug("ChartWindow: Found app instance, creating test window")

        var timestamp = Date.now()
        var chartId = "test_2d_" + timestamp

        // 1) Create backend communication interface first (Test)
        var testSettings = {
            "type": "Multi",
            "use_timestamp": true,
            "sample_ms": 50
        }

        var connectionId = Backend.create_connection("Test", "Test 2D " + timestamp, testSettings)
        if (!connectionId || connectionId === "") {
            Logger.log_error("ChartWindow: Failed to create Test connection")
            return
        }

        var window = app.createFloatingWindow(
            chartId,
            "xy_line",
            "Test 2D Chart " + timestamp,
            150,
            150,
            700,
            500
        )

        if (window === null) {
            Logger.log_error("ChartWindow: Failed to create floating window")
            return
        }

        // Store connection on window so it can be cleaned up on close
        window.connectionId = connectionId
        window.autoDeleteConnectionOnClose = true

        Logger.log_info("ChartWindow: Floating window created, binding 3 Test signals...")

        function tryInitSignals(attemptsLeft) {
            if (!window || !window.chartRenderer) {
                if (attemptsLeft > 0) return Qt.callLater(function() { tryInitSignals(attemptsLeft - 1) })
                Logger.log_error("ChartWindow: Chart renderer not available (timeout)")
                return
            }

                // Ensure central model is present before creating lines
                if (!window.chartRenderer.chartLineModel) {
                    window.chartRenderer.chartLineModel = chartLineModel
                }

                // Make Test 2D signals immediately visible (sine/cos span negative and positive values)
                if (window.chartRenderer.initialYMin !== undefined) window.chartRenderer.initialYMin = -12
                if (window.chartRenderer.initialYMax !== undefined) window.chartRenderer.initialYMax = 12

                var templates = Backend.get_test_signal_templates ? Backend.get_test_signal_templates() : []
                if (!templates || templates.length === 0) {
                    // Fallback if backend doesn't provide templates
                    templates = [
                        {"dataId": 0, "displayName": "Sine Wave", "color": "#ff6b6b"},
                    {"dataId": 1, "displayName": "Cosine Wave", "color": "#4ecdc4"},
                    {"dataId": 2, "displayName": "Sine Wave (2x)", "color": "#ffe66d"}
                ]
            }

            for (var i = 0; i < templates.length; i++) {
                var tpl = templates[i]
                var dataId = tpl.dataId
                var uniqueId = connectionId + "_" + dataId
                window.chartRenderer.createLine(uniqueId, tpl.displayName, tpl.color, "Test", dataId)
            }

            // 3) Start the connection after chart + signals exist
            Backend.start_connection(connectionId)
            Logger.log_info("ChartWindow: Test connection started: " + connectionId)
        }

        tryInitSignals(20)
    }

    /**
     * Test function for XY plots (explicit X/Y from connection).
     * Creates a 2D scatter plot and feeds it with {"id":0,"x":...,"y":...} samples.
     */
    function testFloatingWindowXY() {
        Logger.log_info("ChartWindow: Starting Test XY flow (backend Test interface -> XY scatter)")

        // Get App instance to call createFloatingWindow
        var app = chartWindow.appRoot
        if (app === null) {
            var p = parent
            while (p !== null) {
                if (p.createFloatingWindow !== undefined) {
                    app = p
                    break
                }
                p = p.parent
            }
        }

        if (app === null || app.createFloatingWindow === undefined) {
            Logger.log_error("ChartWindow: Cannot find App.createFloatingWindow function")
            Logger.log_error("ChartWindow: Please ensure chartWindow.appRoot is set by App.qml")
            return
        }

        var timestamp = Date.now()
        var chartId = "test_xy_" + timestamp

        // 1) Create backend communication interface (Test)
        var testSettings = {
            "type": "XYCircle",
            "id": 0,
            "radius": 10.0,
            "frequency": 0.2,
            "sample_ms": 30
        }

        var connectionId = Backend.create_connection("Test", "Test XY " + timestamp, testSettings)
        if (!connectionId || connectionId === "") {
            Logger.log_error("ChartWindow: Failed to create Test connection for XY")
            return
        }

        var window = app.createFloatingWindow(
            chartId,
            "xy_scatter",
            "Test XY Chart " + timestamp,
            180,
            180,
            700,
            500
        )

        if (window === null) {
            Logger.log_error("ChartWindow: Failed to create floating window for XY")
            return
        }

        window.connectionId = connectionId
        window.autoDeleteConnectionOnClose = true

        function tryInitSignals(attemptsLeft) {
            if (!window || !window.chartRenderer) {
                if (attemptsLeft > 0) return Qt.callLater(function() { tryInitSignals(attemptsLeft - 1) })
                Logger.log_error("ChartWindow: Chart renderer not available for XY (timeout)")
                return
            }

            // Ensure central model is present before creating lines
            if (!window.chartRenderer.chartLineModel) {
                window.chartRenderer.chartLineModel = chartLineModel
            }

            // Make coordinate system visible immediately
            if (window.chartRenderer.initialXMin !== undefined) window.chartRenderer.initialXMin = -12
            if (window.chartRenderer.initialXMax !== undefined) window.chartRenderer.initialXMax = 12
            if (window.chartRenderer.initialYMin !== undefined) window.chartRenderer.initialYMin = -12
            if (window.chartRenderer.initialYMax !== undefined) window.chartRenderer.initialYMax = 12

            var uniqueId = connectionId + "_0"
            window.chartRenderer.createLine(uniqueId, "XY Circle", "#ff6b6b", "Test", 0)

            Backend.start_connection(connectionId)
            Logger.log_info("ChartWindow: Test XY connection started: " + connectionId)
        }

        tryInitSignals(20)
    }

    /**
     * Test function for XY plots with 3 signals (explicit X/Y per signal).
     * Creates a 2D chart and feeds it with {"id":0|1|2,"x":...,"y":...} samples.
     */
    function testFloatingWindowXYMulti() {
        Logger.log_info("ChartWindow: Starting Test 2D X/Y flow (3 XY signals)")

        // Get App instance to call createFloatingWindow
        var app = chartWindow.appRoot
        if (app === null) {
            var p = parent
            while (p !== null) {
                if (p.createFloatingWindow !== undefined) {
                    app = p
                    break
                }
                p = p.parent
            }
        }

        if (app === null || app.createFloatingWindow === undefined) {
            Logger.log_error("ChartWindow: Cannot find App.createFloatingWindow function")
            Logger.log_error("ChartWindow: Please ensure chartWindow.appRoot is set by App.qml")
            return
        }

        var timestamp = Date.now()
        var chartId = "test_xy_multi_" + timestamp

        // 1) Create backend communication interface (Test)
        var testSettings = {
            "type": "XYMulti",
            "radius": 10.0,
            "sample_ms": 30
        }

        var connectionId = Backend.create_connection("Test", "Test 2D X/Y " + timestamp, testSettings)
        if (!connectionId || connectionId === "") {
            Logger.log_error("ChartWindow: Failed to create Test connection for XY multi")
            return
        }

        // Use a line chart here so the XY trajectory becomes visible.
        var window = app.createFloatingWindow(
            chartId,
            "xy_line",
            "Test 2D X/Y Chart " + timestamp,
            200,
            200,
            750,
            520
        )

        if (window === null) {
            Logger.log_error("ChartWindow: Failed to create floating window for XY multi")
            return
        }

        window.connectionId = connectionId
        window.autoDeleteConnectionOnClose = true

        function tryInitSignals(attemptsLeft) {
            if (!window || !window.chartRenderer) {
                if (attemptsLeft > 0) return Qt.callLater(function() { tryInitSignals(attemptsLeft - 1) })
                Logger.log_error("ChartWindow: Chart renderer not available for XY multi (timeout)")
                return
            }

            // Ensure central model is present before creating lines
            if (!window.chartRenderer.chartLineModel) {
                window.chartRenderer.chartLineModel = chartLineModel
            }

            // Make coordinate system visible immediately
            if (window.chartRenderer.initialXMin !== undefined) window.chartRenderer.initialXMin = -12
            if (window.chartRenderer.initialXMax !== undefined) window.chartRenderer.initialXMax = 12
            if (window.chartRenderer.initialYMin !== undefined) window.chartRenderer.initialYMin = -12
            if (window.chartRenderer.initialYMax !== undefined) window.chartRenderer.initialYMax = 12

            var templates = [
                {"dataId": 0, "displayName": "XY Circle", "color": "#ff6b6b"},
                {"dataId": 1, "displayName": "XY Lissajous", "color": "#4ecdc4"},
                {"dataId": 2, "displayName": "XY Spiral", "color": "#ffe66d"}
            ]

            for (var i = 0; i < templates.length; i++) {
                var tpl = templates[i]
                var uniqueId = connectionId + "_" + tpl.dataId
                window.chartRenderer.createLine(uniqueId, tpl.displayName, tpl.color, "Test", tpl.dataId)
            }

            Backend.start_connection(connectionId)
            Logger.log_info("ChartWindow: Test 2D X/Y connection started: " + connectionId)
        }

        tryInitSignals(20)
    }

    /**
     * Test function for 3D floating windows
     * Creates a 3D scatter plot with sample data (helix, sphere, random points)
     */
    function test3DFloatingWindow() {
        Logger.log_info("ChartWindow: Testing 3D floating window system")

        // Get App instance to call createFloatingWindow
        var app = chartWindow.appRoot

        // Fallback: Try parent search if appRoot not set
        if (app === null) {
            var p = parent
            while (p !== null) {
                if (p.createFloatingWindow !== undefined) {
                    app = p
                    break
                }
                p = p.parent
            }
        }

        if (app === null || app.createFloatingWindow === undefined) {
            Logger.log_error("ChartWindow: Cannot find App.createFloatingWindow function")
            Logger.log_error("ChartWindow: Please ensure chartWindow.appRoot is set by App.qml")
            return
        }

        Logger.log_debug("ChartWindow: Found app instance, creating 3D test window")

        // Create test 3D floating window
        var timestamp = Date.now()
        var chartId = "test_3d_" + timestamp

        var window = app.createFloatingWindow(
            chartId,
            "xyz_scatter",
            "3D Test Chart " + timestamp,
            200,
            100,
            800,
            600
        )

        if (window === null) {
            Logger.log_error("ChartWindow: Failed to create 3D floating window")
            return
        }

        Logger.log_info("ChartWindow: 3D floating window created, adding test data...")

        // Wait for renderer to be ready
        Qt.callLater(function() {
            if (window.chartRenderer) {
                // Create scatter plots
                window.chartRenderer.createScatterPlot("helix", "Helix", "#ff6b6b")
                window.chartRenderer.createScatterPlot("sphere", "Sphere", "#4ecdc4")
                window.chartRenderer.createScatterPlot("random", "Random Points", "#ffe66d")

                // Generate helix data
                var helixData = []
                for (var t = 0; t < 100; t++) {
                    var angle = t * 0.2
                    helixData.push([
                        Math.cos(angle) * 5,
                        t * 0.2 - 10,
                        Math.sin(angle) * 5
                    ])
                }

                // Generate sphere data (Fibonacci sphere)
                var sphereData = []
                var numPoints = 200
                var goldenRatio = (1 + Math.sqrt(5)) / 2
                for (var i = 0; i < numPoints; i++) {
                    var theta = 2 * Math.PI * i / goldenRatio
                    var phi = Math.acos(1 - 2 * (i + 0.5) / numPoints)
                    var radius = 8
                    sphereData.push([
                        radius * Math.cos(theta) * Math.sin(phi),
                        radius * Math.sin(theta) * Math.sin(phi),
                        radius * Math.cos(phi)
                    ])
                }

                // Generate random scattered points
                var randomData = []
                for (var j = 0; j < 100; j++) {
                    randomData.push([
                        (Math.random() - 0.5) * 20,
                        (Math.random() - 0.5) * 20,
                        (Math.random() - 0.5) * 20
                    ])
                }

                // Add data in batches (fast!)
                window.chartRenderer.appendPointsBatch3D("helix", helixData)
                window.chartRenderer.appendPointsBatch3D("sphere", sphereData)
                window.chartRenderer.appendPointsBatch3D("random", randomData)

                Logger.log_info("ChartWindow: 3D test data added successfully (" +
                    (helixData.length + sphereData.length + randomData.length) + " points)")
            } else {
                Logger.log_error("ChartWindow: 3D chart renderer not available")
            }
        })
    }
}
