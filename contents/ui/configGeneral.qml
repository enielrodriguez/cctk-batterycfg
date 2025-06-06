import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configGeneral

    property alias cfg_biosPassword: biosPasswordField.text
    property alias cfg_needSudo: needSudoField.checked
    property alias cfg_customStart: customStartField.value
    property alias cfg_customStop: customStopField.value
    property alias cfg_iconSize: iconSizeComboBox.currentValue

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Security")
    }

    TextField {
        id: biosPasswordField
        Kirigami.FormData.label: i18n("BIOS password (leave empty if you do not have a BIOS password):")
        echoMode: TextInput.Password
    }
    Label {
        id: noteBiosPasswordField
        text: "NOTE: Passwords with special characters must be enclosed in double inverted quotes (“”)"
    }

    CheckBox {
        id: needSudoField
        text: i18n("I need sudo")
        anchors.top: noteBiosPasswordField.bottom
        anchors.topMargin: 15
    }
    Label {
        text: "NOTE: Check this option if you need sudo to run CCTK"
        anchors.top: needSudoField.bottom
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Start and stop values for Custom option")
    }

    SpinBox {
        id: customStartField
        Kirigami.FormData.label: i18n("Start") + " (50–95):"
        from: 50
        to: 95
        stepSize: 1
        value: 50

        onValueChanged: {
            if (value + 5 > customStopField.value) {
                customStopField.value = value + 5;
            }
        }
    }

    SpinBox {
        id: customStopField
        Kirigami.FormData.label: i18n("Stop") + " (55–100):"
        from: 55
        to: 100
        stepSize: 1
        value: 55

        onValueChanged: {
            if (value - 5 < customStartField.value) {
                customStartField.value = value - 5;
            }
        }
    }


    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Other settings")
    }


    ComboBox {
        id: iconSizeComboBox

        Kirigami.FormData.label: i18n("Icon size:")
        model: [
            {text: "small", value: units.iconSizes.small},
            {text: "small-medium", value: units.iconSizes.smallMedium},
            {text: "medium", value: units.iconSizes.medium},
            {text: "large", value: units.iconSizes.large},
            {text: "huge", value: units.iconSizes.huge}
        ]
        textRole: "text"
        valueRole: "value"

        currentIndex: model.findIndex((element) => element.value === plasmoid.configuration.iconSize)
    }

}
