import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen?.name ?? ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property bool connected: mainInstance?.isConnected ?? false
    readonly property string server: mainInstance?.currentServer ?? ""

    baseSize: capsuleHeight
    applyUiScale: false
    customRadius: Style.radiusL
    icon: connected ? "shield-lock" : "shield"
    tooltipText: connected ? "Proton VPN – " + server : "Proton VPN"
    tooltipDirection: BarService.getTooltipDirection(screenName)

    colorBg: Style.capsuleColor
    colorFg: Color.mOnSurface
    colorBgHover: Color.mHover
    colorFgHover: Color.mOnHover
    colorBorder: Style.capsuleBorderColor
    colorBorderHover: Style.capsuleBorderColor

    onClicked: {
        if (pluginApi) {
            pluginApi.openPanel(root.screen, root)
        }
    }

    onRightClicked: {
        PanelService.showContextMenu(contextMenu, root, screen)
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": "Settings",
                "action": "settings",
                "icon": "settings"
            }
        ]

        onTriggered: (action) => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)
            if (action === "settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest)
            }
        }
    }
}
