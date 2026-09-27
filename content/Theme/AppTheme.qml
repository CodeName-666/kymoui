pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick 6.4

QtObject {
    id: theme

    // Color palette
    readonly property QtObject palette: QtObject {
        readonly property color primary: "#3fb7ff"
        readonly property color primaryHover: "#2fa4e6"
        readonly property color primaryPressed: "#238dc9"
        readonly property color primaryBorder: "#1f86c5"
        readonly property color accent: "#2dd4b0"
        readonly property color danger: "#ff6b6b"
        readonly property color success: "#40c057"
        readonly property color warning: "#f3c14b"
    }

    readonly property QtObject surfaces: QtObject {
        readonly property color background: "#0f131a"
        readonly property color interfaceBackground: "#141a24"
        readonly property color card: "#1b2430"
        readonly property color muted: "#10151d"
    }

    readonly property QtObject borders: QtObject {
        readonly property color primary: "#273142"
        readonly property color subtle: "#1f2836"
        readonly property color focus: palette.primary
        readonly property color danger: palette.danger
        readonly property color disabled: "#3b4657"
    }

    readonly property QtObject text: QtObject {
        readonly property color primary: "#eef3fb"
        readonly property color secondary: "#a4afc3"
        readonly property color label: "#d2daea"
        readonly property color contrast: "#0c1118"
        readonly property color disabled: "#7b879c"
        readonly property color placeholder: "#8e9bb1"
    }

    readonly property QtObject states: QtObject {
        readonly property color disabledBackground: "#2a3443"
    }

    readonly property QtObject inputs: QtObject {
        readonly property color background: surfaces.card
        readonly property color disabledBackground: "#1a2230"
    }

    readonly property QtObject buttons: QtObject {
        readonly property QtObject neutral: QtObject {
            readonly property color background: "#2a3443"
            readonly property color hover: "#313d50"
            readonly property color pressed: "#273246"
            readonly property color border: "#334255"
            readonly property color text: "#eef3fb"
        }
    }

    readonly property QtObject spacing: QtObject {
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 20
        readonly property int extraLarge: 24
    }

    readonly property QtObject heights: QtObject {
        readonly property int input: 40
        readonly property int button: 40
        readonly property int combobox: 40
        readonly property int smallInput: 32
        readonly property int label: 40
    }

    readonly property QtObject radius: QtObject {
        readonly property int small: 4
        readonly property int medium: 6
        readonly property int large: 8
        readonly property int extraLarge: 10
    }

    readonly property QtObject fontSize: QtObject {
        readonly property int small: 12
        readonly property int medium: 14
        readonly property int large: 16
        readonly property int title: 20
        readonly property int header: 18
        readonly property int button: 13
    }

    readonly property QtObject margins: QtObject {
        readonly property int small: 8
        readonly property int medium: 16
        readonly property int large: 20
        readonly property int extraLarge: 24
    }
}
