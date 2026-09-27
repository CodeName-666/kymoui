import QtQuick 6.4


QtObject {

    /* Chart Signals/Events */

    /**
     * @brief New Graph Event
     * @param uniqueId - Unique identifier (format: "interface_dataId")
     * @param displayName - User-friendly display name
     * @param color - Line color
     * @param interfaceType - Interface type (Serial, MQTT, etc.)
     */
    signal newGraph(var uniqueId, var displayName, var color, var interfaceType);
    /**
     * @brief Append a value to an existing graph
     */
    signal append_graph_point(var name, var point);
    /**
     * @brief Append multiple points to an existing graph (batch update)
     */
    signal append_graph_points_batch(var uniqueId, var points);
    /**
     * @brief Append a 3D point to an existing graph (for XYZ charts)
     * @param uniqueId - Unique identifier
     * @param point - Point object with x, y, z properties
     */
    signal append_graph_point_3d(var uniqueId, var point);
    /**
     * @brief Append multiple 3D points to an existing graph (batch update for XYZ charts)
     * @param uniqueId - Unique identifier
     * @param points - Array of [x, y, z] arrays
     */
    signal append_graph_points_batch_3d(var uniqueId, var points);
    /**
     * @brief Message received/update event (latest state per message)
     * @param message - Object with keys: uniqueId, displayName, interface, interfaceType, dataId,
     *                  x, y, z, timestamp, t, rxTime, cycleTime, rxCount
     */
    signal message_received(var message)
    /** Remove all UI state for signals owned by a deleted connection. */
    signal signals_removed(var uniqueIds)
    /**
     * @brief Scroll Right Event
     */
    signal scrollRight(var pixel);
    /**
     * @brief Com Port Update Event
     */
    signal com_port_update(var portList);
    /**
     * @brief Setup Settings Event
     *
     * Event to setup the Settings Ui
     */
    signal ui_setup(var settings)
    /**
     * @brief General status notification
     */
    signal status_message(var level, var message)


}
