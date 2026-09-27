import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import DataModels.SerialDataModels 1.0
import Common 1.0
import Backend 1.0
import Theme 1.0
import "components"
import "ChartWindow/ConnectionManager"

Drawer {
    id: navDrawer
    objectName: "navDrawer"
    property var window
    property var settingsPopup

    width: Math.min((window ? window.width : 800) * 0.4, 360)
    height: window ? window.height : 600
    edge: Qt.LeftEdge
    interactive: true
    modal: true

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: navDrawer.panelBackground }
            GradientStop { position: 1.0; color: AppTheme.surfaces.muted }
        }
        border.color: navDrawer.sectionBorder
        border.width: 1
    }

    // State for connection section collapse
    property bool connectionsExpanded: true
    property bool testSectionExpanded: false

    readonly property color panelBackground: AppTheme.surfaces.interfaceBackground
    readonly property color sectionBackground: AppTheme.surfaces.card
    readonly property color sectionBorder: AppTheme.borders.primary
    readonly property color dividerColor: AppTheme.borders.subtle
    readonly property color textPrimary: AppTheme.text.primary
    readonly property color textSecondary: AppTheme.text.secondary
    readonly property color textMuted: AppTheme.text.placeholder
    readonly property color accent: AppTheme.palette.primary
    readonly property color accentHover: AppTheme.palette.primaryHover
    readonly property color accentPressed: AppTheme.palette.primaryPressed
    readonly property color accentBorder: AppTheme.palette.primaryBorder

    // Connection Manager Dialog (unified, shared component)
    ConnectionManagerDialog {
        id: connectionManagerDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
    }

    Component.onCompleted: {
        Logger.log_debug("NavDrawer completed")
        // Load initial connections
        updateConnectionsList()
    }

    onOpened: {
        Logger.log_debug("NavDrawer opened")
        updateConnectionsList()
    }

    onClosed: {
        Logger.log_debug("NavDrawer closed")
    }

    // Connections to Backend signals
    Connections {
        target: Backend

        function onConnections_changed(connections) {
            Logger.log_debug("NavDrawer: Received connections_changed signal")
            updateConnectionsList()
        }

        function onConnection_status_changed(connectionId, status, details) {
            Logger.log_debug("NavDrawer: Connection " + connectionId + " status changed to " + status)
            updateConnectionsList()
        }
    }

    ListModel {
        id: navModel
        ListElement { section: "APPLICATION"; title: "About"; iconName: "info" }
        ListElement { section: "APPLICATION"; title: "Quit"; iconName: "exit" }
    }

    ListModel {
        id: connectionsListModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        spacing: 12

        // Connections Section (Collapsible)
        Rectangle {
            id: connectionsSection
            Layout.fillWidth: true
            Layout.preferredHeight: connectionsExpanded ?
                (connectionsSectionContent.implicitHeight + connectionsSectionHeader.height + 24) :
                (connectionsSectionHeader.height + 16)
            Layout.minimumHeight: connectionsSectionHeader.height + 16
            radius: 8
            color: navDrawer.sectionBackground
            border.color: navDrawer.sectionBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 8
                spacing: 12

                // Header with Expand/Collapse button and Add button
                RowLayout {
                    id: connectionsSectionHeader
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 10

                    Button {
                        id: expandCollapseButton
                        text: connectionsExpanded ? "▼" : "▶"
                        visible: false
                        Layout.preferredWidth: 0
                        Layout.preferredHeight: 32
                        font.pixelSize: 11

                        onClicked: {
                            connectionsExpanded = !connectionsExpanded
                            Logger.log_debug("NavDrawer: Connections section " +
                                (connectionsExpanded ? "expanded" : "collapsed"))
                        }

                        background: Rectangle {
                            radius: 4
                            color: expandCollapseButton.pressed ? AppTheme.surfaces.muted :
                                   expandCollapseButton.hovered ? AppTheme.surfaces.card : "transparent"
                            border.color: navDrawer.dividerColor
                            border.width: 1
                        }
                    }

                    Label {
                        text: qsTr("1 · Data sources") + " (" + connectionsListModel.count + ")"
                        font.bold: true
                        font.pixelSize: 14
                        color: navDrawer.textPrimary
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Button {
                        id: manageConnectionsButton
                        text: qsTr("Manage")
                        Layout.preferredWidth: 78
                        Layout.preferredHeight: 32
                        font.pixelSize: 16
                        font.bold: true

                        onClicked: {
                            connectionManagerDialog.open()
                        }

                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Manage Connections")
                        ToolTip.delay: 500

                        background: Rectangle {
                            radius: 4
                            color: {
                                if (manageConnectionsButton.pressed) return navDrawer.accentPressed
                                if (manageConnectionsButton.hovered) return navDrawer.accentHover
                                return navDrawer.accent
                            }
                            border.color: navDrawer.accentBorder
                            border.width: 1
                        }

                        contentItem: Text {
                            text: manageConnectionsButton.text
                            font: manageConnectionsButton.font
                            color: AppTheme.text.primary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        id: addConnectionButton
                        text: qsTr("+ Add")
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 32
                        font.pixelSize: 16
                        font.bold: true

                        onClicked: {
                            addConnectionDialog.open()
                        }

                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Add Connection")
                        ToolTip.delay: 500

                        background: Rectangle {
                            radius: 4
                            color: {
                                if (addConnectionButton.pressed) return navDrawer.accentPressed
                                if (addConnectionButton.hovered) return navDrawer.accentHover
                                return navDrawer.accent
                            }
                            border.color: navDrawer.accentBorder
                            border.width: 1
                        }

                        contentItem: Text {
                            text: addConnectionButton.text
                            font: addConnectionButton.font
                            color: AppTheme.text.primary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Connections List (only visible when expanded)
                ColumnLayout {
                    id: connectionsSectionContent
                    Layout.fillWidth: true
                    visible: connectionsExpanded
                    opacity: connectionsExpanded ? 1.0 : 0.0
                    spacing: 6

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(connectionsListView.contentHeight, 300)
                        clip: true

                        ListView {
                            id: connectionsListView
                            model: connectionsListModel
                            spacing: 6
                            interactive: contentHeight > height
                            reuseItems: true
                            cacheBuffer: 200

                            delegate: ConnectionCard {
                                width: ListView.view.width
                                connectionId: model.id || ""
                                interfaceType: model.type || ""
                                displayName: model.name || ""
                                status: model.status || "disconnected"
                                connectionSettings: model.settings || ({})

                                onStartClicked: function(connId) {
                                    Logger.log_info("NavDrawer: Starting connection: " + connId)
                                    Backend.start_connection(connId)
                                }

                                onStopClicked: function(connId) {
                                    Logger.log_info("NavDrawer: Stopping connection: " + connId)
                                    Backend.stop_connection(connId)
                                }

                                onSettingsClicked: function(connId, ifaceType) {
                                    Logger.log_info("NavDrawer: Opening settings for connection: " + connId)
                                    openSettingsForConnection(connId, ifaceType)
                                }

                                onDeleteClicked: function(connId) {
                                    Logger.log_info("NavDrawer: Deleting connection: " + connId)
                                    Backend.delete_connection(connId)
                                }
                            }
                        }
                    }

                    // Empty State
                    Label {
                        text: qsTr("No data source yet. Add a Serial, Telnet, MQTT, CAN or Test connection.")
                        font.pixelSize: 11
                        color: navDrawer.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        Layout.bottomMargin: 12
                        visible: connectionsListModel.count === 0
                    }
                }
            }
        }

        // TEST Section (Collapsible)
        Rectangle {
            id: testSection
            visible: false
            Layout.fillWidth: true
            Layout.preferredHeight: testSectionExpanded ?
                (testSectionContent.implicitHeight + testSectionHeader.height + 24) :
                (testSectionHeader.height + 16)
            Layout.minimumHeight: testSectionHeader.height + 16
            radius: 8
            color: navDrawer.sectionBackground
            border.color: navDrawer.sectionBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 8
                spacing: 12

                // Header with Expand/Collapse button
                RowLayout {
                    id: testSectionHeader
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 10

                    Button {
                        id: testExpandCollapseButton
                        text: testSectionExpanded ? "▼" : "▶"
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 32
                        font.pixelSize: 11

                        onClicked: {
                            testSectionExpanded = !testSectionExpanded
                            Logger.log_debug("NavDrawer: Test section " +
                                (testSectionExpanded ? "expanded" : "collapsed"))
                        }

                        background: Rectangle {
                            radius: 4
                            color: testExpandCollapseButton.pressed ? AppTheme.surfaces.muted :
                                   testExpandCollapseButton.hovered ? AppTheme.surfaces.card : "transparent"
                            border.color: navDrawer.dividerColor
                            border.width: 1
                        }
                    }

                    Label {
                        text: qsTr("Advanced test tools")
                        font.bold: true
                        font.pixelSize: 14
                        color: navDrawer.textPrimary
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Test Items (only visible when expanded)
                ColumnLayout {
                    id: testSectionContent
                    Layout.fillWidth: true
                    visible: testSectionExpanded
                    opacity: testSectionExpanded ? 1.0 : 0.0
                    spacing: 6

                    ListView {
                        id: testList
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        spacing: 4
                        model: navModel ? navModel : []
                        clip: true
                        interactive: false
                        reuseItems: true

                        delegate: Rectangle {
                            id: testMenuItem
                            width: ListView.view.width
                            height: section === "TEST" ? 44 : 0
                            visible: section === "TEST"
                            color: {
                                if (ListView.isCurrentItem) return navDrawer.accent
                                if (testMenuItemMouseArea.containsMouse) return AppTheme.surfaces.muted
                                return "transparent"
                            }
                            border.color: ListView.isCurrentItem ? navDrawer.accentBorder : "transparent"
                            border.width: ListView.isCurrentItem ? 1 : 0
                            radius: 6

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.topMargin: 8
                                anchors.bottomMargin: 8
                                spacing: 12

                                Label {
                                    text: "\u25A0"
                                    visible: iconName !== ""
                                    color: ListView.isCurrentItem ? AppTheme.text.primary : navDrawer.textSecondary
                                    font.pixelSize: 14
                                }
                                Label {
                                    text: title
                                    color: ListView.isCurrentItem ? AppTheme.text.primary : navDrawer.textPrimary
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: testMenuItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    Logger.log_debug("NavDrawer: Test menu item clicked: " + title)
                                    testList.currentIndex = index

                                    // Handle test actions
                                    if (title === "Test 2D") {
                                        testFloatingWindow2D()
                                    } else if (title === "Test 2D X/Y") {
                                        testFloatingWindow2DXY()
                                    } else if (title === "Test XY") {
                                        testFloatingWindowXY()
                                    } else if (title === "Test 3D") {
                                        testFloatingWindow3D()
                                    }

                                    navDrawer.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Spacer to push APPLICATION section to bottom
        Item {
            Layout.fillHeight: true
        }

        // APPLICATION Section (About & Quit at bottom)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: false

            // APPLICATION Section Container
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: applicationSectionContent.implicitHeight + 24
                radius: 8
                color: navDrawer.sectionBackground
                border.color: navDrawer.sectionBorder
                border.width: 1

                ColumnLayout {
                    id: applicationSectionContent
                    anchors.fill: parent
                    anchors.topMargin: 12
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 8

                    // APPLICATION Section Header
                    Label {
                        text: qsTr("APPLICATION")
                        color: navDrawer.textMuted
                        font.pixelSize: 11
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.bottomMargin: 4
                    }

                    ListView {
                        id: applicationList
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
                        spacing: 4
                        model: navModel ? navModel : []
                        clip: true
                        interactive: false
                        reuseItems: true

                        delegate: Rectangle {
                            id: menuItem
                            width: ListView.view.width
                            height: section === "APPLICATION" ? 44 : 0
                            visible: section === "APPLICATION"
                        color: {
                            if (ListView.isCurrentItem) return navDrawer.accent
                            if (menuItemMouseArea.containsMouse) return AppTheme.surfaces.muted
                            return "transparent"
                        }
                        border.color: ListView.isCurrentItem ? navDrawer.accentBorder : "transparent"
                        border.width: ListView.isCurrentItem ? 1 : 0
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            spacing: 12

                            Label {
                                text: "\u25A0"
                                visible: iconName !== ""
                                color: ListView.isCurrentItem ? AppTheme.text.primary : navDrawer.textSecondary
                                font.pixelSize: 14
                            }
                            Label {
                                text: title
                                color: ListView.isCurrentItem ? AppTheme.text.primary : navDrawer.textPrimary
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: menuItemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Logger.log_debug("NavDrawer: Menu item clicked: " + title)
                                applicationList.currentIndex = index

                                // Handle menu actions
                                if (title === "About") {
                                    aboutDialog.open()
                                } else if (title === "Quit") {
                                    if (window) {
                                        window.close()
                                    }
                                }

                                navDrawer.close()
                            }
                        }
                    }
                }
            }
        }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: qsTr("About")
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                onClicked: aboutDialog.open()
            }

            Button {
                text: qsTr("Quit")
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                onClicked: if (window) window.close()
            }
        }

        // Infrequent application options stay secondary to the data-source workflow.
        Button {
            id: navSettingsButton
            text: qsTr("Application settings")
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.topMargin: 4

            onClicked: {
                Logger.log_info("NavDrawer: Settings button clicked")
                if(settingsPopup) {
                    navDrawer.close()  // Close drawer when opening settings
                    settingsPopup.open()
                } else {
                    Logger.log_error("NavDrawer: settingsPopup is null")
                }
            }

            background: Rectangle {
                radius: 8
                color: {
                    if (navSettingsButton.pressed) return navDrawer.accentPressed
                    if (navSettingsButton.hovered) return navDrawer.accentHover
                    return AppTheme.buttons.neutral.background
                }
                border.color: navSettingsButton.activeFocus ? AppTheme.borders.focus : AppTheme.buttons.neutral.border
                border.width: 1
            }

            contentItem: Text {
                text: navSettingsButton.text
                font.pixelSize: 14
                font.bold: true
                color: AppTheme.text.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Add Connection Dialog
    AddConnectionDialog {
        id: addConnectionDialog
        parent: Overlay.overlay
        anchors.centerIn: parent

        onConnectionCreated: function(connectionId) {
            Logger.log_info("NavDrawer: New connection created: " + connectionId)
            updateConnectionsList()
        }
    }

    // About Dialog
    Dialog {
        id: aboutDialog
        parent: Overlay.overlay
        anchors.centerIn: parent

        title: qsTr("About Plotter")
        modal: true
        standardButtons: Dialog.Ok

        width: 400
        height: 300

        background: Rectangle {
            color: AppTheme.surfaces.card
            border.color: AppTheme.borders.primary
            border.width: 1
            radius: 8
        }

        contentItem: ColumnLayout {
            spacing: 16
            anchors.fill: parent
            anchors.margins: 20

            Label {
                text: qsTr("Plotter Application")
                font.pixelSize: 24
                font.bold: true
                color: AppTheme.text.primary
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("Version 1.0")
                font.pixelSize: 14
                color: AppTheme.text.secondary
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: AppTheme.borders.subtle
            }

            Label {
                text: qsTr("A multi-interface data plotting application supporting Serial, Telnet, MQTT, and Test interfaces.")
                font.pixelSize: 12
                color: AppTheme.text.secondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                Layout.fillHeight: true
            }

            Label {
                text: qsTr("© 2025 Plotter Project")
                font.pixelSize: 10
                color: AppTheme.text.placeholder
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Helper Functions
    function updateConnectionsList() {
        Logger.log_debug("NavDrawer: Updating connections list")

        var connections = Backend.get_connections()
        Logger.log_debug("NavDrawer: Got " + connections.length + " connections from backend")

        connectionsListModel.clear()

        for (var i = 0; i < connections.length; i++) {
            var conn = connections[i]
            connectionsListModel.append({
                id: conn.id,
                type: conn.type,
                name: conn.name,
                status: conn.status,
                settings: conn.settings
            })
        }

        Logger.log_debug("NavDrawer: Connections list updated with " + connectionsListModel.count + " items")
    }

    function openSettingsForConnection(connectionId, interfaceType) {
        Logger.log_debug("NavDrawer: Opening settings via unified ConnectionManagerDialog for connection " + connectionId)
        navDrawer.close()
        connectionManagerDialog.openAndEditConnection(connectionId)
    }

    function testFloatingWindow2D() {
        _createExampleChart("time_series", "Time Series")
    }

    function testFloatingWindow3D() {
        _createExampleChart("xyz_scatter", "3D Scatter")
    }

    function testFloatingWindow2DXY() {
        _createExampleChart("time_series", "Time Series X/Y")
    }

    function testFloatingWindowXY() {
        _createExampleChart("xy_line", "Cartesian XY")
    }

    function _createExampleChart(chartType, title) {
        if (!window || !window.workspaceController) {
            Logger.log_error("NavDrawer: Workspace controller unavailable")
            return
        }
        window.workspaceController.createChart(
            chartType,
            title,
            "chart_" + chartType + "_" + Date.now()
        )
    }
}
