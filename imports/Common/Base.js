.pragma library
.import QtQuick 6.6 as QtQuick


function get_workspace_path()
{
    return  Qt.resolvedUrl("../../")
}


function create_component(path_to_component, parent = undefined) {

    var base_path = get_workspace_path()
    var file_path = base_path + path_to_component
    var component = Qt.createComponent(file_path);
    var used_parent = Qt.application
    if (component.status === QtQuick.Component.Ready) {
        if(parent !== undefined)
            used_parent = parent
        var object = component.createObject(used_parent);
        if (object === null) {
            console.error("Error: Komponente konnte nicht erstellt werden.");
            return null;
        }
        return object;
    } else if (component.status === QtQuick.Component.Error) {
        console.error("Error:", component.errorString());
        return null;
    } else {
        console.error("Error: Unbekannter Status beim Erstellen der Komponente.");
        return null;
    }
}
