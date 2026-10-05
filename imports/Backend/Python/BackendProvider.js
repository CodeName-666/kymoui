.pragma library

function has_backend() {
    return typeof Backend !== 'undefined'
}

function set_settings(interface_type, settings) {
    if (has_backend() && Backend.set_settings)
        return Backend.set_settings(interface_type, settings)
    console.warn("BackendProvider.set_settings: Backend unavailable")
    return false
}

function get_settings(interface_type) {
    if (has_backend() && Backend.get_settings)
        return Backend.get_settings(interface_type)
    console.warn("BackendProvider.get_settings: Backend unavailable")
    return null
}

function settings_valid() {
    if (has_backend() && Backend.settings_valid)
        return Backend.settings_valid()
    console.warn("BackendProvider.settings_valid: Backend unavailable")
    return false
}

function connect() {
    if (has_backend()) {
        if (Backend.connect)
            return Backend.connect()
        if (Backend.connectTo)
            return Backend.connectTo("")
    }
    console.warn("BackendProvider.connect: Backend unavailable")
    return false
}

function is_connect() {
    if (has_backend()) {
        if (Backend.is_connect)
            return Backend.is_connect()
        if (Backend.connected)
            return Backend.connected()
    }
    return false
}

function set_plot_area(area) {
    if (has_backend() && Backend.set_plot_area)
        Backend.set_plot_area(area)
}

function add_graph(name, graph) {
    if (has_backend() && Backend.add_graph)
        Backend.add_graph(name, graph)
}

function set_axis(xAxis, yAxis) {
    if (has_backend() && Backend.set_axis)
        Backend.set_axis(xAxis, yAxis)
}
