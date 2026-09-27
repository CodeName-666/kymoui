import QtQuick 6.4
import QtCharts 2.3
import QtQuick.Layouts 1.11
import QtQuick.Controls 6.4
import "ChartLinesList"
import "FloatingActionButton"
import "../Theme"

Item {
    property alias chart: chart
    property alias xAxis: xAxis
    property alias yAxis: yAxis
    property alias title: chart.title
    property alias chartMouseArea: chartMouseArea
    property alias horizontalScrollMask: horizontalScrollMask
    property alias verticalScrollMask: verticalScrollMask
    property alias chartControls: chartControls
    property alias yAxisControls: yAxisControls
    property alias chartLinesList: chartLinesList
    property alias fabButton: fabButton

    property bool chartLinesListCollapsed: false
    property int chartLinesListWidth: 280
    property int chartLinesListCollapsedWidth: 50

    ChartView {
        id: chart
        title: "Data Plot"
        objectName: "chart"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: chartLinesList.left
        anchors.rightMargin: 10
        legend.alignment: Qt.AlignBottom
        antialiasing: true
        theme: ChartView.ChartThemeDark

        Rectangle {
            color: "transparent"
            width: 1
            height: 1
            id: horizontalScrollMask
            visible: false
        }

        Rectangle {
            color: "transparent"
            width: 1
            height: 1
            id: verticalScrollMask
            visible: false
        }

        MouseArea {
            id: chartMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }

        ValuesAxis {
            id: xAxis
            min: 0
            max: 10
        }

        ValuesAxis {
            id: yAxis
            min: 0
            max: 10
        }
    }

    // Compact zoom controls - positioned left of chart lines panel to avoid overlap
    ChartControls {
        id: chartControls
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: chartLinesListCollapsed ? 76 : 306
        z: 100
    }

    // Dedicated Y-axis zoom buttons on the left near the axis
    Rectangle {
        id: yAxisControls
        signal zoomYIn()
        signal zoomYOut()

        property int buttonSize: 32

        width: buttonSize + 12
        height: buttonSize * 2 + 12
        radius: 6
        color: Qt.rgba(20 / 255, 26 / 255, 36 / 255, 0.85)
        border.color: AppTheme.borders.primary
        border.width: 1

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        z: 100

        opacity: yMouseArea.containsMouse ? 1.0 : 0.35
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            id: yMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            ToolButton {
                id: yZoomInBtn
                text: "Y+"
                font.pixelSize: 16
                font.bold: true
                Layout.preferredWidth: yAxisControls.buttonSize
                Layout.preferredHeight: yAxisControls.buttonSize

                ToolTip.visible: hovered
                ToolTip.text: qsTr("Zoom In (Y axis)")
                ToolTip.delay: 400

                background: Rectangle {
                    color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                    radius: 4
                    border.color: parent.hovered ? AppTheme.borders.subtle : "transparent"
                }

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: AppTheme.text.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: yAxisControls.zoomYIn()
            }

            ToolButton {
                id: yZoomOutBtn
                text: "Y-"
                font.pixelSize: 16
                font.bold: true
                Layout.preferredWidth: yAxisControls.buttonSize
                Layout.preferredHeight: yAxisControls.buttonSize

                ToolTip.visible: hovered
                ToolTip.text: qsTr("Zoom Out (Y axis)")
                ToolTip.delay: 400

                background: Rectangle {
                    color: parent.hovered ? AppTheme.surfaces.muted : "transparent"
                    radius: 4
                    border.color: parent.hovered ? AppTheme.borders.subtle : "transparent"
                }

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: AppTheme.text.primary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: yAxisControls.zoomYOut()
            }
        }
    }

    // Charts Manager - right side panel (collapsible)
    ChartsManager {
        id: chartLinesList
        width: chartLinesListCollapsed ? chartLinesListCollapsedWidth : chartLinesListWidth
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 10
        z: 120

        isCollapsed: chartLinesListCollapsed

        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }
    }

    // Floating Action Button - bottom-right corner (adjusts position based on panel state)
    FloatingActionButton {
        id: fabButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: chartLinesListCollapsed ? (chartLinesListCollapsedWidth + 20) : (chartLinesListWidth + 30)
        anchors.bottomMargin: 20
        z: 110

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }
    }
}
