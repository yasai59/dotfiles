import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var pluginApi: null
  property var mainInstance: null
  property Item positionTarget: null
  property string engineStatusBadgeText: ""
  property color engineStatusBadgeFg: Color.mOnSurfaceVariant
  property color engineStatusBadgeBg: Qt.alpha(engineStatusBadgeFg, 0.16)
  property bool scanningCompatibility: false
  property bool pendingCompatibilityScan: false
  property string searchText: ""
  property string selectedType: "all"
  property string selectedResolution: "all"
  property string sortMode: "name"
  property bool sortAscending: true
  property var typeLabel: null
  property var resolutionFilterLabel: null
  property var sortLabel: null
  property real resolutionButtonWidth: 220 * Style.uiScaleRatio
  property real filterButtonWidth: 220 * Style.uiScaleRatio
  property real sortButtonWidth: 220 * Style.uiScaleRatio

  signal compatibilityQuickCheckRequested()
  signal reloadRequested()
  signal toggleRunRequested()
  signal settingsRequested()
  signal closeRequested()
  signal pendingCompatibilityScanRequested(bool value)
  signal searchTextUpdateRequested(string text)
  signal clearSearchRequested()
  signal resolutionDropdownToggleRequested(real x, real y, real width)
  signal filterDropdownToggleRequested(real x, real y, real width)
  signal sortDropdownToggleRequested(real x, real y, real width)

  function mapButtonGeometry(item) {
    if (!item || !root.positionTarget) {
      return { x: 0, y: 0, width: 0 };
    }

    const pos = item.mapToItem(root.positionTarget, 0, item.height + Style.marginXS);
    return {
      x: pos.x,
      y: pos.y,
      width: item.width
    };
  }

  Layout.fillWidth: true
  Layout.preferredHeight: headerColumn.implicitHeight + Style.marginS * 2
  Layout.minimumHeight: Layout.preferredHeight
  radius: Style.radiusL
  color: Qt.alpha(Color.mSurfaceVariant, 0.35)
  border.width: Style.borderS
  border.color: Qt.alpha(Color.mOutline, 0.35)

  ColumnLayout {
    id: headerColumn
    anchors.fill: parent
    anchors.margins: Style.marginS
    spacing: Style.marginS

    RowLayout {
      Layout.fillWidth: true

      NIcon {
        icon: "wallpaper-selector"
        pointSize: Style.fontSizeL
        color: Color.mOnSurface
      }

      NText {
        text: pluginApi?.tr("panel.title")
        font.pointSize: Style.fontSizeL
        font.weight: Font.Bold
        color: Color.mOnSurface
      }

      Rectangle {
        radius: Style.radiusXS
        color: root.engineStatusBadgeBg
        implicitWidth: statusBadgeText.implicitWidth + Style.marginS * 2
        implicitHeight: statusBadgeText.implicitHeight + Style.marginXS * 2

        NText {
          id: statusBadgeText
          anchors.centerIn: parent
          text: root.engineStatusBadgeText
          color: root.engineStatusBadgeFg
          font.pointSize: Style.fontSizeXS
          font.weight: Font.Medium
        }
      }

      Item { Layout.fillWidth: true }

      NIconButton {
        enabled: (mainInstance?.engineAvailable ?? false) && !root.scanningCompatibility
        icon: root.scanningCompatibility ? "loader" : "shield-search"
        colorFg: Color.mOnSurface
        tooltipText: root.scanningCompatibility
          ? pluginApi?.tr("panel.compatibilityQuickCheckRunning")
          : pluginApi?.tr("panel.compatibilityQuickCheck")
        onClicked: {
          if (!root.scanningCompatibility) {
            root.pendingCompatibilityScanRequested(true)
          }
        }
      }

      NIconButton {
        enabled: !(mainInstance?.scanningWallpapers ?? false)
        icon: "refresh"
        colorFg: Color.mOnSurface
        tooltipText: pluginApi?.tr("panel.refreshWallpapers")
        onClicked: root.reloadRequested()
      }

      NIconButton {
        enabled: mainInstance?.engineAvailable ?? false
        icon: mainInstance?.engineRunning ? "player-stop" : "player-play"
        colorFg: Color.mOnSurface
        tooltipText: mainInstance?.engineRunning ? pluginApi?.tr("panel.stop") : pluginApi?.tr("panel.start")
        onClicked: root.toggleRunRequested()
      }

      NIconButton {
        icon: "settings"
        colorFg: Color.mOnSurface
        tooltipText: pluginApi?.tr("menu.settings")
        onClicked: root.settingsRequested()
      }

      NIconButton {
        icon: "x"
        colorFg: Color.mOnSurface
        tooltipText: pluginApi?.tr("panel.closePanel")
        onClicked: root.closeRequested()
      }
    }

    NBox {
      visible: root.pendingCompatibilityScan
      Layout.fillWidth: true
      Layout.preferredHeight: compatibilityConfirmRow.implicitHeight + Style.marginM * 2

      RowLayout {
        id: compatibilityConfirmRow
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        NText {
          Layout.fillWidth: true
          text: pluginApi?.tr("panel.compatibilityQuickCheckConfirm")
          pointSize: Style.fontSizeS
          color: Color.mOnSurface
          wrapMode: Text.WordWrap
        }

        NButton {
          text: pluginApi?.tr("panel.confirm")
          enabled: !root.scanningCompatibility
          onClicked: root.compatibilityQuickCheckRequested()
        }

        NButton {
          text: pluginApi?.tr("panel.cancel")
          enabled: !root.scanningCompatibility
          onClicked: root.pendingCompatibilityScanRequested(false)
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 48 * Style.uiScaleRatio

      NTextInput {
        Layout.fillWidth: true
        placeholderText: pluginApi?.tr("panel.searchPlaceholder")
        text: root.searchText
        onTextChanged: root.searchTextUpdateRequested(text)
      }

      NIconButton {
        Layout.alignment: Qt.AlignVCenter
        visible: root.searchText.length > 0
        icon: "x"
        tooltipText: pluginApi?.tr("panel.searchClear")
        onClicked: root.clearSearchRequested()
      }

      Rectangle {
        id: resolutionButton
        Layout.preferredWidth: root.resolutionButtonWidth
        Layout.maximumWidth: root.resolutionButtonWidth
        Layout.preferredHeight: 42 * Style.uiScaleRatio
        radius: Style.radiusL
        color: Qt.alpha(Color.mSurfaceVariant, 0.42)
        border.width: Style.borderS
        border.color: Qt.alpha(Color.mOutline, 0.45)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginXXS

          NIcon {
            icon: "badge-hd"
            pointSize: Style.fontSizeM
            color: Color.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: root.resolutionFilterLabel ? root.resolutionFilterLabel(root.selectedResolution) : ""
            color: Color.mOnSurface
            elide: Text.ElideRight
          }

          NIcon {
            icon: "chevron-down"
            pointSize: Style.fontSizeM
            color: Color.mOnSurfaceVariant
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: {
            const geometry = root.mapButtonGeometry(resolutionButton);
            root.resolutionDropdownToggleRequested(geometry.x, geometry.y, geometry.width);
          }
        }
      }

      Rectangle {
        id: filterButton
        Layout.preferredWidth: root.filterButtonWidth
        Layout.maximumWidth: root.filterButtonWidth
        Layout.preferredHeight: 42 * Style.uiScaleRatio
        radius: Style.radiusL
        color: Qt.alpha(Color.mSurfaceVariant, 0.42)
        border.width: Style.borderS
        border.color: Qt.alpha(Color.mOutline, 0.45)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginXXS

          NIcon {
            icon: "adjustments-horizontal"
            pointSize: Style.fontSizeM
            color: Color.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("panel.filterButtonSummary", { type: root.typeLabel ? root.typeLabel(root.selectedType) : "" })
            color: Color.mOnSurface
            elide: Text.ElideRight
          }

          NIcon {
            icon: "chevron-down"
            pointSize: Style.fontSizeM
            color: Color.mOnSurfaceVariant
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: {
            const geometry = root.mapButtonGeometry(filterButton);
            root.filterDropdownToggleRequested(geometry.x, geometry.y, geometry.width);
          }
        }
      }

      Rectangle {
        id: sortButton
        Layout.preferredWidth: root.sortButtonWidth
        Layout.maximumWidth: root.sortButtonWidth
        Layout.preferredHeight: 42 * Style.uiScaleRatio
        radius: Style.radiusL
        color: Qt.alpha(Color.mSurfaceVariant, 0.42)
        border.width: Style.borderS
        border.color: Qt.alpha(Color.mOutline, 0.45)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginXXS

          NIcon {
            icon: "arrows-sort"
            pointSize: Style.fontSizeM
            color: Color.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("panel.sortButtonSummary", {
              direction: root.sortAscending ? "↑" : "↓",
              sort: root.sortLabel ? root.sortLabel(root.sortMode) : ""
            })
            color: Color.mOnSurface
            elide: Text.ElideRight
          }

          NIcon {
            icon: "chevron-down"
            pointSize: Style.fontSizeM
            color: Color.mOnSurfaceVariant
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: {
            const geometry = root.mapButtonGeometry(sortButton);
            root.sortDropdownToggleRequested(geometry.x, geometry.y, geometry.width);
          }
        }
      }
    }
  }
}
