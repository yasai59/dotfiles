import QtQuick
import QtQuick.Layouts
import QtMultimedia

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var mainInstance: null
  property var wallpapers: []
  property string pendingPath: ""
  property string selectedPath: ""
  property bool scanningWallpapers: false
  property int wallpaperItemsCount: 0
  property int visibleWallpaperCount: 0
  property var propertyLoadFailedByPath: ({})
  property int currentPage: 0
  property int pageCount: 1
  property int currentPageDisplay: 0
  property int currentPageStartIndex: 0
  property int currentPageEndIndex: 0
  property bool paginationVisible: false
  property var resolutionBadgeIcon: null
  property var resolutionBadgeLabel: null
  property var typeLabel: null
  property var isVideoMotion: null

  signal wallpaperActivated(string path)
  signal previousPageRequested()
  signal nextPageRequested()

  Layout.fillWidth: true
  Layout.fillHeight: true
  spacing: Style.marginS

  NGridView {
    id: gridView
    Layout.fillWidth: true
    Layout.fillHeight: true
    property real minCardWidth: 244 * Style.uiScaleRatio
    property real cardGap: Style.marginS
    property int columnCount: Math.max(1, Math.floor((availableWidth + cardGap) / (minCardWidth + cardGap)))
    cellWidth: (availableWidth - ((columnCount - 1) * cardGap)) / columnCount
    cellHeight: 208 * Style.uiScaleRatio
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    model: root.wallpapers

    delegate: Rectangle {
      id: tileCard
      required property var modelData
      width: gridView.cellWidth
      height: gridView.cellHeight
      radius: Style.radiusL
      color: Qt.alpha(Color.mSurfaceVariant, 0.42)
      border.width: root.pendingPath === modelData.path ? 2 : (root.selectedPath === modelData.path ? 1 : 0)
      border.color: root.pendingPath === modelData.path ? Color.mPrimary : Qt.alpha(Color.mOutline, 0.35)
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginS
        spacing: Style.marginXS

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 136 * Style.uiScaleRatio
          radius: Style.radiusM
          color: Color.mSurfaceVariant
          clip: true

          Image {
            anchors.fill: parent
            visible: modelData.thumb && modelData.thumb.length > 0
            source: visible ? ("file://" + modelData.thumb) : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
          }

          Loader {
            anchors.fill: parent
            active: modelData.motionPreview && modelData.motionPreview.length > 0
            sourceComponent: root.isVideoMotion && root.isVideoMotion(modelData.motionPreview) ? motionVideoComponent : motionAnimatedComponent
          }

          Component {
            id: motionAnimatedComponent

            AnimatedImage {
              anchors.fill: parent
              source: "file://" + modelData.motionPreview
              fillMode: Image.PreserveAspectCrop
              cache: false
              playing: true
            }
          }

          Component {
            id: motionVideoComponent

            Video {
              anchors.fill: parent
              autoPlay: true
              loops: MediaPlayer.Infinite
              muted: true
              fillMode: VideoOutput.PreserveAspectCrop
              source: "file://" + modelData.motionPreview
            }
          }

          NIcon {
            anchors.centerIn: parent
            visible: (!modelData.thumb || modelData.thumb.length === 0) && (!modelData.motionPreview || modelData.motionPreview.length === 0)
            icon: "photo"
            pointSize: Style.fontSizeXL
            color: Color.mOnSurfaceVariant
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          NText {
            Layout.fillWidth: true
            text: modelData.name
            color: Color.mOnSurface
            font.weight: Font.Medium
            elide: Text.ElideRight
          }

          NIcon {
            visible: root.selectedPath === modelData.path
            icon: "check"
            pointSize: Style.fontSizeL
            color: Color.mPrimary
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: Style.marginXS

          Rectangle {
            color: Qt.alpha(Color.mSecondary, 0.18)
            radius: Style.radiusXS
            implicitWidth: typeBadgeText.implicitWidth + Style.marginS * 2
            implicitHeight: typeBadgeText.implicitHeight + Style.marginXS * 2

            NText {
              id: typeBadgeText
              anchors.centerIn: parent
              text: root.typeLabel ? root.typeLabel(modelData.type) : ""
              color: Color.mSecondary
              font.pointSize: Style.fontSizeXS
              font.weight: Font.Medium
            }
          }

          Rectangle {
            color: modelData.dynamic ? Qt.alpha(Color.mTertiary, 0.18) : Qt.alpha(Color.mOutline, 0.18)
            radius: Style.radiusXS
            implicitWidth: motionBadgeText.implicitWidth + Style.marginS * 2
            implicitHeight: motionBadgeText.implicitHeight + Style.marginXS * 2

            NText {
              id: motionBadgeText
              anchors.centerIn: parent
              text: modelData.dynamic
                ? pluginApi?.tr("panel.dynamicBadge")
                : pluginApi?.tr("panel.staticBadge")
              color: modelData.dynamic ? Color.mTertiary : Color.mOnSurfaceVariant
              font.pointSize: Style.fontSizeXS
              font.weight: Font.Medium
            }
          }

          Rectangle {
            visible: root.resolutionBadgeIcon && root.resolutionBadgeIcon(modelData.resolution).length > 0
            color: Qt.alpha(Color.mSurfaceVariant, 0.24)
            radius: Style.radiusXS
            implicitWidth: resolutionBadgeRow.implicitWidth + Style.marginS * 2
            implicitHeight: resolutionBadgeRow.implicitHeight + Style.marginXS * 2

            RowLayout {
              id: resolutionBadgeRow
              anchors.centerIn: parent
              spacing: Style.marginXS

              NIcon {
                icon: root.resolutionBadgeIcon ? root.resolutionBadgeIcon(modelData.resolution) : ""
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
              }

              NText {
                text: root.resolutionBadgeLabel ? root.resolutionBadgeLabel(modelData.resolution) : ""
                color: Color.mOnSurfaceVariant
                font.pointSize: Style.fontSizeXS
                font.weight: Font.Medium
              }
            }
          }

          Rectangle {
            visible: root.propertyLoadFailedByPath[String(modelData.path || "")] === true
            color: Qt.alpha(Color.mError, 0.16)
            radius: Style.radiusXS
            implicitWidth: propertyFailedBadgeRow.implicitWidth + Style.marginS * 2
            implicitHeight: propertyFailedBadgeRow.implicitHeight + Style.marginXS * 2

            RowLayout {
              id: propertyFailedBadgeRow
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
      }

      MouseArea {
        anchors.fill: parent
        enabled: root.mainInstance?.engineAvailable ?? false
        hoverEnabled: true
        onClicked: root.wallpaperActivated(modelData.path)
      }
    }

    Rectangle {
      visible: root.wallpapers.length === 0 && !root.scanningWallpapers
      anchors.centerIn: parent
      color: "transparent"
      width: 300 * Style.uiScaleRatio
      height: 140 * Style.uiScaleRatio

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
          Layout.alignment: Qt.AlignHCenter
          icon: "photo"
          pointSize: Style.fontSizeXL
          color: Color.mOnSurfaceVariant
        }

        NText {
          text: root.wallpaperItemsCount === 0
            ? pluginApi?.tr("panel.emptyAll")
            : pluginApi?.tr("panel.emptyFiltered")
          color: Color.mOnSurfaceVariant
        }
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    visible: root.paginationVisible
    implicitHeight: paginationRow.implicitHeight + Style.marginS * 2
    radius: Style.radiusM
    color: Qt.alpha(Color.mSurfaceVariant, 0.35)
    border.width: Style.borderS
    border.color: Qt.alpha(Color.mOutline, 0.3)

    RowLayout {
      id: paginationRow
      anchors.fill: parent
      anchors.margins: Style.marginS
      spacing: Style.marginS

      NButton {
        text: pluginApi?.tr("panel.prevPage")
        icon: "chevron-left"
        enabled: root.currentPage > 0
        onClicked: root.previousPageRequested()
      }

      NText {
        text: pluginApi?.tr("panel.pageSummary", {
          current: root.currentPageDisplay,
          total: root.pageCount
        })
        color: Color.mOnSurface
        font.weight: Font.Medium
      }

      NText {
        text: pluginApi?.tr("panel.pageRange", {
          start: root.currentPageStartIndex,
          end: root.currentPageEndIndex,
          total: root.visibleWallpaperCount
        })
        color: Color.mOnSurfaceVariant
      }

      Item { Layout.fillWidth: true }

      NButton {
        text: pluginApi?.tr("panel.nextPage")
        icon: "chevron-right"
        enabled: root.currentPage < root.pageCount - 1
        onClicked: root.nextPageRequested()
      }
    }
  }
}
