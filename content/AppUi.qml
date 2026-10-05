import QtQuick 6.4
import QtQuick.Window 2.15
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15
import Common 1.0
import Theme 1.0
import "Footer"
import "ChartWindow/ChartLinesList"
import "ChartWindow/FloatingActionButton"
import "Toolbar"
import "Workspace"
ApplicationWindow {
    id: applicationWindow
    objectName: "applicationWindow"
    width: Constants.width
    height: Constants.height
    visible: true
    color: AppTheme.surfaces.background
    title: qsTr(Constants.title)
    font.family: "Space Grotesk"
    font.pixelSize: 14
    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: AppTheme.surfaces.background }
            GradientStop { position: 1.0; color: AppTheme.surfaces.interfaceBackground }
        }
    }

    property var appController
    property var workspaceController

    property alias settingsPopup: settingsPopup
    property alias chartWorkspace: chartWorkspace
    property alias toolbar: topToolbar
    property alias navDrawer: navDrawer

    header: Toolbar {
        id: topToolbar
        onMenuRequested: navDrawer.open()
    }

    // State for chart lines list
    property bool chartLinesListCollapsed: false
    property int chartLinesListWidth: 360
    property int chartLinesListCollapsedWidth: 48

    Item {
        id: mainArea
        anchors.fill: parent
        opacity: 1

        // Split area: chart workspace (left) + manager sidebar (right)
        Item {
            id: splitArea
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: footer.top
            }

            RowLayout {
                id: splitLayout
                anchors.fill: parent
                spacing: 10

                // Workspace area for charts/floating windows (excludes right-side manager panel)
                Item {
                    id: chartWorkspace
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    z: 0

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: AppTheme.surfaces.interfaceBackground }
                            GradientStop { position: 1.0; color: AppTheme.surfaces.muted }
                        }
                        border.color: AppTheme.borders.subtle
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.min(430, parent.width - 48)
                            spacing: 12

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("No chart open")
                                font.pixelSize: 18
                                font.bold: true
                                color: AppTheme.text.primary
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Create a time series or a Cartesian XY chart, then assign incoming signals in the workspace panel.")
                                font.pixelSize: 13
                                color: AppTheme.text.secondary
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                        }
                    }

                    ChartWorkspace {
                        id: workspaceView
                        anchors.fill: parent
                        z: 10
                        workspaceController: applicationWindow.workspaceController
                    }
                }

                // Charts Manager - right side panel (collapsible, management tabs)
                ChartsManager {
                    id: chartLinesList
                    Layout.preferredWidth: chartLinesListCollapsed ? chartLinesListCollapsedWidth : chartLinesListWidth
                    Layout.fillHeight: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    Layout.rightMargin: 10
                    // Always stay visible above chart content.
                    z: 100

                    isCollapsed: chartLinesListCollapsed
                    chartLineModel: applicationWindow.workspaceController ? applicationWindow.workspaceController.chartLineModel : null
                    signalModel: applicationWindow.workspaceController ? applicationWindow.workspaceController.signalModel : null
                    messageModel: applicationWindow.workspaceController ? applicationWindow.workspaceController.messageModel : null
                    availableCharts: applicationWindow.workspaceController ? applicationWindow.workspaceController.availableCharts : []

                    onCollapseToggled: {
                        chartLinesListCollapsed = !chartLinesListCollapsed
                    }

                    onLineVisibilityToggled: function(lineKey, visible) {
                        if (applicationWindow.workspaceController) {
                            applicationWindow.workspaceController.setLineVisibility(lineKey, visible)
                        }
                    }

                    onLineSelected: function(lineKey) {
                        workspaceDialogs.openEditLine(lineKey)
                    }

                    onAddSignalRequested: {
                        workspaceDialogs.openAddSignal()
                    }

                    onRemoveSignalRequested: function(uniqueId) {
                        if (applicationWindow.workspaceController) applicationWindow.workspaceController.removeSignal(uniqueId)
                    }

                    onSetSignalChartsRequested: function(uniqueId, assignments) {
                        if (applicationWindow.workspaceController) applicationWindow.workspaceController.setSignalCharts(uniqueId, assignments)
                    }

                    onCreateChartRequested: function(chartType, chartTitle, chartId) {
                        if (applicationWindow.workspaceController) applicationWindow.workspaceController.createChart(chartType, chartTitle, chartId)
                    }

                    onRemoveChartRequested: function(chartId) {
                        if (applicationWindow.workspaceController) applicationWindow.workspaceController.removeChart(chartId)
                    }

                    onRenameChartRequested: function(chartId, chartTitle) {
                        if (applicationWindow.workspaceController) applicationWindow.workspaceController.renameChart(chartId, chartTitle)
                    }

                }
            }
        }

        // Primary workspace action. Its label avoids an ambiguous, icon-only "+" action.
        FloatingActionButton {
            id: fabButton
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.rightMargin: chartLinesListCollapsed ? (chartLinesListCollapsedWidth + 20) : (chartLinesListWidth + 30)
            anchors.bottomMargin: 20
            z: 110

            label: qsTr("New chart")
            onClicked: chartLinesList.openCreateChartDialog()
        }

        Footer {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }

        WorkspaceDialogs {
            id: workspaceDialogs
            anchors.fill: parent
            workspaceController: applicationWindow.workspaceController
        }
    }

    NavDrawer {
        id: navDrawer
        window: applicationWindow
        settingsPopup: settingsPopup
    }

    Popup {
        id: settingsPopup
        width: parent.width * 0.55
        height: parent.height * 0.65
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        contentItem: Loader {
            id: settingsLoader
            anchors.fill: parent
            asynchronous: false
            source: "Settings/Settings.qml"
        }
    }
}
