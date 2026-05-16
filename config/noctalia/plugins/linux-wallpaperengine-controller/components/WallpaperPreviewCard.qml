import QtQuick
import QtQuick.Layouts
import QtMultimedia

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var selectedWallpaperData: null
  property var propertyLoadFailedByPath: ({})
  property var resolutionBadgeIcon: null
  property var resolutionBadgeLabel: null
  property var typeLabel: null
  property var isVideoMotion: null
  property var formatBytes: null
  property var workshopUrlForWallpaper: null

  signal workshopLinkRequested(string url)

  Layout.fillWidth: true
  spacing: Style.marginS

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 180 * Style.uiScaleRatio
    radius: Style.radiusM
    color: Color.mSurfaceVariant
    clip: true

    Image {
      anchors.fill: parent
      visible: root.selectedWallpaperData && (!root.selectedWallpaperData.motionPreview || root.selectedWallpaperData.motionPreview.length === 0) && root.selectedWallpaperData.thumb && root.selectedWallpaperData.thumb.length > 0
      source: visible ? ("file://" + root.selectedWallpaperData.thumb) : ""
      fillMode: Image.PreserveAspectCrop
      cache: false
    }

    AnimatedImage {
      anchors.fill: parent
      visible: root.selectedWallpaperData && root.selectedWallpaperData.motionPreview && root.selectedWallpaperData.motionPreview.length > 0 && !(root.isVideoMotion && root.isVideoMotion(root.selectedWallpaperData.motionPreview))
      source: visible ? ("file://" + root.selectedWallpaperData.motionPreview) : ""
      fillMode: Image.PreserveAspectCrop
      cache: false
      playing: visible
    }

    Video {
      anchors.fill: parent
      visible: root.selectedWallpaperData && root.selectedWallpaperData.motionPreview && root.selectedWallpaperData.motionPreview.length > 0 && root.isVideoMotion && root.isVideoMotion(root.selectedWallpaperData.motionPreview)
      autoPlay: true
      loops: MediaPlayer.Infinite
      muted: true
      fillMode: VideoOutput.PreserveAspectCrop
      source: visible ? ("file://" + root.selectedWallpaperData.motionPreview) : ""
    }
  }

  NText {
    Layout.fillWidth: true
    text: root.selectedWallpaperData ? root.selectedWallpaperData.name : ""
    color: Color.mOnSurface
    font.weight: Font.Bold
    elide: Text.ElideRight
  }

  Flow {
    Layout.fillWidth: true
    spacing: Style.marginXS

    Rectangle {
      visible: root.selectedWallpaperData && root.resolutionBadgeLabel && root.resolutionBadgeLabel(root.selectedWallpaperData.resolution).length > 0
      color: Qt.alpha(Color.mSurfaceVariant, 0.24)
      radius: Style.radiusXS
      implicitWidth: sidebarResolutionBadgeRow.implicitWidth + Style.marginS * 2
      implicitHeight: sidebarResolutionBadgeRow.implicitHeight + Style.marginXS * 2

      RowLayout {
        id: sidebarResolutionBadgeRow
        anchors.centerIn: parent
        spacing: Style.marginXS

        NIcon {
          icon: root.selectedWallpaperData && root.resolutionBadgeIcon ? root.resolutionBadgeIcon(root.selectedWallpaperData.resolution) : ""
          pointSize: Style.fontSizeM
          color: Color.mOnSurfaceVariant
        }

        NText {
          text: root.selectedWallpaperData && root.resolutionBadgeLabel ? root.resolutionBadgeLabel(root.selectedWallpaperData.resolution) : ""
          color: Color.mOnSurfaceVariant
          font.pointSize: Style.fontSizeXS
          font.weight: Font.Medium
        }
      }
    }

    Rectangle {
      color: Qt.alpha(Color.mSecondary, 0.18)
      radius: Style.radiusXS
      implicitWidth: sidebarTypeBadgeText.implicitWidth + Style.marginS * 2
      implicitHeight: sidebarTypeBadgeText.implicitHeight + Style.marginXS * 2

      NText {
        id: sidebarTypeBadgeText
        anchors.centerIn: parent
        text: root.selectedWallpaperData && root.typeLabel ? root.typeLabel(root.selectedWallpaperData.type) : ""
        color: Color.mSecondary
        font.pointSize: Style.fontSizeXS
        font.weight: Font.Medium
      }
    }

    Rectangle {
      color: root.selectedWallpaperData && root.selectedWallpaperData.dynamic
        ? Qt.alpha(Color.mTertiary, 0.18)
        : Qt.alpha(Color.mOutline, 0.18)
      radius: Style.radiusXS
      implicitWidth: sidebarMotionBadgeText.implicitWidth + Style.marginS * 2
      implicitHeight: sidebarMotionBadgeText.implicitHeight + Style.marginXS * 2

      NText {
        id: sidebarMotionBadgeText
        anchors.centerIn: parent
        text: root.selectedWallpaperData
          ? (root.selectedWallpaperData.dynamic
            ? pluginApi?.tr("panel.dynamicBadge")
            : pluginApi?.tr("panel.staticBadge"))
          : ""
        color: root.selectedWallpaperData && root.selectedWallpaperData.dynamic ? Color.mTertiary : Color.mOnSurfaceVariant
        font.pointSize: Style.fontSizeXS
        font.weight: Font.Medium
      }
    }

    Rectangle {
      visible: root.propertyLoadFailedByPath[String(root.selectedWallpaperData?.path || "")] === true
      color: Qt.alpha(Color.mError, 0.16)
      radius: Style.radiusXS
      implicitWidth: sidebarPropertyFailedBadgeRow.implicitWidth + Style.marginS * 2
      implicitHeight: sidebarPropertyFailedBadgeRow.implicitHeight + Style.marginXS * 2

      RowLayout {
        id: sidebarPropertyFailedBadgeRow
        anchors.centerIn: parent
        spacing: Style.marginXS

        NIcon {
          icon: "alert-triangle"
          pointSize: Style.fontSizeM
          color: Color.mError
        }

        NText {
          text: pluginApi?.tr("panel.propertiesFailedBadge")
          color: Color.mError
          font.pointSize: Style.fontSizeXS
          font.weight: Font.Medium
        }
      }
    }
  }

  GridLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    columns: 2
    columnSpacing: Style.marginM
    rowSpacing: Style.marginS

    NText {
      text: pluginApi?.tr("panel.infoType")
      color: Color.mOnSurfaceVariant
    }

    NText {
      Layout.fillWidth: true
      text: root.selectedWallpaperData && root.typeLabel ? root.typeLabel(root.selectedWallpaperData.type) : ""
      color: Color.mOnSurface
      horizontalAlignment: Text.AlignRight
      wrapMode: Text.Wrap
    }

    NText {
      text: pluginApi?.tr("panel.infoId")
      color: Color.mOnSurfaceVariant
    }

    Rectangle {
      color: "transparent"
      Layout.fillWidth: true
      implicitHeight: idValueText.implicitHeight

      NText {
        id: idValueText
        anchors.left: parent.left
        anchors.right: parent.right
        text: root.selectedWallpaperData ? root.selectedWallpaperData.id : ""
        color: idLinkArea.containsMouse ? Color.mPrimary : Color.mOnSurface
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideMiddle
      }

      MouseArea {
        id: idLinkArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.workshopUrlForWallpaper && root.workshopUrlForWallpaper(root.selectedWallpaperData).length > 0
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          const workshopUrl = root.workshopUrlForWallpaper ? root.workshopUrlForWallpaper(root.selectedWallpaperData) : "";
          if (workshopUrl.length === 0) {
            return;
          }
          root.workshopLinkRequested(workshopUrl);
        }
      }
    }

    NText {
      text: pluginApi?.tr("panel.infoResolution")
      color: Color.mOnSurfaceVariant
    }

    NText {
      Layout.fillWidth: true
      text: root.selectedWallpaperData
        ? (String(root.selectedWallpaperData.resolution || "unknown") === "unknown"
          ? pluginApi?.tr("panel.resolutionUnknown")
          : root.selectedWallpaperData.resolution)
        : ""
      color: Color.mOnSurface
      horizontalAlignment: Text.AlignRight
      wrapMode: Text.Wrap
    }

    NText {
      text: pluginApi?.tr("panel.infoSize")
      color: Color.mOnSurfaceVariant
    }

    NText {
      Layout.fillWidth: true
      text: root.selectedWallpaperData && root.formatBytes ? root.formatBytes(root.selectedWallpaperData.bytes) : ""
      color: Color.mOnSurface
      horizontalAlignment: Text.AlignRight
      wrapMode: Text.Wrap
    }
  }
}
