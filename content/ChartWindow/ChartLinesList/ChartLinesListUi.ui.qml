import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 1.15

Item {
    id: root

    property alias listView: listView
    property alias headerLabel: headerLabel
    property alias collapseButton: collapseButton
    property alias headerCollapseButton: headerCollapseButton
    property bool isCollapsed: false

    Rectangle {
        anchors.fill: parent
        color: "#f8f8f8"
        border.color: "#d0d0d0"
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
                    if (collapseButton.pressed) return "#1565c0"
                    if (collapseButton.hovered) return "#1976d2"
                    return "#2196f3"
                }
                radius: 6
                border.color: "#1565c0"
                border.width: 1
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Expanded state - full layout
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            visible: !root.isCollapsed

            // Header with collapse button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    id: headerLabel
                    text: qsTr("Chart Lines")
                    font.pixelSize: 14
                    font.bold: true
                    color: "#444"
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
                            if (headerCollapseButton.pressed) return "#1565c0"
                            if (headerCollapseButton.hovered) return "#1976d2"
                            return "#2196f3"
                        }
                        radius: 4
                        border.color: "#1565c0"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#d0d0d0"
                visible: !root.isCollapsed
            }

            // List view
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                visible: !root.isCollapsed
                opacity: root.isCollapsed ? 0.0 : 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Item {
                    width: listView.width
                    height: 40

                    Rectangle {
                        anchors.fill: parent
                        color: mouseArea.containsMouse ? "#e3f2fd" : "transparent"
                        radius: 6
                        border.color: model.visible ? "#1976d2" : "transparent"
                        border.width: model.visible ? 1 : 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            // Color indicator
                            Rectangle {
                                id: colorIndicator
                                width: 20
                                height: 20
                                radius: 10
                                color: model.color
                                border.color: "#ffffff"
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Display name
                            Label {
                                id: nameLabel
                                text: model.displayName
                                color: model.visible ? "#222" : "#999"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Interface type badge
                            Rectangle {
                                width: typeLabel.width + 12
                                height: 20
                                radius: 3
                                color: "#e0e0e0"
                                Layout.alignment: Qt.AlignVCenter

                                Label {
                                    id: typeLabel
                                    anchors.centerIn: parent
                                    text: model.interfaceType
                                    color: "#555"
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
                                    color: visibilityButton.hovered ? "#e0e0e0" : "transparent"
                                    radius: 3
                                }

                                contentItem: Text {
                                    text: model.visible ? "\u{1F441}" : "\u{1F441}\u{FE0F}\u{200D}\u{1F5E8}\u{FE0F}"
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: model.visible ? "#2196f3" : "#999"
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true

                            onClicked: {
                                // Future: select line for editing
                            }
                        }
                    }
                }

                // Empty state
                Label {
                    anchors.centerIn: parent
                    text: qsTr("No chart lines")
                    color: "#999"
                    font.pixelSize: 12
                    visible: listView.count === 0
                }
            }
        }
    }
}
