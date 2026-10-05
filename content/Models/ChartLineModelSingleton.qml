pragma Singleton
import QtQuick 6.4

/**
 * Singleton instance of ChartLineModel for global access
 *
 * Usage:
 *   import "Models"
 *   ChartLineModelSingleton.addLine(...)
 */
ChartLineModel {
    id: singleton

    Component.onCompleted: {
        console.log("ChartLineModelSingleton: Initialized")
    }
}
