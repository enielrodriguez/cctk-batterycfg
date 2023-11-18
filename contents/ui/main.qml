import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0


/**
 * This widget uses the Dell Client Configuration Toolkit, therefore it is essential for its operation
 */

Item {
    id: root

    property string cctkBiosPasswordOption: plasmoid.configuration.biosPassword ? " --ValSetupPwd=" + plasmoid.configuration.biosPassword : ""
    property string pkexecPath: plasmoid.configuration.needSudo ? "/usr/bin/pkexec" : "/usr/bin/sudo"

    property string cctkSeedCmd: pkexecPath + " /opt/dell/dcc/cctk"

    // Icons for each status and errors
    property var icons: {
        "standard": Qt.resolvedUrl("./image/standard.png"),
        "adaptive": Qt.resolvedUrl("./image/adaptive.png"),
        "primacuse": Qt.resolvedUrl("./image/primac.png"),
        "express": Qt.resolvedUrl("./image/express.png"),
        "custom": Qt.resolvedUrl("./image/custom.png"),
        "error": Qt.resolvedUrl("./image/error.png")
    }

    // This property represents the current PrimaryBattChargeCfg value
    // Note: This value can change after the execution of onCompleted()
    property string currentStatus: "standard"

    // The desired value for PrimaryBattChargeCfg
    // Note: This value can change after the execution of onCompleted()
    property string desiredStatus: "standard"

    // A flag indicating whether the widget is compatible with the system
    property bool isCompatible: false

    // The notification tool to use (e.g., "zenity" or "notify-send").
    // It is defined automatically through a search in the user's system.
    property string notificationTool: ""

    // A flag indicating if an operation is in progress
    property bool loading: false

    // The currently displayed icon based on the current status
    property string icon: root.isCompatible ? root.icons[root.currentStatus] : root.icons.error

    // Set the icon for the Plasmoid
    Plasmoid.icon: root.icon

    // Executed when the component is completed
    Component.onCompleted: {
        initialSetup()
    }

    // CustomDataSource for querying the current PrimaryBattChargeCfg status
    CustomDataSource {
        id: queryStatusDataSource
        command: root.cctkSeedCmd + " --PrimaryBattChargeCfg"
    }

    // CustomDataSource for setting the PrimaryBattChargeCfg status
    CustomDataSource {
        id: setStatusDataSource

        // Dynamically set in switchStatus(). Set a default value to avoid errors at startup.
        property string status: "adaptive"

        property string seedCmd: root.cctkSeedCmd + " --PrimaryBattChargeCfg="

        // Commands to set different PrimaryBattChargeCfg modes
        property var cmds: {
            "standard": seedCmd + "Standard",
            "adaptive": seedCmd + "Adaptive",
            "primacuse": seedCmd + "PrimAcUse",
            "express": seedCmd + "Express",
            "custom": seedCmd + "Custom:" + plasmoid.configuration.customStart + "-" + plasmoid.configuration.customStop
        }
        command: cmds[status] + root.cctkBiosPasswordOption
    }

    // CustomDataSource for finding the notification tool (notify-send or zenity)
    CustomDataSource {
        id: findNotificationToolDataSource
        // Find notification tool and exclude all “permission denied” errors
        command: "find /usr -type f -executable \\( -name \"notify-send\" -o -name \"zenity\" \\) 2>&1 | grep -v \"Permission denied\""
    }

    // CustomDataSource for sending notifications
    CustomDataSource {
        id: sendNotification

        // Dynamically set in showNotification().
        property string tool: root.notificationTool

        property string iconURL: ""
        property string title: ""
        property string message: ""
        property string options: ""

        property var cmds: {
            "notify-send": `notify-send -i ${iconURL} '${title}' '${message}' ${options}`,
            "zenity": `zenity --notification --text='${title}\\n${message}'`
        }
        command: tool ? cmds[tool] : ""
    }


    // Connection for handling the queryStatusDataSource
    Connections {
        target: queryStatusDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if (stderr) {
                showNotification(root.icons.error, stderr)
            } else {
                // If there are no errors we assume that the system is compatible.
                root.isCompatible = true

                // The output looks like PrimaryBattChargeCfg=Adaptive
                var value = stdout.substring(stdout.indexOf('=') + 1).toLowerCase().trim()
                root.currentStatus = root.desiredStatus = value
            }
        }
    }


    // Connection for handling the setStatusDataSource
    Connections {
        target: setStatusDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){
            root.loading = false

            if (stderr) {
                showNotification(root.icons.error, stderr)
                root.desiredStatus = root.currentStatus
            } else {
                root.currentStatus = root.desiredStatus
                showNotification(root.icons[root.currentStatus], i18n("Status switched to %1.", root.currentStatus.toUpperCase()))
            }
        }
    }


    // Connection for finding the notification tool and querying the current status
    Connections {
        target: findNotificationToolDataSource
        function onExited(exitCode, exitStatus, stdout, stderr){

            if(stderr){
                console.warn(stderr)
            } else {
                setupNotificationTool(stdout)
            }

            queryStatus()
        }
    }

    function setupNotificationTool(stdout: string){
        if(!stdout){
            return
        }

        // Many Linux distros have two notification tools
        var paths = stdout.trim().split("\n")
        var path1 = paths[0]
        var path2 = paths[1]

        // Prefer notify-send because it allows using an icon; zenity v3.44.0 does not accept an icon option
        if (path1 && path1.trim().endsWith("notify-send")) {
            root.notificationTool = "notify-send"
        } else if (path2 && path2.trim().endsWith("notify-send")) {
            root.notificationTool = "notify-send"
        } else if (path1 && path1.trim().endsWith("zenity")) {
            root.notificationTool = "zenity"
        } else {
            console.warn("No compatible notification tool found.")
        }
    }

    // Get the current status by executing the queryStatusDataSource
    function queryStatus() {
        root.loading = true
        queryStatusDataSource.exec()
    }

    // Switch PrimaryBattChargeCfg status
    function switchStatus() {
        root.loading = true

        showNotification(root.icons[root.desiredStatus], i18n("Switching status to %1.", root.desiredStatus.toUpperCase()))

        setStatusDataSource.status = root.desiredStatus
        setStatusDataSource.exec()
    }

    // Show a notification with icon, message, and title
    function showNotification(iconURL: string, message: string, title = i18n("Battery Charge Configuration"), options = ""){
        if(root.notificationTool){
            sendNotification.iconURL = iconURL
            sendNotification.title = title
            sendNotification.message = message
            sendNotification.options = options

            sendNotification.exec()
        } else {
            console.warn(message)
        }
    }

    // Find the notification tool by executing the findNotificationToolDataSource
    function initialSetup() {
        findNotificationToolDataSource.exec()
    }


    // Set the preferred representation of the Plasmoid to the compact representation
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    // Compact representation of the Plasmoid
    Plasmoid.compactRepresentation: Item {
        PlasmaCore.IconItem {
            height: plasmoid.configuration.iconSize
            width: plasmoid.configuration.iconSize
            anchors.centerIn: parent

            source: root.icon
            active: compactMouse.containsMouse

            MouseArea {
                id: compactMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    plasmoid.expanded = !plasmoid.expanded
                }
            }
        }
    }

    // Full representation of the Plasmoid
    Plasmoid.fullRepresentation: Item {
        Layout.preferredWidth: 400 * PlasmaCore.Units.devicePixelRatio
        Layout.preferredHeight: 300 * PlasmaCore.Units.devicePixelRatio

        ColumnLayout {
            anchors.centerIn: parent

            Image {
                id: mode_image
                source: root.icon
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 64
                fillMode: Image.PreserveAspectFit
            }


            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignCenter
                text: root.isCompatible ? i18n("Battery Charge Configuration is set to %1.", root.currentStatus.toUpperCase()) : i18n("The Battery Charge Configuration feature is not available.")
            }


            PlasmaComponents3.ComboBox {
                Layout.alignment: Qt.AlignCenter

                enabled: !root.loading && root.isCompatible
                model: [
                    {text: "Standard", value: "standard"},
                    {text: "Express", value: "express"},
                    {text: "PrimAcUse", value: "primacuse"},
                    {text: "Adaptive", value: "adaptive"},
                    {text: "Custom", value: "custom"}
                ]
                textRole: "text"
                valueRole: "value"
                currentIndex: model.findIndex((element) => element.value === root.desiredStatus)

                onCurrentIndexChanged: {
                    root.desiredStatus = model[currentIndex].value
                    if (root.desiredStatus !== root.currentStatus) {
                        switchStatus()
                    }
                }
            }

            BusyIndicator {
                id: loadingIndicator
                Layout.alignment: Qt.AlignCenter
                running: root.loading
            }

        }
    }

    // Main tooltip text for the Plasmoid
    Plasmoid.toolTipMainText: i18n("Switch Battery Charge Configuration mode.")

    // Subtext for the tooltip, indicating the current status
    Plasmoid.toolTipSubText: root.isCompatible ? i18n("Battery Charge Configuration is set to %1.", root.currentStatus.toUpperCase()) : i18n("The Battery Charge Configuration feature is not available.")
}
