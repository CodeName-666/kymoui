/**
 * FloatingChartWindow.qml
 *
 * Floating, movable, resizable chart window component.
 * Part of the Phase 1 floating multi-chart-type system.
 *
 * Features:
 * - Drag & drop movement
 * - Window chrome (title bar, close/minimize buttons)
 * - Docking to screen edges
 * - Z-order management
 * - Per-window chart type (XY Line, XY Scatter, XYZ Surface, etc.)
 */

import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 6.4
import QtQuick.Effects
import Common 1.0
import Theme 1.0

Rectangle {
    id: floatingWindow
    objectName: "floatingChartWindow_" + chartId

    // Public properties
    property string chartId: ""
    property string chartTitle: "Chart"
    property string chartType: "xy_line"  // ChartType enum value
    // The workspace owns chart state, assignments and data routing.
    property var workspaceController: null
    // Optional: backend connection associated with this window (used for Test charts)
    property string connectionId: ""
    property bool autoDeleteConnectionOnClose: false
    property bool isDocked: false
    property string dockPosition: ""  // "left", "right", "top", "bottom"

    // Expose chart view (which wraps the renderer and provides chart line management)
    property alias chartRenderer: chartLoader.item

    // Window state
    property bool isMinimized: false
    property bool isMaximized: false
    property int zOrder: 0
    property rect restoreGeometry: Qt.rect(100, 100, 800, 600)
    property rect minimizeRestoreGeometry: Qt.rect(0, 0, 0, 0)

    // Drag state
    property bool isDragging: false
    property bool isResizing: false
    property point dragStartPos: Qt.point(0, 0)
    property point windowStartPos: Qt.point(0, 0)

    // Visual feedback during dragging
    property color dragBorderColor: AppTheme.palette.primary
    property real dragShadowIntensity: 1.0

    // Docking preview
    property bool showDockingPreview: false
    property string previewDockPosition: ""

    // Performance
    property int dragUpdateThrottle: 8  // ~120fps for smooth dragging
    property var lastDragUpdate: Date.now()

    // Visual properties
    color: AppTheme.surfaces.card
    border.color: isDragging ? dragBorderColor : AppTheme.borders.primary
    border.width: 2
    radius: 8
    // opacity and scale removed from root to prevent jitter during dragging

    // Default size
    width: 800
    height: 600

    states: [
        State {
            name: "maximized"
            when: floatingWindow.isMaximized
            AnchorChanges {
                target: floatingWindow
                anchors.left: floatingWindow.parent.left
                anchors.right: floatingWindow.parent.right
                anchors.top: floatingWindow.parent.top
                anchors.bottom: floatingWindow.parent.bottom
            }
        },
        State {
            name: "dockedLeft"
            when: floatingWindow.isDocked && floatingWindow.dockPosition === "left"
            AnchorChanges {
                target: floatingWindow
                anchors.left: floatingWindow.parent.left
                anchors.top: floatingWindow.parent.top
                anchors.bottom: floatingWindow.parent.bottom
            }
            PropertyChanges {
                target: floatingWindow
                width: floatingWindow.parent.width / 2
            }
        },
        State {
            name: "dockedRight"
            when: floatingWindow.isDocked && floatingWindow.dockPosition === "right"
            AnchorChanges {
                target: floatingWindow
                anchors.right: floatingWindow.parent.right
                anchors.top: floatingWindow.parent.top
                anchors.bottom: floatingWindow.parent.bottom
            }
            PropertyChanges {
                target: floatingWindow
                width: floatingWindow.parent.width / 2
            }
        },
        State {
            name: "dockedTop"
            when: floatingWindow.isDocked && floatingWindow.dockPosition === "top"
            AnchorChanges {
                target: floatingWindow
                anchors.left: floatingWindow.parent.left
                anchors.right: floatingWindow.parent.right
                anchors.top: floatingWindow.parent.top
            }
            PropertyChanges {
                target: floatingWindow
                height: floatingWindow.parent.height / 2
            }
        },
        State {
            name: "dockedBottom"
            when: floatingWindow.isDocked && floatingWindow.dockPosition === "bottom"
            AnchorChanges {
                target: floatingWindow
                anchors.left: floatingWindow.parent.left
                anchors.right: floatingWindow.parent.right
                anchors.bottom: floatingWindow.parent.bottom
            }
            PropertyChanges {
                target: floatingWindow
                height: floatingWindow.parent.height / 2
            }
        }
    ]

    // Z-order
    z: zOrder

    // Smooth animations for visual feedback
    Behavior on dragBorderColor {
        ColorAnimation { duration: 150 }
    }

    Behavior on dragShadowIntensity {
        NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
    }

    Behavior on width {
        enabled: !floatingWindow.isDragging && !floatingWindow.isResizing
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    Behavior on height {
        enabled: !floatingWindow.isDragging && !floatingWindow.isResizing
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // Window shadow (disabled during drag/resize for performance)
    layer.enabled: !floatingWindow.isDragging && !floatingWindow.isResizing
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, floatingWindow.isDragging ? 0.25 : 0.45)
        shadowHorizontalOffset: 0
        shadowVerticalOffset: floatingWindow.isDragging ? 2 : 6
        shadowBlur: floatingWindow.isDragging ? 0.25 : 0.6
        shadowScale: 1.0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Title Bar (Window Chrome)
        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: AppTheme.surfaces.interfaceBackground
            radius: floatingWindow.radius

            // Drag area
            MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: (floatingWindow.isDocked || floatingWindow.isMaximized) ? Qt.ArrowCursor : Qt.SizeAllCursor

                property point clickPos: Qt.point(0, 0)
                // Use parent coordinates for deltas. Local mouse coords change while the window moves,
                // which causes jitter/undefined movement when computing deltas from mouse.x/mouse.y.
                property point pressPosInParent: Qt.point(0, 0)

                onPressed: (mouse) => {
                    if (floatingWindow.isDocked || floatingWindow.isMaximized) {
                        return
                    }
                    clickPos = Qt.point(mouse.x, mouse.y)
                    floatingWindow.dragStartPos = clickPos
                    floatingWindow.windowStartPos = Qt.point(floatingWindow.x, floatingWindow.y)
                    pressPosInParent = dragArea.mapToItem(floatingWindow.parent, mouse.x, mouse.y)
                    floatingWindow.isDragging = true

                    // Visual feedback: enhanced shadow only (no scale/opacity to prevent jitter)
                    floatingWindow.dragShadowIntensity = 1.3

                    if (floatingWindow.workspaceController) {
                        floatingWindow.workspaceController.bringToFront(floatingWindow.chartId)
                    }
                }

                onPositionChanged: (mouse) => {
                    if (floatingWindow.isDragging && !floatingWindow.isDocked) {
                        // Throttle für Performance
                        var now = Date.now()
                        if (now - floatingWindow.lastDragUpdate < floatingWindow.dragUpdateThrottle) {
                            return
                        }
                        floatingWindow.lastDragUpdate = now

                        var currentPosInParent = dragArea.mapToItem(floatingWindow.parent, mouse.x, mouse.y)
                        var delta = Qt.point(currentPosInParent.x - pressPosInParent.x,
                                             currentPosInParent.y - pressPosInParent.y)
                        var nextX = floatingWindow.windowStartPos.x + delta.x
                        var nextY = floatingWindow.windowStartPos.y + delta.y

                        if (floatingWindow.parent) {
                            var maxX = Math.max(0, floatingWindow.parent.width - floatingWindow.width)
                            var maxY = Math.max(0, floatingWindow.parent.height - floatingWindow.height)
                            nextX = Math.max(0, Math.min(maxX, nextX))
                            nextY = Math.max(0, Math.min(maxY, nextY))
                        }

                        floatingWindow.x = nextX
                        floatingWindow.y = nextY

                        // Preview für Docking-Zones
                        checkDockingZonesPreview()
                    }
                }

                onReleased: {
                    floatingWindow.isDragging = false

                    // Reset visual feedback
                    floatingWindow.dragShadowIntensity = 1.0
                    floatingWindow.showDockingPreview = false

                    // Check for docking zones
                    checkDockingZones()

                    if (floatingWindow.workspaceController) {
                        floatingWindow.workspaceController.updateChartGeometry(
                            floatingWindow.chartId,
                            floatingWindow.x,
                            floatingWindow.y,
                            floatingWindow.width,
                            floatingWindow.height
                        )
                    }
                }

                onDoubleClicked: {
                    // Toggle maximize
                    toggleMaximize()
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8

                // Window icon
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    color: AppTheme.palette.primary
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: getChartTypeIcon(floatingWindow.chartType)
                        font.pixelSize: 14
                        color: "white"
                    }
                }

                // Title
                Text {
                    Layout.fillWidth: true
                    text: floatingWindow.chartTitle
                    font.pixelSize: 14
                    font.bold: true
                    color: AppTheme.text.primary
                    elide: Text.ElideRight
                }

                // Chart type label
                Text {
                    text: getChartTypeLabel(floatingWindow.chartType)
                    font.pixelSize: 11
                    color: AppTheme.text.secondary
                }

                // Minimize button
                ToolButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    text: "−"
                    font.pixelSize: 16

                    ToolTip.visible: hovered
                    ToolTip.text: floatingWindow.isMinimized ? qsTr("Restore chart") : qsTr("Minimize chart")
                    ToolTip.delay: 400

                    onClicked: {
                        toggleMinimize()
                    }

                    background: Rectangle {
                        color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                        radius: 4
                        border.color: parent.activeFocus ? AppTheme.borders.focus : "transparent"
                        border.width: parent.activeFocus ? 2 : 0
                    }
                }

                // Maximize button
                ToolButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    text: floatingWindow.isMaximized ? "◱" : "□"
                    font.pixelSize: 14

                    ToolTip.visible: hovered
                    ToolTip.text: floatingWindow.isMaximized ? qsTr("Restore chart size") : qsTr("Maximize chart")
                    ToolTip.delay: 400

                    onClicked: {
                        toggleMaximize()
                    }

                    background: Rectangle {
                        color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                        radius: 4
                        border.color: parent.activeFocus ? AppTheme.borders.focus : "transparent"
                        border.width: parent.activeFocus ? 2 : 0
                    }
                }

                // Close button
                ToolButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    text: "×"
                    font.pixelSize: 20

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Close chart")
                    ToolTip.delay: 400

                    onClicked: {
                        closeWindow()
                    }

                    background: Rectangle {
                        color: parent.hovered ? AppTheme.palette.danger : "transparent"
                        radius: 4
                        border.color: parent.activeFocus ? AppTheme.borders.focus : "transparent"
                        border.width: parent.activeFocus ? 2 : 0
                    }
                }
            }
        }

        // Chart content area
        Rectangle {
            id: chartContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: AppTheme.surfaces.interfaceBackground
            visible: !floatingWindow.isMinimized

            // Chart renderer will be loaded here dynamically
            Loader {
                id: chartLoader
                anchors.fill: parent
                anchors.margins: 8

                source: getChartRendererQml(floatingWindow.chartType)
                asynchronous: true

                onLoaded: {
                    // Pass properties to the loaded chart view
                    if (item) {
                        item.chartId = floatingWindow.chartId
                        item.chartTitle = floatingWindow.chartTitle
                        if (item.chartType !== undefined) {
                            item.chartType = floatingWindow.chartType
                        }
                    }
                    syncRendererState()
                    if (floatingWindow.workspaceController) {
                        floatingWindow.workspaceController.rendererReady(floatingWindow.chartId)
                    }
                }

                onStatusChanged: {
                    if (status === Loader.Error) {
                        console.error("FloatingChartWindow: Failed to load chart renderer:", source)
                    } else if (status === Loader.Ready) {
                        console.log("FloatingChartWindow: Chart renderer loaded successfully")
                    }
                }
            }

            // Placeholder when no chart loaded
            Text {
                anchors.centerIn: parent
                text: "No chart loaded"
                font.pixelSize: 16
                color: AppTheme.text.placeholder
                visible: chartLoader.status !== Loader.Ready
            }
        }
    }

    // Resize handles (bottom-right corner)
    Rectangle {
        id: resizeHandle
        width: 16
        height: 16
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
        color: AppTheme.surfaces.muted
        radius: 2
        visible: !floatingWindow.isMinimized && !floatingWindow.isMaximized && !floatingWindow.isDocked

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor

            property point clickPos: Qt.point(0, 0)
            property point pressPosInParent: Qt.point(0, 0)
            property size startSize: Qt.size(0, 0)

            onPressed: (mouse) => {
                clickPos = Qt.point(mouse.x, mouse.y)
                startSize = Qt.size(floatingWindow.width, floatingWindow.height)
                pressPosInParent = resizeHandle.mapToItem(floatingWindow.parent, mouse.x, mouse.y)
                floatingWindow.isResizing = true
            }

            onPositionChanged: (mouse) => {
                var currentPosInParent = resizeHandle.mapToItem(floatingWindow.parent, mouse.x, mouse.y)
                var delta = Qt.point(currentPosInParent.x - pressPosInParent.x,
                                     currentPosInParent.y - pressPosInParent.y)
                var maxW = floatingWindow.parent ? floatingWindow.parent.width : 1000000
                var maxH = floatingWindow.parent ? floatingWindow.parent.height : 1000000
                var minW = Math.min(400, maxW)
                var minH = Math.min(300, maxH)

                floatingWindow.width = Math.max(minW, Math.min(maxW, startSize.width + delta.x))
                floatingWindow.height = Math.max(minH, Math.min(maxH, startSize.height + delta.y))
                clampToParent()
            }

            onReleased: {
                floatingWindow.isResizing = false

                if (floatingWindow.workspaceController) {
                    floatingWindow.workspaceController.updateChartGeometry(
                        floatingWindow.chartId,
                        floatingWindow.x,
                        floatingWindow.y,
                        floatingWindow.width,
                        floatingWindow.height
                    )
                }
            }
        }
    }

    // Docking Zone Preview Overlay
    Rectangle {
        id: dockPreviewOverlay
        color: Qt.rgba(63 / 255, 183 / 255, 255 / 255, 0.25)
        border.color: AppTheme.palette.primary
        border.width: 3
        radius: 4
        visible: floatingWindow.showDockingPreview
        z: -1  // Behind window

        x: {
            if (!parent) return 0
            if (floatingWindow.previewDockPosition === "left") return 0
            if (floatingWindow.previewDockPosition === "right") return parent.width / 2
            return 0
        }

        y: {
            if (!parent) return 0
            if (floatingWindow.previewDockPosition === "top") return 0
            if (floatingWindow.previewDockPosition === "bottom") return parent.height / 2
            return 0
        }

        width: {
            if (!parent) return 0
            if (floatingWindow.previewDockPosition === "left" || floatingWindow.previewDockPosition === "right")
                return parent.width / 2
            return parent.width
        }

        height: {
            if (!parent) return 0
            if (floatingWindow.previewDockPosition === "top" || floatingWindow.previewDockPosition === "bottom")
                return parent.height / 2
            return parent.height
        }

        Behavior on x {
            enabled: !floatingWindow.isDragging
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
        Behavior on y {
            enabled: !floatingWindow.isDragging
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
        Behavior on width {
            enabled: !floatingWindow.isDragging
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
        Behavior on height {
            enabled: !floatingWindow.isDragging
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }

        Text {
            anchors.centerIn: parent
            text: {
                switch(floatingWindow.previewDockPosition) {
                    case "left": return "◀"
                    case "right": return "▶"
                    case "top": return "▲"
                    case "bottom": return "▼"
                    default: return "⊞"
                }
            }
            font.pixelSize: 48
            color: AppTheme.palette.primary
            opacity: 0.6
        }
    }

    // Narrow renderer port used by WorkspaceController.
    function createSeries(uniqueId, displayName, color, interfaceType, dataId, valueField) {
        if (!chartRenderer || !chartRenderer.createLine) return null
        if (chartRenderer.getLine) {
            var existing = chartRenderer.getLine(uniqueId, valueField)
            if (existing) return existing.series || existing
        }
        return chartRenderer.createLine(uniqueId, displayName, color, interfaceType, dataId, valueField)
    }

    function removeSeries(uniqueId, valueField) {
        if (!chartRenderer || !chartRenderer.removeLine) return false
        return chartRenderer.removeLine(uniqueId, valueField)
    }

    function updateSeries(uniqueId, valueField, displayName, color, visible) {
        if (!chartRenderer || !chartRenderer.updateLineProperties) return false
        chartRenderer.updateLineProperties(uniqueId, valueField, displayName, color, visible)
        return true
    }

    function appendPointsBatch(uniqueId, points) {
        if (!chartRenderer || !chartRenderer.appendPointsBatch) return false
        chartRenderer.appendPointsBatch(uniqueId, points)
        return true
    }

    function appendPointsBatch3D(uniqueId, points) {
        if (!chartRenderer || !chartRenderer.appendPointsBatch3D) return false
        chartRenderer.appendPointsBatch3D(uniqueId, points)
        return true
    }

    function clampToParent() {
        if (!parent) return
        if (floatingWindow.isDocked || floatingWindow.isMaximized) return

        if (floatingWindow.width > parent.width) {
            floatingWindow.width = parent.width
        }
        if (floatingWindow.height > parent.height) {
            floatingWindow.height = parent.height
        }

        var maxX = Math.max(0, parent.width - floatingWindow.width)
        var maxY = Math.max(0, parent.height - floatingWindow.height)
        floatingWindow.x = Math.max(0, Math.min(maxX, floatingWindow.x))
        floatingWindow.y = Math.max(0, Math.min(maxY, floatingWindow.y))
    }

    Connections {
        target: floatingWindow.parent
        function onWidthChanged() { clampToParent() }
        function onHeightChanged() { clampToParent() }
    }

    Component.onCompleted: {
        if (floatingWindow.workspaceController) {
            floatingWindow.workspaceController.registerWindow(floatingWindow.chartId, floatingWindow)
        }
        clampToParent()
        syncRendererState()
    }

    onIsDraggingChanged: syncRendererState()
    onIsResizingChanged: syncRendererState()
    onIsMinimizedChanged: syncRendererState()

    function getChartTypeIcon(type) {
        switch(type) {
            case "xy_line": return "XY"
            case "xy_scatter": return "XY"
            case "time_series": return "t"
            case "xyz_surface": return "3D"
            case "xyz_scatter": return "3D"
            case "bar": return "B"
            case "heatmap": return "H"
            default: return "·"
        }
    }

    function getChartTypeLabel(type) {
        switch(type) {
            case "xy_line": return qsTr("Cartesian XY · X vs Y")
            case "xy_scatter": return qsTr("Cartesian XY points · X vs Y")
            case "time_series": return qsTr("Time series · time vs value")
            case "xyz_surface": return qsTr("3D surface · X/Y/Z")
            case "xyz_scatter": return qsTr("3D points · X/Y/Z")
            case "bar": return "Bar Chart"
            case "heatmap": return "Heatmap"
            default: return "Unknown"
        }
    }

    function getChartRendererQml(type) {
        switch(type) {
            case "xy_line":
            case "xy_scatter":
                return "../ChartTypes/XYChartView.qml"
            case "time_series":
                return "../ChartTypes/TimeSeriesRenderer.qml"
            case "xyz_surface":
            case "xyz_scatter":
                return "../ChartTypes/XYZChartRenderer.qml"
            default:
                return ""
        }
    }

    function toggleMinimize() {
        if (!floatingWindow.isMinimized) {
            if (floatingWindow.isDocked) {
                undock()
            }
            if (floatingWindow.isMaximized) {
                floatingWindow.isMaximized = false
                floatingWindow.x = floatingWindow.restoreGeometry.x
                floatingWindow.y = floatingWindow.restoreGeometry.y
                floatingWindow.width = floatingWindow.restoreGeometry.width
                floatingWindow.height = floatingWindow.restoreGeometry.height
            }
            floatingWindow.minimizeRestoreGeometry = Qt.rect(floatingWindow.x, floatingWindow.y, floatingWindow.width, floatingWindow.height)
            floatingWindow.isMinimized = true
            floatingWindow.height = titleBar.height
        } else {
            floatingWindow.isMinimized = false
            var restore = floatingWindow.minimizeRestoreGeometry
            if (restore.width <= 0 || restore.height <= 0) {
                restore = Qt.rect(floatingWindow.x, floatingWindow.y, 800, 600)
            }
            floatingWindow.x = restore.x
            floatingWindow.y = restore.y
            floatingWindow.width = restore.width
            floatingWindow.height = restore.height
            clampToParent()
        }
        syncRendererState()
        persistWindowState()
    }

    function toggleMaximize() {
        if (floatingWindow.isDocked) {
            undock()
        }
        if (floatingWindow.isMinimized) {
            toggleMinimize()
        }

        if (!floatingWindow.isMaximized) {
            floatingWindow.restoreGeometry = Qt.rect(floatingWindow.x, floatingWindow.y, floatingWindow.width, floatingWindow.height)
            floatingWindow.isMaximized = true
        } else {
            floatingWindow.isMaximized = false
            floatingWindow.x = floatingWindow.restoreGeometry.x
            floatingWindow.y = floatingWindow.restoreGeometry.y
            floatingWindow.width = floatingWindow.restoreGeometry.width
            floatingWindow.height = floatingWindow.restoreGeometry.height
            clampToParent()
        }
        persistWindowState()
    }

    function closeWindow() {
        if (floatingWindow.workspaceController) {
            floatingWindow.workspaceController.removeChart(floatingWindow.chartId)
        }
    }

    function syncRendererState() {
        if (chartRenderer && chartRenderer.updatesSuspended !== undefined) {
            chartRenderer.updatesSuspended = floatingWindow.isDragging || floatingWindow.isResizing || floatingWindow.isMinimized
        }
    }

    function persistWindowState() {
        if (!floatingWindow.workspaceController) return
        floatingWindow.workspaceController.updateChartWindowState(
            floatingWindow.chartId,
            floatingWindow.isMinimized,
            floatingWindow.isMaximized,
            floatingWindow.restoreGeometry
        )
    }

    function checkDockingZonesPreview() {
        if (!parent) return

        var dockThreshold = 80
        var parentWidth = parent.width
        var parentHeight = parent.height

        var leftDist = floatingWindow.x
        var rightDist = parentWidth - (floatingWindow.x + floatingWindow.width)
        var topDist = floatingWindow.y
        var bottomDist = parentHeight - (floatingWindow.y + floatingWindow.height)

        var minDist = Math.min(leftDist, rightDist, topDist, bottomDist)

        if (minDist > dockThreshold) {
            floatingWindow.showDockingPreview = false
            floatingWindow.previewDockPosition = ""
            floatingWindow.dragBorderColor = AppTheme.palette.primary
            return
        }

        floatingWindow.showDockingPreview = true
        floatingWindow.dragBorderColor = AppTheme.palette.success

        if (minDist === leftDist) {
            floatingWindow.previewDockPosition = "left"
        } else if (minDist === rightDist) {
            floatingWindow.previewDockPosition = "right"
        } else if (minDist === topDist) {
            floatingWindow.previewDockPosition = "top"
        } else if (minDist === bottomDist) {
            floatingWindow.previewDockPosition = "bottom"
        }
    }

    function checkDockingZones() {
        if (!parent) return

        var dockThreshold = 50
        var parentWidth = parent.width
        var parentHeight = parent.height

        // Check left edge
        if (floatingWindow.x < dockThreshold) {
            dockToEdge("left")
        }
        // Check right edge
        else if (floatingWindow.x + floatingWindow.width > parentWidth - dockThreshold) {
            dockToEdge("right")
        }
        // Check top edge
        else if (floatingWindow.y < dockThreshold) {
            dockToEdge("top")
        }
        // Check bottom edge
        else if (floatingWindow.y + floatingWindow.height > parentHeight - dockThreshold) {
            dockToEdge("bottom")
        }
    }

    function dockToEdge(edge) {
        if (!parent) return

        if (!floatingWindow.isDocked) {
            floatingWindow.restoreGeometry = Qt.rect(floatingWindow.x, floatingWindow.y, floatingWindow.width, floatingWindow.height)
        }

        floatingWindow.isDocked = true
        floatingWindow.dockPosition = edge
        floatingWindow.isMaximized = false

        if (floatingWindow.workspaceController) {
            floatingWindow.workspaceController.updateChartDocking(floatingWindow.chartId, true, edge)
            persistWindowState()
        }
    }

    function undock() {
        floatingWindow.isDocked = false
        floatingWindow.dockPosition = ""
        floatingWindow.x = floatingWindow.restoreGeometry.x
        floatingWindow.y = floatingWindow.restoreGeometry.y
        floatingWindow.width = floatingWindow.restoreGeometry.width
        floatingWindow.height = floatingWindow.restoreGeometry.height
        clampToParent()

        if (floatingWindow.workspaceController) {
            floatingWindow.workspaceController.updateChartDocking(floatingWindow.chartId, false, "")
            floatingWindow.workspaceController.updateChartGeometry(
                floatingWindow.chartId,
                floatingWindow.x,
                floatingWindow.y,
                floatingWindow.width,
                floatingWindow.height
            )
        }
    }

    Component.onDestruction: {
        if (floatingWindow.workspaceController) {
            floatingWindow.workspaceController.unregisterWindow(floatingWindow.chartId, floatingWindow)
        }
    }
}
