import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "helpers/ColorCacheHelpers.js" as ColorCacheHelpers

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string editWallpapersFolder: cfg.wallpapersFolder ?? defaults.wallpapersFolder ?? ""
  property string editAssetsDir: cfg.assetsDir ?? defaults.assetsDir ?? ""
  property string editIconColor: cfg.iconColor ?? defaults.iconColor ?? "none"
  property bool editEnableExtraPropertiesEditor: cfg.enableExtraPropertiesEditor ?? defaults.enableExtraPropertiesEditor ?? true
  property string editDefaultScaling: cfg.defaultScaling ?? defaults.defaultScaling ?? "fill"
  property string editDefaultClamp: cfg.defaultClamp ?? defaults.defaultClamp ?? "clamp"
  property int editDefaultFps: cfg.defaultFps ?? defaults.defaultFps ?? 30
  property int editDefaultVolume: cfg.defaultVolume ?? defaults.defaultVolume ?? 100
  property bool editDefaultMuted: cfg.defaultMuted ?? defaults.defaultMuted ?? true
  property bool editDefaultAudioReactiveEffects: cfg.defaultAudioReactiveEffects ?? defaults.defaultAudioReactiveEffects ?? true
  property bool editDefaultNoAutomute: cfg.defaultNoAutomute ?? defaults.defaultNoAutomute ?? false
  property bool editDefaultDisableMouse: cfg.defaultDisableMouse ?? defaults.defaultDisableMouse ?? false
  property bool editDefaultDisableParallax: cfg.defaultDisableParallax ?? defaults.defaultDisableParallax ?? false
  property bool editDefaultNoFullscreenPause: cfg.defaultNoFullscreenPause ?? defaults.defaultNoFullscreenPause ?? false
  property bool editDefaultFullscreenPauseOnlyActive: cfg.defaultFullscreenPauseOnlyActive ?? defaults.defaultFullscreenPauseOnlyActive ?? false
  property bool editAutoApplyOnStartup: cfg.autoApplyOnStartup ?? defaults.autoApplyOnStartup ?? true
  property int editWallpaperScanCacheMinutes: cfg.wallpaperScanCacheMinutes ?? defaults.wallpaperScanCacheMinutes ?? 5
  property bool scanning: false
  property bool refreshingCacheSize: false
  property bool clearingCache: false
  property string cacheSizeLabel: pluginApi?.tr("settings.cache.sizeUnknown")
  readonly property string pluginCacheDir: ColorCacheHelpers.pluginCacheDir(
    Settings.cacheDir,
    pluginApi?.manifest?.id || pluginApi?.pluginId || "linux-wallpaperengine-controller"
  )

  spacing: Style.marginL

  function refreshCacheSize() {
    if (root.refreshingCacheSize) {
      return;
    }

    root.refreshingCacheSize = true;
    cacheSizeProcess.running = true;
  }

  function formatBytes(bytes) {
    return ColorCacheHelpers.formatBytes(bytes, pluginApi?.tr("settings.cache.sizeUnknown"));
  }

  function preservedWallpaperColorScreenshots() {
    return ColorCacheHelpers.preservedEntriesForScreens(
      pluginApi?.pluginSettings?.wallpaperColorScreenshots,
      Quickshell.screens
    );
  }

  function clearCacheCommand() {
    const preserved = root.preservedWallpaperColorScreenshots();
    return ColorCacheHelpers.clearCacheCommand(root.pluginApi?.pluginDir || "", root.pluginCacheDir, preserved);
  }

  Component.onCompleted: refreshCacheSize()

  NBox {
    Layout.fillWidth: true
    implicitHeight: interfaceSection.implicitHeight + Style.marginL * 2

    ColumnLayout {
      id: interfaceSection
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.category.interfaceTitle")
        color: Color.mOnSurface
        font.weight: Font.Bold
      }

      NColorChoice {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.description")
        currentKey: root.editIconColor
        onSelected: key => root.editIconColor = key
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.enableExtraPropertiesEditor.label")
        description: pluginApi?.tr("settings.enableExtraPropertiesEditor.description")
        checked: root.editEnableExtraPropertiesEditor
        onToggled: checked => root.editEnableExtraPropertiesEditor = checked
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: resourcesSection.implicitHeight + Style.marginL * 2

    ColumnLayout {
      id: resourcesSection
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.category.compatibilityTitle")
        color: Color.mOnSurface
        font.weight: Font.Bold
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.wallpapersFolder.label")
        description: pluginApi?.tr("settings.wallpapersFolder.description")
        placeholderText: pluginApi?.tr("settings.wallpapersFolder.placeholder")
        text: root.editWallpapersFolder
        onTextChanged: root.editWallpapersFolder = text
      }

      NButton {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.wallpapersFolder.scan")
        icon: root.scanning ? "loader" : "search"
        enabled: !root.scanning
        onClicked: {
          root.scanning = true;
          scanProcess.running = true;
        }
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.assetsDir.label")
        description: pluginApi?.tr("settings.assetsDir.description")
        placeholderText: pluginApi?.tr("settings.assetsDir.placeholder")
        text: root.editAssetsDir
        onTextChanged: root.editAssetsDir = text
      }

      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.wallpaperScanCacheMinutes.label")
        description: pluginApi?.tr("settings.wallpaperScanCacheMinutes.description")
        from: 0
        to: 1440
        stepSize: 1
        value: root.editWallpaperScanCacheMinutes
        suffix: pluginApi?.tr("settings.units.minutes")
        onValueChanged: if (value !== root.editWallpaperScanCacheMinutes) root.editWallpaperScanCacheMinutes = value
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.cache.currentSize", { size: root.cacheSizeLabel })
        color: Color.mOnSurfaceVariant
        wrapMode: Text.Wrap
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NButton {
          Layout.fillWidth: true
          text: pluginApi?.tr("settings.cache.refresh")
          icon: root.refreshingCacheSize ? "loader" : "refresh"
          enabled: !root.refreshingCacheSize && !root.clearingCache
          onClicked: root.refreshCacheSize()
        }

        NButton {
          Layout.fillWidth: true
          text: pluginApi?.tr("settings.cache.clear")
          icon: root.clearingCache ? "loader" : "trash"
          enabled: !root.clearingCache && !root.refreshingCacheSize
          onClicked: {
            root.clearingCache = true;
            clearCacheProcess.command = root.clearCacheCommand();
            clearCacheProcess.running = true;
          }
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: defaultsSection.implicitHeight + Style.marginL * 2

    ColumnLayout {
      id: defaultsSection
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.defaults.title")
        color: Color.mOnSurface
        font.weight: Font.Bold
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.defaults.description")
        color: Color.mOnSurfaceVariant
        wrapMode: Text.Wrap
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.category.performanceTitle")
        color: Color.mOnSurface
        font.weight: Font.Bold
      }

      NSpinBox {
        id: defaultFpsSpinBox
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultFps.label")
        description: pluginApi?.tr("settings.defaultFps.description")
        from: 1
        to: 240
        stepSize: 1
        value: root.editDefaultFps
        suffix: pluginApi?.tr("settings.units.fps")
        onValueChanged: if (value !== root.editDefaultFps) root.editDefaultFps = value
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultNoFullscreenPause.label")
        description: pluginApi?.tr("settings.defaultNoFullscreenPause.description")
        checked: root.editDefaultNoFullscreenPause
        onToggled: checked => root.editDefaultNoFullscreenPause = checked
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultFullscreenPauseOnlyActive.label")
        description: pluginApi?.tr("settings.defaultFullscreenPauseOnlyActive.description")
        checked: root.editDefaultFullscreenPauseOnlyActive
        onToggled: checked => root.editDefaultFullscreenPauseOnlyActive = checked
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.autoApplyOnStartup.label")
        description: pluginApi?.tr("settings.autoApplyOnStartup.description")
        checked: root.editAutoApplyOnStartup
        onToggled: checked => root.editAutoApplyOnStartup = checked
      }

      NDivider {
        Layout.fillWidth: true
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.category.audioTitle")
        color: Color.mOnSurface
        font.weight: Font.Bold
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultMuted.label")
        description: pluginApi?.tr("settings.defaultMuted.description")
        checked: root.editDefaultMuted
        onToggled: checked => root.editDefaultMuted = checked
      }

      NSpinBox {
        id: defaultVolumeSpinBox
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultVolume.label")
        description: pluginApi?.tr("settings.defaultVolume.description")
        from: 0
        to: 100
        stepSize: 1
        suffix: pluginApi?.tr("settings.units.percent")
        value: root.editDefaultVolume
        enabled: !root.editDefaultMuted
        onValueChanged: if (value !== root.editDefaultVolume) root.editDefaultVolume = value
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultAudioReactiveEffects.label")
        description: pluginApi?.tr("settings.defaultAudioReactiveEffects.description")
        checked: root.editDefaultAudioReactiveEffects
        onToggled: checked => root.editDefaultAudioReactiveEffects = checked
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultNoAutomute.label")
        description: pluginApi?.tr("settings.defaultNoAutomute.description")
        checked: root.editDefaultNoAutomute
        onToggled: checked => root.editDefaultNoAutomute = checked
      }

      NDivider {
        Layout.fillWidth: true
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.category.displayTitle")
        color: Color.mOnSurface
        font.weight: Font.Bold
      }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultScaling.label")
        description: pluginApi?.tr("settings.defaultScaling.description")
        model: [
          { "key": "fill", "name": pluginApi?.tr("panel.scalingFill") },
          { "key": "fit", "name": pluginApi?.tr("panel.scalingFit") },
          { "key": "stretch", "name": pluginApi?.tr("panel.scalingStretch") },
          { "key": "default", "name": pluginApi?.tr("panel.scalingDefault") }
        ]
        currentKey: root.editDefaultScaling
        onSelected: key => root.editDefaultScaling = key
      }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultClamp.label")
        description: pluginApi?.tr("settings.defaultClamp.description")
        model: [
          { "key": "clamp", "name": pluginApi?.tr("panel.clampClamp") },
          { "key": "border", "name": pluginApi?.tr("panel.clampBorder") },
          { "key": "repeat", "name": pluginApi?.tr("panel.clampRepeat") }
        ]
        currentKey: root.editDefaultClamp
        onSelected: key => root.editDefaultClamp = key
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultDisableMouse.label")
        description: pluginApi?.tr("settings.defaultDisableMouse.description")
        checked: root.editDefaultDisableMouse
        onToggled: checked => root.editDefaultDisableMouse = checked
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.defaultDisableParallax.label")
        description: pluginApi?.tr("settings.defaultDisableParallax.description")
        checked: root.editDefaultDisableParallax
        onToggled: checked => root.editDefaultDisableParallax = checked
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("LWEController", "Cannot save settings: pluginApi is null");
      return;
    }

    if (pluginApi.pluginSettings.screens === undefined || pluginApi.pluginSettings.screens === null) {
      pluginApi.pluginSettings.screens = {};
    }

    pluginApi.pluginSettings.wallpapersFolder = root.editWallpapersFolder;
    pluginApi.pluginSettings.assetsDir = root.editAssetsDir;
    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.pluginSettings.enableExtraPropertiesEditor = root.editEnableExtraPropertiesEditor;
    pluginApi.pluginSettings.defaultScaling = root.editDefaultScaling;
    pluginApi.pluginSettings.defaultClamp = root.editDefaultClamp;
    pluginApi.pluginSettings.defaultFps = defaultFpsSpinBox.value;
    pluginApi.pluginSettings.defaultVolume = defaultVolumeSpinBox.value;
    pluginApi.pluginSettings.defaultMuted = root.editDefaultMuted;
    pluginApi.pluginSettings.defaultAudioReactiveEffects = root.editDefaultAudioReactiveEffects;
    pluginApi.pluginSettings.defaultNoAutomute = root.editDefaultNoAutomute;
    pluginApi.pluginSettings.defaultDisableMouse = root.editDefaultDisableMouse;
    pluginApi.pluginSettings.defaultDisableParallax = root.editDefaultDisableParallax;
    pluginApi.pluginSettings.defaultNoFullscreenPause = root.editDefaultNoFullscreenPause;
    pluginApi.pluginSettings.defaultFullscreenPauseOnlyActive = root.editDefaultFullscreenPauseOnlyActive;
    pluginApi.pluginSettings.autoApplyOnStartup = root.editAutoApplyOnStartup;
    pluginApi.pluginSettings.wallpaperScanCacheMinutes = root.editWallpaperScanCacheMinutes;

    pluginApi.saveSettings();
    Logger.d("LWEController", "Settings saved", "wallpapersFolder=", root.editWallpapersFolder, "assetsDir=", root.editAssetsDir, "defaultScaling=", root.editDefaultScaling, "defaultClamp=", root.editDefaultClamp, "defaultFps=", defaultFpsSpinBox.value, "defaultVolume=", defaultVolumeSpinBox.value, "defaultMuted=", root.editDefaultMuted, "defaultAudioReactiveEffects=", root.editDefaultAudioReactiveEffects, "defaultNoAutomute=", root.editDefaultNoAutomute, "defaultDisableMouse=", root.editDefaultDisableMouse, "defaultDisableParallax=", root.editDefaultDisableParallax, "defaultNoFullscreenPause=", root.editDefaultNoFullscreenPause, "defaultFullscreenPauseOnlyActive=", root.editDefaultFullscreenPauseOnlyActive, "autoApplyOnStartup=", root.editAutoApplyOnStartup, "wallpaperScanCacheMinutes=", root.editWallpaperScanCacheMinutes);

    if (pluginApi.mainInstance) {
      Logger.d("LWEController", "Refreshing wallpaper cache and reloading engine after settings save");
      pluginApi.mainInstance.refreshWallpaperCache(true, false);
      if (pluginApi.mainInstance.hasAnyConfiguredWallpaper()) {
        pluginApi.mainInstance.reload();
      }
    }
  }

  Process {
    id: scanProcess
    running: false

    command: {
      const pluginDir = root.pluginApi?.pluginDir || "";
      const scriptPath = pluginDir + "/scripts/detect-steam-workshop.sh";
      return ["bash", scriptPath];
    }

    onExited: function () {
      root.scanning = false;
      const detected = String(stdout.text || "").trim();
      if (detected.length > 0 && root.editWallpapersFolder.length === 0) {
        root.editWallpapersFolder = detected;
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: cacheSizeProcess
    running: false
    command: {
      const pluginDir = root.pluginApi?.pluginDir || "";
      const scriptPath = pluginDir + "/scripts/get-cache-size-bytes.sh";
      return ["bash", scriptPath, root.pluginCacheDir];
    }

    onExited: function (exitCode) {
      root.refreshingCacheSize = false;

      if (exitCode !== 0) {
        const errorOutput = String(stderr.text || "").trim();
        if (errorOutput.length > 0) {
          Logger.w("LWEController", "Failed to get cache size", errorOutput);
        }
        root.cacheSizeLabel = pluginApi?.tr("settings.cache.sizeUnknown");
        return;
      }

      const output = String(stdout.text || "").trim();
      const bytes = Number(output);
      if (output.length === 0 || isNaN(bytes) || bytes < 0) {
        root.cacheSizeLabel = pluginApi?.tr("settings.cache.sizeUnknown");
        return;
      }

      root.cacheSizeLabel = root.formatBytes(bytes);
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: clearCacheProcess
    running: false
    command: root.clearCacheCommand()

    onExited: function () {
      root.clearingCache = false;
      if (pluginApi) {
        pluginApi.pluginSettings.wallpaperColorScreenshots = root.preservedWallpaperColorScreenshots();
        pluginApi.saveSettings();
      }
      root.refreshCacheSize();
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }
}
