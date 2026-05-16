import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

import qs.Commons
import qs.Widgets

import "."

ColumnLayout {
  id: root

  property var pluginApi: null
  property var mainInstance: null
  property var selectedWallpaperData: null
  property var propertyLoadFailedByPath: ({})
  property bool singleScreenMode: true
  property bool applyAllDisplays: true
  property bool applyTargetExpanded: false
  property var screenModel: []
  property string selectedScreenName: ""
  property string selectedScaling: "fill"
  property string selectedClamp: "clamp"
  property int selectedVolume: 100
  property bool selectedMuted: true
  property bool selectedAudioReactiveEffects: true
  property bool selectedDisableMouse: false
  property bool selectedDisableParallax: false
  property bool applyWallpaperColorsOnApply: false
  property bool applyingWallpaperColors: false
  property bool extraPropertiesEditorEnabled: true
  property bool loadingWallpaperProperties: false
  property string wallpaperPropertyError: ""
  property var wallpaperPropertyDefinitions: []
  property var resolutionBadgeIcon: null
  property var resolutionBadgeLabel: null
  property var typeLabel: null
  property var isVideoMotion: null
  property var formatBytes: null
  property var workshopUrlForWallpaper: null
  property var propertyValueFor: null
  property var numberOr: null
  property var formatSliderValue: null
  property var comboChoicesFor: null
  property var ensureColorValue: null
  property var serializePropertyValue: null
  property var setPropertyValue: null

  signal applyRequested()
  signal applyAllDisplaysRequested(bool value)
  signal applyTargetExpandedRequested(bool value)
  signal selectedScreenNameRequested(string value)
  signal selectedScalingRequested(string value)
  signal selectedClampRequested(string value)
  signal selectedVolumeRequested(int value)
  signal selectedMutedRequested(bool value)
  signal selectedAudioReactiveEffectsRequested(bool value)
  signal selectedDisableMouseRequested(bool value)
  signal selectedDisableParallaxRequested(bool value)
  signal workshopLinkRequested(string url)
  signal applyWallpaperColorsOnApplyRequested(bool value)

  Layout.preferredWidth: 340 * Style.uiScaleRatio
  Layout.maximumWidth: 340 * Style.uiScaleRatio
  Layout.fillWidth: false
  Layout.fillHeight: true
  visible: root.selectedWallpaperData !== null
  spacing: 0

  Rectangle {
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Style.radiusL
    color: Qt.alpha(Color.mSurfaceVariant, 0.35)
    border.width: Style.borderS
    border.color: Qt.alpha(Color.mOutline, 0.35)
    clip: true

    NScrollView {
      id: sidebarScrollView
      anchors.fill: parent
      anchors.margins: Style.marginM
      showScrollbarWhenScrollable: true
      gradientColor: "transparent"

      ColumnLayout {
        width: sidebarScrollView.availableWidth
        spacing: Style.marginS

        WallpaperPreviewCard {
          pluginApi: root.pluginApi
          selectedWallpaperData: root.selectedWallpaperData
          propertyLoadFailedByPath: root.propertyLoadFailedByPath
          resolutionBadgeIcon: root.resolutionBadgeIcon
          resolutionBadgeLabel: root.resolutionBadgeLabel
          typeLabel: root.typeLabel
          isVideoMotion: root.isVideoMotion
          formatBytes: root.formatBytes
          workshopUrlForWallpaper: root.workshopUrlForWallpaper
          onWorkshopLinkRequested: workshopUrl => root.workshopLinkRequested(workshopUrl)
        }

        WallpaperApplyControls {
          pluginApi: root.pluginApi
          mainInstance: root.mainInstance
          selectedWallpaperData: root.selectedWallpaperData
          singleScreenMode: root.singleScreenMode
          applyAllDisplays: root.applyAllDisplays
          applyTargetExpanded: root.applyTargetExpanded
          screenModel: root.screenModel
          selectedScreenName: root.selectedScreenName
          selectedScaling: root.selectedScaling
          selectedClamp: root.selectedClamp
          selectedVolume: root.selectedVolume
          selectedMuted: root.selectedMuted
          selectedAudioReactiveEffects: root.selectedAudioReactiveEffects
          selectedDisableMouse: root.selectedDisableMouse
          selectedDisableParallax: root.selectedDisableParallax
          applyWallpaperColorsOnApply: root.applyWallpaperColorsOnApply
          applyingWallpaperColors: root.applyingWallpaperColors
          extraPropertiesEditorEnabled: root.extraPropertiesEditorEnabled
          loadingWallpaperProperties: root.loadingWallpaperProperties
          wallpaperPropertyError: root.wallpaperPropertyError
          wallpaperPropertyDefinitions: root.wallpaperPropertyDefinitions
          propertyValueFor: root.propertyValueFor
          numberOr: root.numberOr
          formatSliderValue: root.formatSliderValue
          comboChoicesFor: root.comboChoicesFor
          ensureColorValue: root.ensureColorValue
          serializePropertyValue: root.serializePropertyValue
          setPropertyValue: root.setPropertyValue
          onApplyRequested: root.applyRequested()
          onApplyAllDisplaysRequested: value => root.applyAllDisplaysRequested(value)
          onApplyTargetExpandedRequested: value => root.applyTargetExpandedRequested(value)
          onSelectedScreenNameRequested: value => root.selectedScreenNameRequested(value)
          onSelectedScalingRequested: value => root.selectedScalingRequested(value)
          onSelectedClampRequested: value => root.selectedClampRequested(value)
          onSelectedVolumeRequested: value => root.selectedVolumeRequested(value)
          onSelectedMutedRequested: value => root.selectedMutedRequested(value)
          onSelectedAudioReactiveEffectsRequested: value => root.selectedAudioReactiveEffectsRequested(value)
          onSelectedDisableMouseRequested: value => root.selectedDisableMouseRequested(value)
          onSelectedDisableParallaxRequested: value => root.selectedDisableParallaxRequested(value)
          onApplyWallpaperColorsOnApplyRequested: value => root.applyWallpaperColorsOnApplyRequested(value)
        }
      }
    }
  }
}
