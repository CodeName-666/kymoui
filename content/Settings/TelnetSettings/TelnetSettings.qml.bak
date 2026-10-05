import QtQuick 6.4
import QtQuick.Controls 6.4

TelnetSettingsUi {


    /*******************************************************************
     * FUNCTION
     ******************************************************************/
    function get_settings()
    {
        const port = parseInt(portInput.text)
        return  {
                 "host": ipInput.text,
                 "port": isNaN(port) ? 0 : port
                }
    }


    /*******************************************************************
     * FUNCTION
     ******************************************************************/
    function set_settings(settings)
    {
        if(!settings)
            return
        ipInput.text = settings["host"] !== undefined ? settings["host"] : settings["ip"];
        portInput.text = settings["port"] !== undefined ? settings["port"] : "";
    }
}
