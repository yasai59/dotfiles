import QtQuick

import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property bool resolutionDropdownOpen: false
  property bool filterDropdownOpen: false
  property bool sortDropdownOpen: false
  property string selectedResolution: "all"
  property string selectedType: "all"
  property string sortMode: "name"
  property bool sortAscending: true
  property real resolutionDropdownX: 0
  property real resolutionDropdownY: 0
  property real resolutionDropdownWidth: 220 * Style.uiScaleRatio
  property real filterDropdownX: 0
  property real filterDropdownY: 0
  property real filterDropdownWidth: 220 * Style.uiScaleRatio
  property real sortDropdownX: 0
  property real sortDropdownY: 0
  property real sortDropdownWidth: 220 * Style.uiScaleRatio

  signal closeRequested()
  signal resolutionActionTriggered(string action)
  signal filterActionTriggered(string action)
  signal sortActionTriggered(string action)

  anchors.fill: parent

  MouseArea {
    anchors.fill: parent
    visible: root.filterDropdownOpen || root.resolutionDropdownOpen || root.sortDropdownOpen
    z: 900
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: root.closeRequested()
  }

  Rectangle {
    visible: root.resolutionDropdownOpen
    x: root.resolutionDropdownX
    y: root.resolutionDropdownY
    width: root.resolutionDropdownWidth
    height: Math.min(210 * Style.uiScaleRatio, resolutionList.contentHeight + 2 * Style.marginS)
    radius: Style.radiusL
    color: Qt.alpha(Color.mSurface, 0.96)
    border.width: Style.borderS
    border.color: Qt.alpha(Color.mOutline, 0.45)
    z: 901

    NListView {
      id: resolutionList
      anchors.fill: parent
      anchors.margins: Style.marginS
      clip: true
      spacing: Style.marginXS
      model: [
        { "label": pluginApi?.tr("panel.filterResAll"), "action": "res:all", "selected": root.selectedResolution === "all" },
        { "label": pluginApi?.tr("panel.filterRes4k"), "action": "res:4k", "selected": root.selectedResolution === "4k" },
        { "label": pluginApi?.tr("panel.filterRes8k"), "action": "res:8k", "selected": root.selectedResolution === "8k" },
        { "label": pluginApi?.tr("panel.filterResUnknown"), "action": "res:unknown", "selected": root.selectedResolution === "unknown" }
      ]

      delegate: Rectangle {
        required property var modelData
        width: resolutionList.availableWidth
        height: 34 * Style.uiScaleRatio
        radius: Style.radiusM
        color: modelData.selected ? Qt.alpha(Color.mPrimary, 0.22) : "transparent"
        border.width: modelData.selected ? 1 : 0
        border.color: Qt.alpha(Color.mPrimary, 0.45)

        NText {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS
          text: modelData.label
          color: modelData.selected ? Color.mPrimary : Color.mOnSurface
          font.weight: modelData.selected ? Font.Medium : Font.Normal
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.resolutionActionTriggered(modelData.action)
        }
      }
    }
  }

  Rectangle {
    visible: root.filterDropdownOpen
    x: root.filterDropdownX
    y: root.filterDropdownY
    width: root.filterDropdownWidth
    height: Math.min(244 * Style.uiScaleRatio, filterList.contentHeight + 2 * Style.marginS)
    radius: Style.radiusL
    color: Qt.alpha(Color.mSurface, 0.96)
    border.width: Style.borderS
    border.color: Qt.alpha(Color.mOutline, 0.45)
    z: 901

    NListView {
      id: filterList
      anchors.fill: parent
      anchors.margins: Style.marginS
      clip: true
      spacing: Style.marginXS
      model: [
        { "label": pluginApi?.tr("panel.filterTypeAll"), "action": "type:all", "selected": root.selectedType === "all" },
        { "label": pluginApi?.tr("panel.filterTypeScene"), "action": "type:scene", "selected": root.selectedType === "scene" },
        { "label": pluginApi?.tr("panel.filterTypeVideo"), "action": "type:video", "selected": root.selectedType === "video" },
        { "label": pluginApi?.tr("panel.filterTypeWeb"), "action": "type:web", "selected": root.selectedType === "web" },
        { "label": pluginApi?.tr("panel.filterTypeApplication"), "action": "type:application", "selected": root.selectedType === "application" }
      ]

      delegate: Rectangle {
        required property var modelData
        width: filterList.availableWidth
        height: 34 * Style.uiScaleRatio
        radius: Style.radiusM
        color: modelData.selected ? Qt.alpha(Color.mPrimary, 0.22) : "transparent"
        border.width: modelData.selected ? 1 : 0
        border.color: Qt.alpha(Color.mPrimary, 0.45)

        NText {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS
          text: modelData.label
          color: modelData.selected ? Color.mPrimary : Color.mOnSurface
          font.weight: modelData.selected ? Font.Medium : Font.Normal
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.filterActionTriggered(modelData.action)
        }
      }
    }
  }

  Rectangle {
    visible: root.sortDropdownOpen
    x: root.sortDropdownX
    y: root.sortDropdownY
    width: root.sortDropdownWidth
    height: Math.min(244 * Style.uiScaleRatio, sortList.contentHeight + 2 * Style.marginS)
    radius: Style.radiusL
    color: Qt.alpha(Color.mSurface, 0.96)
    border.width: Style.borderS
    border.color: Qt.alpha(Color.mOutline, 0.45)
    z: 901

    NListView {
      id: sortList
      anchors.fill: parent
      anchors.margins: Style.marginS
      clip: true
      spacing: Style.marginXS
      model: [
        { "label": pluginApi?.tr("panel.sortName"), "action": "sort:name", "selected": root.sortMode === "name" },
        { "label": pluginApi?.tr("panel.sortDateAdded"), "action": "sort:date", "selected": root.sortMode === "date" },
        { "label": pluginApi?.tr("panel.sortSize"), "action": "sort:size", "selected": root.sortMode === "size" },
        { "label": pluginApi?.tr("panel.sortRecent"), "action": "sort:recent", "selected": root.sortMode === "recent" },
        {
          "label": pluginApi?.tr("panel.sortAscendingToggleWithDirection", {
            direction: root.sortAscending ? "↑" : "↓"
          }),
          "action": "sort:toggleAscending",
          "selected": false
        }
      ]

      delegate: Rectangle {
        required property var modelData
        width: sortList.availableWidth
        height: 34 * Style.uiScaleRatio
        radius: Style.radiusM
        color: modelData.selected ? Qt.alpha(Color.mPrimary, 0.22) : "transparent"
        border.width: modelData.selected ? 1 : 0
        border.color: Qt.alpha(Color.mPrimary, 0.45)

        NText {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.leftMargin: Style.marginS
          text: modelData.label
          color: modelData.selected ? Color.mPrimary : Color.mOnSurface
          font.weight: modelData.selected ? Font.Medium : Font.Normal
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.sortActionTriggered(modelData.action)
        }
      }
    }
  }
}
