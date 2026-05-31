import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    property bool cmdExists: false
    property bool isLoggedIn: false
    property bool isConnected: false
    property string currentServer: ""
    property var countries: []
    property var countryCodes: ({})

    function countryCode(name) {
        return root.countryCodes[name] || ""
    }

    function refresh() {
        checkCmdProc.running = true
    }

    function refreshCountries() {
        countriesProc.running = true
    }

    function refreshStatus() {
        statusProc.running = true
    }

    Component.onCompleted: {
        startupTimer.running = true
    }

    Timer {
        id: startupTimer
        interval: 100
        onTriggered: {
            checkCmdProc.running = true
        }
    }

    Process {
        id: checkCmdProc
        command: ["sh", "-c", "command -v protonvpn"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (exitCode) => {
            cmdExists = exitCode === 0
            if (cmdExists) {
                checkLoginProc.running = true
                countriesProc.running = true
            }
        }
    }

    Process {
        id: checkLoginProc
        command: ["sh", "-c", "protonvpn info"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: (exitCode) => {
            isLoggedIn = exitCode === 0
        }
    }

    Process {
        id: countriesProc
        property var _lines: []
        command: ["sh", "-c", "protonvpn countries list"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "")
                    countriesProc._lines.push(line)
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                var names = []
                var codes = ({})
                for (var i = 0; i < countriesProc._lines.length; i++) {
                    var match = countriesProc._lines[i].match(/^(.+?)\s{2,}([A-Z]{2})$/)
                    if (match) {
                        var name = match[1]
                        var code = match[2]
                        names.push(name)
                        codes[name] = code
                    }
                }
                countries = names
                countryCodes = codes
            }
            countriesProc._lines = []
        }
    }

    Process {
        id: statusProc
        property var _lines: []
        command: ["sh", "-c", "protonvpn status"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "")
                    statusProc._lines.push(line.trim())
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                var connected = false
                var server = ""
                for (var i = 0; i < statusProc._lines.length; i++) {
                    var line = statusProc._lines[i]
                    if (line.indexOf("Status:") !== -1)
                        connected = line.indexOf("Connected") !== -1
                    else if (line.indexOf("Server:") !== -1)
                        server = line.substring(line.indexOf(":") + 1).trim()
                }
                isConnected = connected
                currentServer = server
            }
            statusProc._lines = []
        }
    }

    onIsLoggedInChanged: {
        if (cmdExists && isLoggedIn)
            statusProc.running = true
    }

    Timer {
        id: statusTimer
        interval: 15000
        repeat: true
        running: cmdExists && isLoggedIn
        onTriggered: statusProc.running = true
    }

    Timer {
        id: refreshCountriesTimer
        interval: 3600000
        repeat: true
        running: cmdExists
        onTriggered: countriesProc.running = true
    }
}
