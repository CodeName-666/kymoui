import QtQuick 6.4
import QtQuick.Controls 6.4
import QtCharts 2.3
import Theme 1.0

/**
 * TimeSeriesRenderer.qml
 *
 * Time Series Chart renderer for floating windows.
 * Displays Y values cyclically over time with automatic time axis management.
 * Perfect for monitoring single data streams in real-time.
 *
 * Features:
 * - Automatic time axis (X) management
 * - Configurable time window (default: 60 seconds)
 * - Auto-scrolling as new data arrives
 * - Multiple lines/signals supported
 * - Zoom and pan functionality
 *
 * Expected properties from parent FloatingChartWindow:
 * - chartId: Unique identifier for this chart instance
 * - chartTitle: Display name for the chart
 */
Item {
    id: root

    // Public properties that can be set by parent
    property string chartId: ""
    property string chartTitle: "Time Series"
    property var chartData: null  // Reference to chart data model

    // Time Series specific configuration
    property real timeWindow: 60.0  // Time window in seconds (default: 60s)
    property bool autoScroll: true  // Auto-scroll as new data arrives
    property bool autoScaleY: true  // Auto-scale Y axis to fit data
    property real initialYMin: 0
    property real initialYMax: 10
    property bool updatesSuspended: false

    // Internal state
    property var _graphs: ({})  // Dictionary of line series by lineKey
    property var _graphsByUniqueId: ({})  // uniqueId -> [lineKey]
    property real _currentTime: 0  // Current time position (in seconds)
    property real _startTime: 0    // Start time of visible window
    property var _pendingPoints: ({})
    property int maxPendingPointsPerSignal: 2000

    onUpdatesSuspendedChanged: {
        if (!updatesSuspended) flushPendingPoints()
    }
    // Axis scans touch every visible point. Coalesce them so high-frequency
    // batches do not rescan the complete series for every delivery.
    Timer {
        id: yAxisUpdateTimer
        interval: 125
        repeat: false
        onTriggered: if (root.autoScaleY) root.updateYAxisRange()
    }

    // Chart view component
    ChartView {
        id: chart
        anchors.fill: parent
        // QtCharts antialiasing is expensive for continuously changing series.
        antialiasing: false
        backgroundColor: AppTheme.surfaces.interfaceBackground
        legend.visible: true
        legend.alignment: Qt.AlignBottom
        legend.labelColor: AppTheme.text.primary
        legend.font.pixelSize: 11

        theme: ChartView.ChartThemeDark
        animationOptions: ChartView.NoAnimation  // Better performance

        // Time Axis (X)
        ValueAxis {
            id: timeAxis
            min: 0
            max: root.timeWindow
            labelFormat: "%.1f s"
            labelsFont.pixelSize: 10
            labelsColor: AppTheme.text.secondary
            gridLineColor: AppTheme.borders.subtle
            minorGridLineColor: AppTheme.surfaces.muted
            titleText: "Time (s)"
            titleFont.pixelSize: 11
            titleFont.bold: true
        }

        // Value Axis (Y)
        ValueAxis {
            id: valueAxis
            min: root.initialYMin
            max: root.initialYMax
            labelFormat: "%.2f"
            labelsFont.pixelSize: 10
            labelsColor: AppTheme.text.secondary
            gridLineColor: AppTheme.borders.subtle
            minorGridLineColor: AppTheme.surfaces.muted
            titleText: "Value"
            titleFont.pixelSize: 11
            titleFont.bold: true
        }

        // Mouse interaction area
        MouseArea {
            id: chartMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            property real lastMouseX: 0
            property real lastMouseY: 0
            property bool isPanning: false

            // Mouse wheel zoom
            onWheel: function(wheel) {
                var factor = wheel.angleDelta.y > 0 ? 0.9 : 1.1
                zoomChart(factor)
            }

            // Pan on left mouse drag
            onPressed: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    lastMouseX = mouse.x
                    lastMouseY = mouse.y
                    isPanning = true
                    root.autoScroll = false  // Disable auto-scroll when panning
                }
            }

            onReleased: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    isPanning = false
                }
            }

            onPositionChanged: function(mouse) {
                if (isPanning && mouse.buttons & Qt.LeftButton) {
                    var dx = mouse.x - lastMouseX
                    var dy = mouse.y - lastMouseY
                    pan(dx, dy)
                    lastMouseX = mouse.x
                    lastMouseY = mouse.y
                }
            }
        }
    }

    // Control buttons overlay
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 5
        z: 100

        Button {
            text: "Reset"
            width: 60
            height: 30
            onClicked: resetZoom()
        }

        Button {
            text: autoScroll ? qsTr("Pause") : qsTr("Follow")
            width: 60
            height: 30
            onClicked: toggleAutoScroll()
            ToolTip.visible: hovered
            ToolTip.text: autoScroll ? "Pause auto-scroll" : "Resume auto-scroll"
        }

        Button {
            text: "Fit"
            width: 50
            height: 30
            onClicked: fitToData()
        }
    }

    // Component initialization
    Component.onCompleted: {
        console.log("TimeSeriesRenderer initialized for chart:", chartId)
    }

    // ========== PUBLIC API ==========

    /**
     * Create a new data line
     */
    function _normalizeValueField(valueField) {
        return valueField === "x" ? "x" : "y"
    }

    function _buildLineKey(uniqueId, valueField) {
        var field = _normalizeValueField(valueField)
        return (root.chartId || "main") + "::" + uniqueId + "::" + field
    }

    function _formatDisplayName(displayName, valueField) {
        var suffix = valueField === "x" ? " (X)" : " (Y)"
        return displayName + suffix
    }

    function _registerLineKey(uniqueId, lineKey) {
        if (!_graphsByUniqueId[uniqueId]) {
            _graphsByUniqueId[uniqueId] = []
        }
        if (_graphsByUniqueId[uniqueId].indexOf(lineKey) === -1) {
            _graphsByUniqueId[uniqueId].push(lineKey)
        }
    }

    function _unregisterLineKey(uniqueId, lineKey) {
        if (!_graphsByUniqueId[uniqueId]) return
        var idx = _graphsByUniqueId[uniqueId].indexOf(lineKey)
        if (idx !== -1) {
            _graphsByUniqueId[uniqueId].splice(idx, 1)
        }
        if (_graphsByUniqueId[uniqueId].length === 0) {
            delete _graphsByUniqueId[uniqueId]
        }
    }

    function _getGraphsForUniqueId(uniqueId) {
        var keys = _graphsByUniqueId[uniqueId] || []
        var graphs = []
        for (var i = 0; i < keys.length; i++) {
            var graph = _graphs[keys[i]]
            if (graph) graphs.push(graph)
        }
        return graphs
    }

    function createLine(uniqueId, displayName, color, interfaceType, dataId, valueField) {
        var field = _normalizeValueField(valueField)
        var lineKey = _buildLineKey(uniqueId, field)
        if (_graphs[lineKey]) {
            console.warn("Line already exists:", lineKey)
            return null
        }

        // Create new line series
        var series = chart.createSeries(ChartView.SeriesTypeLine, displayName, timeAxis, valueAxis)
        series.color = color || Qt.rgba(Math.random(), Math.random(), Math.random(), 1)
        series.width = 2
        series.useOpenGL = false

        _graphs[lineKey] = {
            lineKey: lineKey,
            uniqueId: uniqueId,
            valueField: field,
            series: series,
            displayName: displayName,
            color: series.color,
            visible: true,
            pointCount: 0,
            lastTime: 0
        }
        _registerLineKey(uniqueId, lineKey)

        console.log("Created time series line:", uniqueId, displayName, field)
        return series
    }

    /**
     * Append a single point to a line (with timestamp)
     */
    function _appendPointForGraph(graph, timestamp, value) {
        if (!graph || !graph.visible) return
        var series = graph.series

        // Update current time tracking
        if (timestamp > _currentTime) {
            _currentTime = timestamp
        }

        // Auto-scroll: adjust time window
        if (autoScroll && timestamp > timeAxis.max) {
            var windowSize = timeAxis.max - timeAxis.min
            timeAxis.min = timestamp - windowSize
            timeAxis.max = timestamp
        }

        // Add point
        series.append(timestamp, value)
        graph.pointCount++
        graph.lastTime = timestamp

        // Limit points to prevent performance issues (keep last 10000 points)
        if (graph.pointCount > 10000) {
            series.removePoints(0, 100)
            graph.pointCount -= 100
        }

        // Auto-scale Y axis if enabled
        scheduleYAxisUpdate()
    }

    function appendPoint(uniqueId, timestamp, value) {
        var graphs = _getGraphsForUniqueId(uniqueId)
        if (graphs.length === 0) return
        if (root.updatesSuspended) {
            queuePendingPoints(uniqueId, [[value, value, timestamp, true]])
            return
        }
        for (var i = 0; i < graphs.length; i++) {
            _appendPointForGraph(graphs[i], timestamp, value)
        }
    }

    /**
     * Append points in batch (optimized)
     */
    function appendPointsBatch(uniqueId, points) {
        var graphs = _getGraphsForUniqueId(uniqueId)
        if (graphs.length === 0) return
        if (root.updatesSuspended) {
            queuePendingPoints(uniqueId, points)
            return
        }
        if (!points || points.length === 0) {
            return
        }

        for (var i = 0; i < points.length; i++) {
            var point = points[i]
            // Backend can send [x, y], [x, y, t] or
            // [x, y, t, hasExplicitX]; time series always prefers t.
            var timestamp = (point.length !== undefined && point.length > 2 && point[2] !== undefined && point[2] !== null) ? point[2] : point[0]
            var yValue = point[1]
            var xValue = point[0]

            for (var g = 0; g < graphs.length; g++) {
                var graph = graphs[g]
                if (!graph || !graph.visible) continue
                var value = graph.valueField === "x" ? xValue : yValue

                // Update current time
                if (timestamp > _currentTime) {
                    _currentTime = timestamp
                }

                graph.series.append(timestamp, value)
                graph.pointCount++
                graph.lastTime = timestamp
            }
        }

        // Auto-scroll
        if (autoScroll && _currentTime > timeAxis.max) {
            var windowSize = timeAxis.max - timeAxis.min
            timeAxis.min = _currentTime - windowSize
            timeAxis.max = _currentTime
        }

        // Limit points
        for (var k = 0; k < graphs.length; k++) {
            var gGraph = graphs[k]
            if (!gGraph) continue
            if (gGraph.pointCount > 10000) {
                var removeCount = Math.min(100, gGraph.pointCount - 10000)
                gGraph.series.removePoints(0, removeCount)
                gGraph.pointCount -= removeCount
            }
        }

        // Auto-scale Y
        scheduleYAxisUpdate()
    }

    /**
     * Remove a data line
     */
    function removeLine(uniqueId, valueField) {
        var keys = []
        if (valueField !== undefined && valueField !== null && valueField !== "") {
            keys.push(_buildLineKey(uniqueId, valueField))
        } else if (_graphsByUniqueId[uniqueId]) {
            keys = _graphsByUniqueId[uniqueId].slice()
        }

        if (keys.length === 0) {
            return false
        }

        for (var i = 0; i < keys.length; i++) {
            var lineKey = keys[i]
            var graph = _graphs[lineKey]
            if (!graph) continue
            chart.removeSeries(graph.series)
            delete _graphs[lineKey]
            _unregisterLineKey(uniqueId, lineKey)
            console.log("Removed time series line:", uniqueId, graph.valueField)
        }
        return true
    }

    /**
     * Clear all points from a line
     */
    function _clearLineByKey(lineKey) {
        var graph = _graphs[lineKey]
        if (!graph) return
        graph.series.removePoints(0, graph.series.count)
        graph.pointCount = 0
        graph.lastTime = 0
    }

    function clearLine(uniqueId, valueField) {
        var keys = []
        if (valueField !== undefined && valueField !== null && valueField !== "") {
            keys.push(_buildLineKey(uniqueId, valueField))
        } else if (_graphsByUniqueId[uniqueId]) {
            keys = _graphsByUniqueId[uniqueId].slice()
        }
        for (var i = 0; i < keys.length; i++) {
            _clearLineByKey(keys[i])
        }
    }

    /**
     * Clear all lines
     */
    function clearAll() {
        for (var lineKey in _graphs) {
            _clearLineByKey(lineKey)
        }
    }

    /**
     * Toggle line visibility
     */
    function toggleLineVisibility(uniqueId, visible) {
        var keys = _graphsByUniqueId[uniqueId] || []
        for (var i = 0; i < keys.length; i++) {
            var graph = _graphs[keys[i]]
            if (!graph) continue
            graph.visible = visible
            graph.series.visible = visible
        }
    }

    /**
     * Get a line by uniqueId
     */
    function getLine(uniqueId, valueField) {
        if (valueField !== undefined && valueField !== null && valueField !== "") {
            return _graphs[_buildLineKey(uniqueId, valueField)] || null
        }
        var keys = _graphsByUniqueId[uniqueId] || []
        if (keys.length === 0) return null
        return _graphs[keys[0]] || null
    }

    function updateLineProperties(uniqueId, valueField, displayName, color, visible) {
        var graph = getLine(uniqueId, valueField)
        if (!graph) return
        graph.displayName = displayName
        graph.color = color
        graph.visible = visible
        graph.series.name = displayName
        graph.series.color = color
        graph.series.visible = visible
    }

    // ========== ZOOM AND PAN FUNCTIONS ==========

    function zoomChart(factor) {
        var timeRange = timeAxis.max - timeAxis.min
        var valueRange = valueAxis.max - valueAxis.min

        var newTimeRange = timeRange * factor
        var newValueRange = valueRange * factor

        var timeCenter = (timeAxis.max + timeAxis.min) / 2
        var valueCenter = (valueAxis.max + valueAxis.min) / 2

        timeAxis.min = timeCenter - newTimeRange / 2
        timeAxis.max = timeCenter + newTimeRange / 2
        valueAxis.min = valueCenter - newValueRange / 2
        valueAxis.max = valueCenter + newValueRange / 2

        root.autoScroll = false  // Disable auto-scroll when zooming
    }

    function pan(dx, dy) {
        var plotArea = chart.plotArea
        if (plotArea.width <= 0 || plotArea.height <= 0) {
            return
        }
        var timeRange = timeAxis.max - timeAxis.min
        var valueRange = valueAxis.max - valueAxis.min

        var timeShift = -(dx / plotArea.width) * timeRange
        var valueShift = (dy / plotArea.height) * valueRange

        timeAxis.min += timeShift
        timeAxis.max += timeShift
        valueAxis.min += valueShift
        valueAxis.max += valueShift
    }

    function resetZoom() {
        timeAxis.min = 0
        timeAxis.max = root.timeWindow
        valueAxis.min = root.initialYMin
        valueAxis.max = root.initialYMax
        root.autoScroll = true
        root.autoScaleY = true
    }

    function fitToData() {
        var minY = Infinity
        var maxY = -Infinity
        var minT = Infinity
        var maxT = -Infinity

        for (var uniqueId in _graphs) {
            var graph = _graphs[uniqueId]
            if (!graph || !graph.visible) continue

            var series = graph.series
            for (var i = 0; i < series.count; i++) {
                var point = series.at(i)
                minT = Math.min(minT, point.x)
                maxT = Math.max(maxT, point.x)
                minY = Math.min(minY, point.y)
                maxY = Math.max(maxY, point.y)
            }
        }

        if (minT !== Infinity && maxT !== -Infinity) {
            var timeMargin = (maxT - minT) * 0.05
            timeAxis.min = minT - timeMargin
            timeAxis.max = maxT + timeMargin
        }

        if (minY !== Infinity && maxY !== -Infinity) {
            var valueMargin = (maxY - minY) * 0.1
            valueAxis.min = minY - valueMargin
            valueAxis.max = maxY + valueMargin
        }

        root.autoScroll = false
        root.autoScaleY = false
    }

    function toggleAutoScroll() {
        root.autoScroll = !root.autoScroll
        if (root.autoScroll) {
            // Jump to latest data
            var windowSize = timeAxis.max - timeAxis.min
            timeAxis.min = _currentTime - windowSize
            timeAxis.max = _currentTime
        }
    }

    function updateYAxisRange() {
        var minY = Infinity
        var maxY = -Infinity

        for (var uniqueId in _graphs) {
            var graph = _graphs[uniqueId]
            if (!graph || !graph.visible) continue

            var series = graph.series
            for (var i = 0; i < series.count; i++) {
                var point = series.at(i)
                // Only consider points in visible time window
                if (point.x >= timeAxis.min && point.x <= timeAxis.max) {
                    minY = Math.min(minY, point.y)
                    maxY = Math.max(maxY, point.y)
                }
            }
        }

        if (minY !== Infinity && maxY !== -Infinity) {
            var margin = (maxY - minY) * 0.1
            valueAxis.min = minY - margin
            valueAxis.max = maxY + margin
        }
    }

    function scheduleYAxisUpdate() {
        if (root.autoScaleY && !yAxisUpdateTimer.running) {
            yAxisUpdateTimer.start()
        }
    }

    function queuePendingPoints(uniqueId, points) {
        if (!points || points.length === 0) return
        var pending = root._pendingPoints[uniqueId] || []
        for (var i = 0; i < points.length; i++) pending.push(points[i])
        if (pending.length > root.maxPendingPointsPerSignal) {
            pending = pending.slice(pending.length - root.maxPendingPointsPerSignal)
        }
        root._pendingPoints[uniqueId] = pending
    }

    function flushPendingPoints() {
        var pendingBySignal = root._pendingPoints
        root._pendingPoints = ({})
        for (var uniqueId in pendingBySignal) {
            root.appendPointsBatch(uniqueId, pendingBySignal[uniqueId])
        }
    }
}
