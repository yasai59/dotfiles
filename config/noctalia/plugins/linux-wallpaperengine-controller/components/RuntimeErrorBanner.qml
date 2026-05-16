import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var pluginApi: null
  property var mainInstance: null
  property bool errorDetailsExpanded: false

  signal errorDetailsExpandedRequested(bool value)
  signal dismissRequested()

  visible: !!(mainInstance?.lastError && mainInstance.lastError.length > 0)
  Layout.fillWidth: true
  implicitHeight: errorBannerContent.implicitHeight + Style.marginS * 2
  Layout.preferredHeight: implicitHeight
  radius: Style.radiusM
  color: Color.mSurface
  border.width: Style.borderS
  border.color: Qt.alpha(Color.mOutline, 0.2)

  ColumnLayout {
    id: errorBannerContent
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: Style.marginS
    anchors.rightMargin: Style.marginS
    anchors.topMargin: Style.marginS
    spacing: Style.marginXS

    RowLayout {
      Layout.fillWidth: true

      NIcon {
        icon: "alert-triangle"
        pointSize: Style.fontSizeL
        color: Color.mError
      }

      NText {
        text: pluginApi?.tr("panel.errorBannerTitle")
        color: Color.mOnSurface
        font.weight: Font.Bold
      }

      Item { Layout.fillWidth: true }

      NButton {
        text: root.errorDetailsExpanded
          ? pluginApi?.tr("panel.errorHideDetails")
          : pluginApi?.tr("panel.errorShowDetails")
        icon: root.errorDetailsExpanded ? "chevron-up" : "chevron-down"
        onClicked: root.errorDetailsExpandedRequested(!root.errorDetailsExpanded)
      }

      NIconButton {
        icon: "x"
        tooltipText: pluginApi?.tr("panel.errorDismiss")
        onClicked: root.dismissRequested()
      }
    }

    NText {
      Layout.fillWidth: true
      text: mainInstance?.lastError ?? ""
      color: Color.mOnSurface
      wrapMode: Text.WordWrap
      maximumLineCount: 2
      elide: Text.ElideRight
    }

    Rectangle {
      visible: root.errorDetailsExpanded && (mainInstance?.lastErrorDetails ?? "").length > 0
      Layout.fillWidth: true
      Layout.preferredHeight: 136 * Style.uiScaleRatio
      radius: Style.radiusS
      color: Qt.alpha(Color.mSurfaceVariant, 0.35)
      border.width: Style.borderS
      border.color: Qt.alpha(Color.mOutline, 0.25)

      NScrollView {
        anchors.fill: parent
        anchors.margins: Style.marginXS
        showScrollbarWhenScrollable: true
        gradientColor: "transparent"

        NText {
          width: parent.width
          text: mainInstance?.lastErrorDetails ?? ""
          color: Color.mOnSurface
          wrapMode: Text.WrapAnywhere
        }
      }
    }
  }
}
