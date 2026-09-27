pragma Singleton
import QtQuick 6.4
import "../../Theme"

QtObject {
    id: theme

    readonly property color cardBackground: AppTheme.surfaces.card
    readonly property color settingsBackground: AppTheme.surfaces.background
    readonly property color interfaceBackground: AppTheme.surfaces.interfaceBackground
    readonly property color borderColor: AppTheme.borders.primary
    readonly property color borderColorLight: AppTheme.borders.subtle
    readonly property color textPrimary: AppTheme.text.primary
    readonly property color textSecondary: AppTheme.text.secondary
    readonly property color textLabel: AppTheme.text.label
    readonly property color errorColor: AppTheme.palette.danger
    readonly property color errorBackground: "#3a1f23"
    readonly property color successColor: AppTheme.palette.success
    readonly property color highlightColor: AppTheme.palette.primary

    readonly property QtObject spacing: AppTheme.spacing
    readonly property QtObject heights: AppTheme.heights
    readonly property QtObject radius: AppTheme.radius
    readonly property QtObject fontSize: AppTheme.fontSize
    readonly property QtObject margins: AppTheme.margins
}
