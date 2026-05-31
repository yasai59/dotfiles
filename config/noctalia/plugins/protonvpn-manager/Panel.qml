import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 400 * Style.uiScaleRatio
    property real contentPreferredHeight: 520 * Style.uiScaleRatio

    anchors.fill: parent

    readonly property var mainInstance: pluginApi?.mainInstance

    // Reactive bindings to persistent Main.qml state
    readonly property bool cmdExists: mainInstance?.cmdExists ?? false
    readonly property bool isLoggedIn: mainInstance?.isLoggedIn ?? false
    readonly property bool isConnected: mainInstance?.isConnected ?? false
    readonly property string currentServer: mainInstance?.currentServer ?? ""
    readonly property var countries: mainInstance?.countries ?? []
    readonly property var countryCodes: mainInstance?.countryCodes ?? ({})

    // Local panel-only state
    property bool isConnecting: false
    property string searchText: ""

    readonly property string statusMessage: {
        if (!mainInstance) return ""
        if (!cmdExists) return "protonvpn-cli not installed"
        if (!isLoggedIn) return "Not logged in. Run 'protonvpn login'"
        return ""
    }

    readonly property var filteredCountries: {
        if (searchText === "") return countries
        var q = searchText.toLowerCase()
        var res = []
        for (var i = 0; i < countries.length; i++) {
            if (countries[i].toLowerCase().indexOf(q) !== -1)
                res.push(countries[i])
        }
        return res
    }

    function countryCode(name) {
        return root.countryCodes[name] || ""
    }

    Process {
        id: connectProc
        property string targetCountryCode: ""
        command: targetCountryCode === "" ? ["protonvpn", "connect"] : ["protonvpn", "connect", "--country", targetCountryCode]
        onExited: {
            isConnecting = false
            mainInstance?.refreshStatus()
        }
    }

    Process {
        id: disconnectProc
        command: ["protonvpn", "disconnect"]
        onExited: {
            mainInstance?.refreshStatus()
        }
    }

    function quickConnect() {
        if (isConnecting) return
        isConnecting = true
        connectProc.targetCountryCode = ""
        connectProc.running = true
    }

    function quickDisconnect() {
        disconnectProc.running = true
    }

    function connectToCountry(name) {
        if (isConnecting) return
        isConnecting = true
        connectProc.targetCountryCode = countryCode(name)
        connectProc.running = true
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            // Status banner
            NBox {
                visible: statusMessage !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: 40 * Style.uiScaleRatio

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    NIcon {
                        icon: cmdExists && isLoggedIn ? "info" : "triangle-alert"
                        pointSize: Style.fontSizeM
                        color: cmdExists && isLoggedIn ? Color.mPrimary : Color.mError
                    }

                    NText {
                        Layout.fillWidth: true
                        text: statusMessage
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Quick connect
            NBox {
                visible: cmdExists && isLoggedIn
                Layout.fillWidth: true
                Layout.preferredHeight: connectRow.implicitHeight + Style.marginM * 2

                RowLayout {
                    id: connectRow
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    NIcon {
                        icon: isConnected ? "power" : "power-off"
                        pointSize: Style.fontSizeL
                        color: isConnected ? Color.mPrimary : Color.mOnSurfaceVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginXXS

                        RowLayout {
                            spacing: Style.marginS

                            NText {
                                text: isConnected ? "Connected" : "Quick Connect"
                                pointSize: Style.fontSizeM
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                            }

                            NIcon {
                                icon: "loader"
                                pointSize: Style.fontSizeM
                                color: Color.mPrimary
                                visible: isConnecting

                                RotationAnimator on rotation {
                                    running: isConnecting
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }
                            }
                        }

                        NText {
                            text: isConnected ? currentServer : "Connect to fastest server"
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurfaceVariant
                        }
                    }

                    Item { Layout.fillWidth: true }

                    NToggle {
                        enabled: !isConnecting
                        checked: isConnected
                        onToggled: (checked) => {
                            if (checked) quickConnect()
                            else quickDisconnect()
                        }
                    }
                }
            }

            // Server status
            NBox {
                visible: cmdExists && isLoggedIn
                Layout.fillWidth: true
                Layout.preferredHeight: serverRow.implicitHeight + Style.marginM * 2

                RowLayout {
                    id: serverRow
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    NIcon {
                        icon: isConnected ? "globe" : "globe-off"
                        pointSize: Style.fontSizeL
                        color: isConnected ? Color.mPrimary : Color.mOnSurfaceVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginXXS

                        NText {
                            text: "Server"
                            pointSize: Style.fontSizeM
                            font.weight: Font.Bold
                        }

                        NText {
                            text: isConnected ? currentServer : "Not connected"
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurfaceVariant
                        }
                    }

                    NIconButton {
                        icon: "refresh"
                        baseSize: Style.baseWidgetSize * 0.8
                        tooltipText: "Refresh"
                        onClicked: mainInstance?.refreshStatus()
                    }
                }
            }

            // Country list
            NBox {
                visible: cmdExists && isLoggedIn
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NTextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Search country..."
                            text: root.searchText
                            onTextChanged: root.searchText = text
                        }

                        NIconButton {
                            icon: "refresh"
                            baseSize: Style.baseWidgetSize * 0.8
                            tooltipText: "Refresh countries"
                            onClicked: mainInstance?.refreshCountries()
                        }
                    }

                    NScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        horizontalPolicy: ScrollBar.AlwaysOff
                        verticalPolicy: ScrollBar.AsNeeded
                        reserveScrollbarSpace: false

                        ListView {
                            id: countryListView
                            anchors.fill: parent
                            clip: true
                            model: root.filteredCountries
                            spacing: Style.marginXS
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                required property string modelData

                                readonly property string countryName: modelData
                                readonly property bool hovered: mouseArea.containsMouse

                                width: countryListView.width
                                implicitHeight: 36 * Style.uiScaleRatio
                                radius: Style.radiusM
                                color: hovered ? Color.mHover : "transparent"

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.connectToCountry(countryName)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Style.marginM
                                    anchors.rightMargin: Style.marginM
                                    spacing: Style.marginS

                                    NText {
                                        Layout.fillWidth: true
                                        text: countryName
                                        pointSize: Style.fontSizeS
                                        color: hovered ? Color.mOnHover : Color.mOnSurface
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    NText {
                                        text: root.countryCode(countryName)
                                        pointSize: Style.fontSizeXS
                                        color: hovered ? Color.mOnHover : Color.mOnSurfaceVariant
                                        opacity: hovered ? 1.0 : 0.6
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Disconnect button
            NButton {
                visible: cmdExists && isLoggedIn && isConnected
                Layout.fillWidth: true
                text: "Disconnect"
                icon: "plug-x"
                backgroundColor: Color.mError
                textColor: Color.mOnError
                onClicked: quickDisconnect()
            }
        }
    }
}
