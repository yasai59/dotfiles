import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property bool loadingWallpaperProperties: false
  property string wallpaperPropertyError: ""
  property var wallpaperPropertyDefinitions: []
  property var propertyValueFor: null
  property var numberOr: null
  property var formatSliderValue: null
  property var comboChoicesFor: null
  property var ensureColorValue: null
  property var serializePropertyValue: null
  property var setPropertyValue: null

  Layout.fillWidth: true
  spacing: Style.marginS

  NText {
    text: pluginApi?.tr("panel.sectionProperties")
    color: Color.mOnSurface
    font.weight: Font.Bold
    font.pointSize: Style.fontSizeM
  }

  NText {
    visible: root.loadingWallpaperProperties
    Layout.fillWidth: true
    text: pluginApi?.tr("panel.loadingProperties")
    color: Color.mOnSurfaceVariant
    wrapMode: Text.Wrap
  }

  NText {
    visible: !root.loadingWallpaperProperties && root.wallpaperPropertyError.length > 0
    Layout.fillWidth: true
    text: root.wallpaperPropertyError
    color: Color.mError
    wrapMode: Text.Wrap
  }

  NText {
    visible: !root.loadingWallpaperProperties && root.wallpaperPropertyError.length === 0 && root.wallpaperPropertyDefinitions.length === 0
    Layout.fillWidth: true
    text: pluginApi?.tr("panel.noEditableProperties")
    color: Color.mOnSurfaceVariant
    wrapMode: Text.Wrap
  }

  NText {
    visible: !root.loadingWallpaperProperties && root.wallpaperPropertyDefinitions.length > 0
    Layout.fillWidth: true
    text: pluginApi?.tr("panel.propertiesNotice")
    color: Color.mOnSurfaceVariant
    wrapMode: Text.Wrap
  }

  Repeater {
    model: root.wallpaperPropertyDefinitions

    delegate: ColumnLayout {
      id: propertyEditor
      required property var modelData
      Layout.fillWidth: true
      spacing: Style.marginXS

      property bool boolValue: !!(root.propertyValueFor ? root.propertyValueFor(modelData) : false)
      property real sliderValue: root.numberOr ? root.numberOr(root.propertyValueFor ? root.propertyValueFor(modelData) : 0, 0) : 0
      property string comboValue: String(root.propertyValueFor ? root.propertyValueFor(modelData) : "")
      property string textValue: String(root.propertyValueFor ? root.propertyValueFor(modelData) : "")
      property color colorValue: Qt.rgba(1, 1, 1, 1)

      Component.onCompleted: {
        if (modelData.type === "color" && root.ensureColorValue && root.propertyValueFor) {
          propertyEditor.colorValue = root.ensureColorValue(root.propertyValueFor(modelData));
        }
      }

      NToggle {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? implicitHeight : 0
        visible: modelData.type === "boolean"
        label: modelData.label
        checked: propertyEditor.boolValue
        onToggled: checked => {
          if (checked === propertyEditor.boolValue) {
            return;
          }
          propertyEditor.boolValue = checked;
          if (root.setPropertyValue) {
            root.setPropertyValue(modelData.key, checked);
          }
        }
      }

      NValueSlider {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? implicitHeight : 0
        visible: modelData.type === "slider"
        label: modelData.label
        from: root.numberOr ? root.numberOr(modelData.min, 0) : 0
        to: root.numberOr ? root.numberOr(modelData.max, 100) : 100
        stepSize: Math.max(root.numberOr ? root.numberOr(modelData.step, 1) : 1, 0.001)
        value: propertyEditor.sliderValue
        text: root.formatSliderValue ? root.formatSliderValue(propertyEditor.sliderValue, modelData.step) : String(propertyEditor.sliderValue)
        onMoved: value => {
          if (value === propertyEditor.sliderValue) {
            return;
          }
          propertyEditor.sliderValue = value;
          if (root.setPropertyValue) {
            root.setPropertyValue(modelData.key, value);
          }
        }
      }

      NComboBox {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? implicitHeight : 0
        visible: modelData.type === "combo"
        label: modelData.label
        model: root.comboChoicesFor ? root.comboChoicesFor(modelData) : []
        currentKey: propertyEditor.comboValue
        onSelected: key => {
          const normalizedKey = String(key);
          if (normalizedKey === propertyEditor.comboValue) {
            return;
          }
          propertyEditor.comboValue = normalizedKey;
          if (root.setPropertyValue) {
            root.setPropertyValue(modelData.key, normalizedKey);
          }
        }
      }

      NTextInput {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? implicitHeight : 0
        visible: modelData.type === "textinput"
        label: modelData.label
        text: propertyEditor.textValue
        onEditingFinished: {
          const nextText = String(text);
          if (nextText === propertyEditor.textValue) {
            return;
          }
          propertyEditor.textValue = nextText;
          if (root.setPropertyValue) {
            root.setPropertyValue(modelData.key, nextText);
          }
        }
        onAccepted: {
          const nextText = String(text);
          if (nextText === propertyEditor.textValue) {
            return;
          }
          propertyEditor.textValue = nextText;
          if (root.setPropertyValue) {
            root.setPropertyValue(modelData.key, nextText);
          }
        }
      }

      NText {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? implicitHeight : 0
        visible: modelData.type === "text"
        text: modelData.label
        color: Color.mPrimary
        font.pointSize: Style.fontSizeM
        font.weight: Font.Bold
        wrapMode: Text.Wrap
        topPadding: Style.marginXS
        bottomPadding: Style.marginXS
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? implicitHeight : 0
        visible: modelData.type === "color"
        spacing: Style.marginXS

        NText {
          Layout.fillWidth: true
          text: modelData.label
          color: Color.mOnSurface
          font.pointSize: Style.fontSizeM
          wrapMode: Text.Wrap
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.baseWidgetSize
          radius: Style.radiusM
          color: propertyEditor.colorValue
          border.width: Style.borderS
          border.color: Qt.alpha(Color.mOutline, 0.35)
        }

        NColorPicker {
          screen: pluginApi?.panelOpenScreen
          Layout.fillWidth: true
          Layout.preferredHeight: Style.baseWidgetSize
          selectedColor: propertyEditor.colorValue
          onColorSelected: color => {
            propertyEditor.colorValue = color;
            if (root.setPropertyValue) {
              root.setPropertyValue(modelData.key, color);
            }
          }
        }

        NText {
          Layout.fillWidth: true
          text: root.serializePropertyValue ? root.serializePropertyValue(propertyEditor.colorValue, "color") : ""
          color: Color.mOnSurfaceVariant
          font.pointSize: Style.fontSizeS
        }
      }
    }
  }
}
