import QtQuick
import Quickshell
import Quickshell.Io

import "helpers/ColorCacheHelpers.js" as ColorCacheHelpers

import qs.Commons
import qs.Services.UI
import qs.Services.Theming

Item {
  id: root

  property var pluginApi: null

  property bool checkingEngine: true
  property bool engineAvailable: false
  property bool isApplying: false
  property bool wallpaperScanShowToast: false
  property bool stopRequested: false
  property bool recoveryInProgress: false
  property bool applyingWallpaperColors: false
  property string lastError: ""
  property string lastErrorDetails: ""
  property string statusMessage: ""
  readonly property bool engineRunning: engineProcess.running || isApplying || pendingCommand.length > 0
  property string lastScreenSetSignature: ""
  property bool scanningWallpapers: false
  property bool wallpapersFolderAccessible: true
  property var cachedWallpaperItems: []
  property double lastWallpaperScanAt: 0
  property var pendingWallpaperColorRequest: null
  property string pendingCachedWallpaperColorPath: ""
  property string pendingCachedWallpaperColorScreenName: ""
  property var pendingWallpaperColorReuseRequest: null
  property string wallpaperColorScreenName: ""
  property string wallpaperColorScaling: "fill"
  property string wallpaperColorRequestPath: ""
  property string wallpaperColorScreenshotPath: ""
  readonly property string activeColorMonitor: String(Settings.data.colorSchemes.monitorForColors || Quickshell.screens[0]?.name || "")
  readonly property bool wallpaperColorsEnabled: !!Settings.data.colorSchemes.useWallpaperColors
  readonly property bool wallpaperColorDarkMode: !!Settings.data.colorSchemes.darkMode
  readonly property string wallpaperColorGenerationMethod: String(Settings.data.colorSchemes.generationMethod || "")

  property var pendingCommand: []

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Initialization and persistence helpers.
  Component.onCompleted: {
    Logger.i("LWEController", "Main initialized");
    lastScreenSetSignature = currentScreenSetSignature();
    scheduleCachedWallpaperColorsForMonitor("startup");
  }

  function ensureSettingsRoot() {
    if (!pluginApi) {
      return;
    }

    if (pluginApi.pluginSettings.screens === undefined || pluginApi.pluginSettings.screens === null) {
      pluginApi.pluginSettings.screens = {};
    }

    if (pluginApi.pluginSettings.lastKnownGoodScreens === undefined || pluginApi.pluginSettings.lastKnownGoodScreens === null) {
      pluginApi.pluginSettings.lastKnownGoodScreens = {};
    }

    if (pluginApi.pluginSettings.wallpaperProperties === undefined || pluginApi.pluginSettings.wallpaperProperties === null) {
      pluginApi.pluginSettings.wallpaperProperties = {};
    }

    if (pluginApi.pluginSettings.runtimeRecoveryPending === undefined || pluginApi.pluginSettings.runtimeRecoveryPending === null) {
      pluginApi.pluginSettings.runtimeRecoveryPending = false;
    }

    if (pluginApi.pluginSettings.wallpaperColorScreenshots === undefined || pluginApi.pluginSettings.wallpaperColorScreenshots === null) {
      pluginApi.pluginSettings.wallpaperColorScreenshots = {};
    }
  }

  function cloneValue(value) {
    return JSON.parse(JSON.stringify(value || ({})));
  }

  function hasAnyScreenPathFrom(sourceScreens) {
    const screens = sourceScreens || ({});
    const keys = Object.keys(screens);
    for (const key of keys) {
      const screenCfg = screens[key] || ({});
      const path = normalizedPath(screenCfg.path || "");
      if (path.length > 0) {
        return true;
      }
    }
    return false;
  }

  function markRuntimeRecoveryPending(value, flushToDisk = true) {
    if (!pluginApi) {
      return;
    }

    ensureSettingsRoot();
    const nextValue = !!value;
    if (pluginApi.pluginSettings.runtimeRecoveryPending === nextValue) {
      return;
    }

    pluginApi.pluginSettings.runtimeRecoveryPending = nextValue;
    if (flushToDisk) {
      pluginApi.saveSettings();
    }
  }

  function saveCurrentLayoutAsLastKnownGood(reason) {
    if (!pluginApi) {
      return false;
    }

    ensureSettingsRoot();

    const currentScreens = cloneValue(pluginApi.pluginSettings.screens || ({}));
    if (!hasAnyScreenPathFrom(currentScreens)) {
      Logger.d("LWEController", "Skip last-known-good snapshot: no configured paths", "reason=", reason);
      return false;
    }

    pluginApi.pluginSettings.lastKnownGoodScreens = currentScreens;
    pluginApi.pluginSettings.runtimeRecoveryPending = false;
    pluginApi.saveSettings();

    Logger.i("LWEController", "Saved last-known-good layout", "reason=", reason);
    return true;
  }

  function restoreLastKnownGoodLayout(reason) {
    if (!pluginApi) {
      return false;
    }

    ensureSettingsRoot();

    const snapshot = pluginApi.pluginSettings.lastKnownGoodScreens || ({});
    if (!hasAnyScreenPathFrom(snapshot)) {
      Logger.w("LWEController", "No restorable last-known-good layout", "reason=", reason);
      return false;
    }

    pluginApi.pluginSettings.screens = cloneValue(snapshot);
    pluginApi.pluginSettings.runtimeRecoveryPending = false;
    pluginApi.saveSettings();

    Logger.i("LWEController", "Restored last-known-good layout", "reason=", reason);
    return true;
  }

  function tryAutoRecoverFromRuntimeError(reason) {
    if (!pluginApi || recoveryInProgress) {
      return false;
    }

    if (!restoreLastKnownGoodLayout(reason)) {
      markRuntimeRecoveryPending(true);
      return false;
    }

    markErrorAsRecovered();
    recoveryInProgress = true;
    if (engineAvailable && hasAnyConfiguredWallpaper()) {
      restartEngine();
    }

    return true;
  }

  function recoverPendingLayoutOnStartup() {
    if (!pluginApi) {
      return false;
    }

    ensureSettingsRoot();
    const pending = !!pluginApi.pluginSettings.runtimeRecoveryPending;
    if (!pending) {
      return false;
    }

    const restored = restoreLastKnownGoodLayout("startup-pending-recovery");
    if (!restored) {
      markRuntimeRecoveryPending(false);
      return false;
    }

    Logger.i("LWEController", "Startup recovery applied from pending marker");
    return true;
  }

  // Runtime defaults derived from settings.
  readonly property string defaultScaling: cfg.defaultScaling ?? defaults.defaultScaling ?? "fill"
  readonly property string defaultClamp: cfg.defaultClamp ?? defaults.defaultClamp ?? "clamp"
  readonly property int defaultFps: cfg.defaultFps ?? defaults.defaultFps ?? 30

  readonly property int defaultVolume: {
    const value = Number(cfg.defaultVolume ?? defaults.defaultVolume ?? 100);
    if (isNaN(value)) {
      return 100;
    }
    return Math.max(0, Math.min(100, Math.floor(value)));
  }

  readonly property bool defaultMuted: cfg.defaultMuted ?? defaults.defaultMuted ?? true
  readonly property bool defaultAudioReactiveEffects: cfg.defaultAudioReactiveEffects ?? defaults.defaultAudioReactiveEffects ?? true
  readonly property bool defaultNoAutomute: cfg.defaultNoAutomute ?? defaults.defaultNoAutomute ?? false
  readonly property bool defaultDisableMouse: cfg.defaultDisableMouse ?? defaults.defaultDisableMouse ?? false
  readonly property bool defaultDisableParallax: cfg.defaultDisableParallax ?? defaults.defaultDisableParallax ?? false
  readonly property bool defaultNoFullscreenPause: cfg.defaultNoFullscreenPause ?? defaults.defaultNoFullscreenPause ?? false
  readonly property bool defaultFullscreenPauseOnlyActive: cfg.defaultFullscreenPauseOnlyActive ?? defaults.defaultFullscreenPauseOnlyActive ?? false
  readonly property bool defaultAutoApply: cfg.autoApplyOnStartup ?? defaults.autoApplyOnStartup ?? true
  readonly property string assetsDir: cfg.assetsDir ?? defaults.assetsDir ?? ""
  readonly property int wallpaperScanCacheMinutes: {
    const value = Number(cfg.wallpaperScanCacheMinutes ?? defaults.wallpaperScanCacheMinutes ?? 5);
    if (isNaN(value)) {
      return 5;
    }
    return Math.max(0, Math.floor(value));
  }

  // Screen and wallpaper configuration accessors.
  function normalizedPath(path) {
    return Settings.preprocessPath(String(path || ""));
  }

  function currentScreenSetSignature() {
    return Quickshell.screens
      .map(screen => String(screen.name || ""))
      .sort()
      .join("|");
  }

  function wallpaperScanCacheValid() {
    if (scanningWallpapers) {
      return true;
    }

    if (wallpaperScanCacheMinutes <= 0) {
      return false;
    }

    if (!cachedWallpaperItems || cachedWallpaperItems.length === 0) {
      return false;
    }

    if (lastWallpaperScanAt <= 0) {
      return false;
    }

    const ageMs = Date.now() - lastWallpaperScanAt;
    return ageMs < wallpaperScanCacheMinutes * 60 * 1000;
  }

  function handleScreenTopologyChanged() {
    const nextSignature = currentScreenSetSignature();
    if (nextSignature === lastScreenSetSignature) {
      return;
    }

    const previousSignature = lastScreenSetSignature;
    lastScreenSetSignature = nextSignature;
    Logger.i("LWEController", "Screen topology changed", "from=", previousSignature, "to=", nextSignature);

    screenTopologyRestartDebounce.restart();
  }

  function getScreenConfig(screenName) {
    const screenConfigs = cfg.screens || ({});
    const raw = screenConfigs[screenName] || ({});

    return {
      path: raw.path ?? "",
      scaling: raw.scaling ?? defaultScaling,
      clamp: raw.clamp ?? defaultClamp
    };
  }

  function hasAnyConfiguredWallpaper() {
    for (const screen of Quickshell.screens) {
      const screenCfg = getScreenConfig(screen.name);
      if (screenCfg.path && screenCfg.path.length > 0) {
        return true;
      }
    }
    return false;
  }

  function wallpaperIdFromPath(path) {
    const raw = normalizedPath(path);
    if (raw.length === 0) {
      return "";
    }

    const parts = raw.split("/");
    return parts.length > 0 ? String(parts[parts.length - 1] || "") : "";
  }

  function cloneWallpaperProperties(source) {
    const cloned = {};
    const raw = source || ({});
    for (const key of Object.keys(raw)) {
      const value = raw[key];
      if (value !== undefined) {
        cloned[key] = value;
      }
    }
    return cloned;
  }

  function setWallpaperProperties(path, properties) {
    if (!pluginApi) {
      return;
    }

    ensureSettingsRoot();
    const wallpaperId = wallpaperIdFromPath(path);
    if (wallpaperId.length === 0) {
      return;
    }

    pluginApi.pluginSettings.wallpaperProperties[wallpaperId] = cloneWallpaperProperties(properties);
  }

  function getWallpaperProperties(path) {
    const wallpaperId = wallpaperIdFromPath(path);
    if (wallpaperId.length === 0) {
      return {};
    }

    const raw = cfg.wallpaperProperties || ({});
    return cloneWallpaperProperties(raw[wallpaperId] || ({}));
  }

  function setScreenWallpaper(screenName, path) {
    setScreenWallpaperWithOptions(screenName, path, ({}));
  }

  function clearLegacyScreenRuntimeOptions(screenName) {
    const screenConfig = pluginApi?.pluginSettings?.screens?.[screenName];
    if (!screenConfig) {
      return;
    }

    delete screenConfig.clamp;
    delete screenConfig.volume;
    delete screenConfig.muted;
    delete screenConfig.audioReactiveEffects;
    delete screenConfig.noAutomute;
    delete screenConfig.disableMouse;
    delete screenConfig.disableParallax;
  }

  function clearLegacyRuntimeOptionsForAllScreens() {
    for (const screen of Quickshell.screens) {
      clearLegacyScreenRuntimeOptions(screen.name);
    }
  }

  function currentWallpaperColorMode() {
    return Settings.data.colorSchemes.darkMode ? "dark" : "light";
  }

  function syncWallpaperColorSource(screenName, screenshotPath) {
    const normalizedScreenName = String(screenName || "").trim();
    const normalizedScreenshotPath = String(screenshotPath || "").trim();
    if (normalizedScreenName.length === 0 || normalizedScreenshotPath.length === 0) {
      return;
    }

    WallpaperService.changeWallpaper(normalizedScreenshotPath, normalizedScreenName, "dark");
    WallpaperService.changeWallpaper(normalizedScreenshotPath, normalizedScreenName, "light");
  }

  function applyWallpaperColorsFromScreenshot(screenName, screenshotPath) {
    if (String(screenshotPath || "").trim().length === 0) {
      return;
    }

    syncWallpaperColorSource(screenName, screenshotPath);
    TemplateProcessor.processWallpaperColors(screenshotPath, currentWallpaperColorMode());
  }

  function screenshotPathForWallpaper(path, screenName = "") {
    return ColorCacheHelpers.screenshotPathForWallpaper(
      Settings.cacheDir,
      pluginApi?.manifest?.id || pluginApi?.pluginId || "linux-wallpaperengine-controller",
      wallpaperIdFromPath(path),
      screenName
    );
  }

  function wallpaperColorScreenshotEntry(screenName) {
    ensureSettingsRoot();
    return ColorCacheHelpers.cachedScreenshotEntry(pluginApi?.pluginSettings?.wallpaperColorScreenshots, screenName);
  }

  function canReuseWallpaperColorScreenshot(screenName, wallpaperPath, scaling) {
    return ColorCacheHelpers.canReuseScreenshot(
      pluginApi?.pluginSettings?.wallpaperColorScreenshots,
      screenName,
      wallpaperPath,
      scaling,
      normalizedPath,
      defaultScaling
    );
  }

  function startWallpaperColorCapture(wallpaperPath, targetScreenName, targetScaling) {
    const screenshotPath = screenshotPathForWallpaper(wallpaperPath, targetScreenName);
    const pluginDir = pluginApi?.pluginDir || "";
    const scriptPath = pluginDir + "/scripts/capture-wallpaper-colors.sh";
    const command = [
      "bash",
      scriptPath,
      screenshotPath,
      "linux-wallpaperengine"
    ];
    const maybeAssetsDir = normalizedPath(assetsDir);
    const wallpaperProperties = getWallpaperProperties(wallpaperPath);

    if (maybeAssetsDir.length > 0) {
      command.push("--assets-dir");
      command.push(maybeAssetsDir);
    }

    command.push("--fps");
    command.push(String(defaultFps));
    command.push("--clamp");
    command.push(String(defaultClamp || "clamp"));
    command.push("--screen-root");
    command.push(targetScreenName);
    command.push("--bg");
    command.push(wallpaperPath);
    command.push("--scaling");
    command.push(targetScaling.length > 0 ? targetScaling : "fill");
    command.push("--screenshot");
    command.push(screenshotPath);

    for (const propertyKey of Object.keys(wallpaperProperties)) {
      const propertyValue = wallpaperProperties[propertyKey];
      if (propertyValue === undefined || propertyValue === null || String(propertyKey || "").trim().length === 0) {
        continue;
      }
      command.push("--set-property");
      command.push(String(propertyKey) + "=" + String(propertyValue));
    }

    applyingWallpaperColors = true;
    wallpaperColorRequestPath = wallpaperPath;
    wallpaperColorScreenshotPath = screenshotPath;
    wallpaperColorScreenName = targetScreenName;
    wallpaperColorScaling = targetScaling.length > 0 ? targetScaling : "fill";
    wallpaperColorProcess.command = command;
    wallpaperColorProcess.running = true;

    Logger.i("LWEController", "Generating screenshot for wallpaper color extraction", "path=", wallpaperPath, "screen=", targetScreenName, "scaling=", wallpaperColorScaling, "output=", screenshotPath);
    ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsGenerating"), "palette");
  }

  function saveWallpaperColorScreenshot(screenName, screenshotPath, wallpaperPath, scaling) {
    if (!pluginApi || screenName.length === 0 || screenshotPath.length === 0) {
      return;
    }

    ensureSettingsRoot();
    pluginApi.pluginSettings.wallpaperColorScreenshots[screenName] = {
      "path": screenshotPath,
      "wallpaperPath": wallpaperPath,
      "scaling": scaling,
      "updatedAt": Date.now()
    };
    pluginApi.saveSettings();
  }

  function scheduleCachedWallpaperColorsForMonitor(reason = "") {
    if (!wallpaperColorsEnabled) {
      return;
    }

    const screenName = activeColorMonitor;
    if (screenName.length === 0) {
      return;
    }

    const entry = wallpaperColorScreenshotEntry(screenName);
    const screenshotPath = normalizedPath(entry?.path || "");
    if (screenshotPath.length === 0) {
      Logger.d("LWEController", "No cached wallpaper color screenshot for active monitor", "screen=", screenName, "reason=", reason);
      return;
    }

    pendingCachedWallpaperColorPath = screenshotPath;
    pendingCachedWallpaperColorScreenName = screenName;
    const pluginDir = pluginApi?.pluginDir || "";
    const scriptPath = pluginDir + "/scripts/check-file-exists.sh";
    cachedWallpaperColorSyncCheckProcess.command = ["bash", scriptPath, screenshotPath];
    cachedWallpaperColorSyncCheckProcess.running = true;
    Logger.d("LWEController", "Scheduled cached wallpaper color sync", "screen=", screenName, "path=", screenshotPath, "reason=", reason);
  }

  function applyWallpaperColorsFromPath(path, options = null) {
    const wallpaperPath = normalizedPath(path);
    const requestOptions = options || ({});
    const targetScreenName = String(requestOptions.screenName || Quickshell.screens[0]?.name || "").trim();
    const targetScaling = String(requestOptions.scaling || defaultScaling || "fill").trim();
    if (!engineAvailable) {
      ToastService.showWarning(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsEngineUnavailable"), "alert-circle");
      return;
    }

    if (wallpaperPath.length === 0) {
      ToastService.showWarning(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsNoSelection"), "alert-circle");
      return;
    }

    if (targetScreenName.length === 0) {
      ToastService.showError(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsFailed"), "alert-circle");
      return;
    }

    if (applyingWallpaperColors) {
      return;
    }

    if (canReuseWallpaperColorScreenshot(targetScreenName, wallpaperPath, targetScaling)) {
      const entry = wallpaperColorScreenshotEntry(targetScreenName);
      const cachedPath = normalizedPath(entry?.path || "");
      const pluginDir = pluginApi?.pluginDir || "";
      const scriptPath = pluginDir + "/scripts/check-file-exists.sh";
      pendingWallpaperColorReuseRequest = {
        "wallpaperPath": wallpaperPath,
        "screenName": targetScreenName,
        "scaling": targetScaling,
        "screenshotPath": cachedPath
      };
      reusedWallpaperColorCheckProcess.command = ["bash", scriptPath, cachedPath];
      reusedWallpaperColorCheckProcess.running = true;
      return;
    }
    startWallpaperColorCapture(wallpaperPath, targetScreenName, targetScaling);
  }

  function scheduleWallpaperColorsFromPath(path, options = null) {
    const wallpaperPath = normalizedPath(path);
    if (wallpaperPath.length === 0) {
      return;
    }

    pendingWallpaperColorRequest = {
      "path": wallpaperPath,
      "screenName": String(options?.screenName || Quickshell.screens[0]?.name || ""),
      "scaling": String(options?.scaling || defaultScaling || "fill")
    };
    wallpaperColorStartTimer.restart();
    Logger.d("LWEController", "Scheduled wallpaper color extraction", "path=", wallpaperPath, "screen=", pendingWallpaperColorRequest.screenName, "scaling=", pendingWallpaperColorRequest.scaling);
  }

  function refreshWallpaperCache(force = false, showToast = false) {
    const folderPath = Settings.preprocessPath(String(cfg.wallpapersFolder ?? defaults.wallpapersFolder ?? "")).trim();

    if (folderPath.length === 0) {
      cachedWallpaperItems = [];
      wallpapersFolderAccessible = false;
      scanningWallpapers = false;
      lastWallpaperScanAt = 0;
      if (showToast) {
        ToastService.showWarning(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.refreshSkippedNoFolder"), "alert-circle");
      }
      Logger.w("LWEController", "Wallpaper refresh skipped: wallpapers folder is empty");
      return;
    }

    if (!force && wallpaperScanCacheValid()) {
      Logger.d("LWEController", "Wallpaper cache reused", "count=", cachedWallpaperItems.length, "ageMs=", Date.now() - lastWallpaperScanAt);
      return;
    }

    const pluginDir = pluginApi?.pluginDir || "";
    const scriptPath = pluginDir + "/scripts/scan-wallpapers.sh";

    Logger.i("LWEController", force ? "Refreshing wallpaper cache" : "Scanning wallpapers for cache", folderPath);
    scanningWallpapers = true;
    wallpaperScanShowToast = showToast;
    wallpaperScanProcess.command = ["bash", scriptPath, folderPath];
    wallpaperScanProcess.running = true;
    if (showToast) {
      ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.refreshingWallpapers"), "refresh");
    }
  }

  // Wallpaper application and persistence.
  function setScreenWallpaperWithOptions(screenName, path, options) {
    if (!pluginApi) {
      return;
    }

    Logger.i("LWEController", "Set wallpaper requested", screenName, path, JSON.stringify(options || ({})));

    ensureSettingsRoot();

    if (pluginApi.pluginSettings.screens[screenName] === undefined) {
      pluginApi.pluginSettings.screens[screenName] = {};
    }

    pluginApi.pluginSettings.screens[screenName].path = path;

    const resolvedScaling = (options?.scaling || "").trim();
    const resolvedClamp = (options?.clamp || "").trim();
    if (resolvedScaling.length > 0) {
      pluginApi.pluginSettings.screens[screenName].scaling = resolvedScaling;
    }
    if (resolvedClamp.length > 0) {
      pluginApi.pluginSettings.defaultClamp = resolvedClamp;
    }

    if (options?.volume !== undefined) {
      const rawVolume = Number(options.volume);
      if (!isNaN(rawVolume)) {
        pluginApi.pluginSettings.defaultVolume = Math.max(0, Math.min(100, Math.floor(rawVolume)));
      }
    }

    if (options?.muted !== undefined) {
      pluginApi.pluginSettings.defaultMuted = !!options.muted;
    }

    if (options?.audioReactiveEffects !== undefined) {
      pluginApi.pluginSettings.defaultAudioReactiveEffects = !!options.audioReactiveEffects;
    }

    if (options?.noAutomute !== undefined) {
      pluginApi.pluginSettings.defaultNoAutomute = !!options.noAutomute;
    }

    if (options?.disableMouse !== undefined) {
      pluginApi.pluginSettings.defaultDisableMouse = !!options.disableMouse;
    }

    if (options?.disableParallax !== undefined) {
      pluginApi.pluginSettings.defaultDisableParallax = !!options.disableParallax;
    }

    clearLegacyScreenRuntimeOptions(screenName);

    if (options?.customProperties !== undefined) {
      setWallpaperProperties(path, options.customProperties);
    }

    pluginApi.saveSettings();

    restartEngine();
  }

  function clearScreenWallpaper(screenName) {
    if (!pluginApi) {
      return;
    }

    Logger.i("LWEController", "Clear wallpaper requested", screenName);

    ensureSettingsRoot();

    if (pluginApi.pluginSettings.screens[screenName] === undefined) {
      pluginApi.pluginSettings.screens[screenName] = {};
    }

    pluginApi.pluginSettings.screens[screenName].path = "";
    pluginApi.saveSettings();

    restartEngine();
  }

  function setAllScreensWallpaper(path) {
    setAllScreensWallpaperWithOptions(path, ({}));
  }

  function setAllScreensWallpaperWithOptions(path, options) {
    if (!pluginApi || !path || path.length === 0) {
      return;
    }

    Logger.i("LWEController", "Set wallpaper for all screens", path, JSON.stringify(options || ({})));

    ensureSettingsRoot();

    const resolvedScaling = (options?.scaling || "").trim();
    const resolvedClamp = (options?.clamp || "").trim();
    const resolvedVolumeRaw = Number(options?.volume);
    const hasResolvedVolume = !isNaN(resolvedVolumeRaw);
    const resolvedVolume = hasResolvedVolume ? Math.max(0, Math.min(100, Math.floor(resolvedVolumeRaw))) : 0;
    const hasMuted = options?.muted !== undefined;
    const hasAudioReactive = options?.audioReactiveEffects !== undefined;
    const hasNoAutomute = options?.noAutomute !== undefined;
    const hasDisableMouse = options?.disableMouse !== undefined;
    const hasDisableParallax = options?.disableParallax !== undefined;

    for (const screen of Quickshell.screens) {
      if (pluginApi.pluginSettings.screens[screen.name] === undefined) {
        pluginApi.pluginSettings.screens[screen.name] = {};
      }

      pluginApi.pluginSettings.screens[screen.name].path = path;
      if (resolvedScaling.length > 0) {
        pluginApi.pluginSettings.screens[screen.name].scaling = resolvedScaling;
      }
      if (options?.customProperties !== undefined) {
        setWallpaperProperties(path, options.customProperties);
      }
    }

    if (resolvedClamp.length > 0) {
      pluginApi.pluginSettings.defaultClamp = resolvedClamp;
    }

    if (hasResolvedVolume) {
      pluginApi.pluginSettings.defaultVolume = resolvedVolume;
    }
    if (hasMuted) {
      pluginApi.pluginSettings.defaultMuted = !!options.muted;
    }
    if (hasAudioReactive) {
      pluginApi.pluginSettings.defaultAudioReactiveEffects = !!options.audioReactiveEffects;
    }
    if (hasNoAutomute) {
      pluginApi.pluginSettings.defaultNoAutomute = !!options.noAutomute;
    }
    if (hasDisableMouse) {
      pluginApi.pluginSettings.defaultDisableMouse = !!options.disableMouse;
    }
    if (hasDisableParallax) {
      pluginApi.pluginSettings.defaultDisableParallax = !!options.disableParallax;
    }

    clearLegacyRuntimeOptionsForAllScreens();

    pluginApi.saveSettings();
    restartEngine();
  }

  // Runtime error handling.
  function extractRuntimeError(stderrText) {
    const text = (stderrText || "").trim();
    if (text.length === 0) {
      return "";
    }

    const lower = text.toLowerCase();

    if (lower.indexOf("cannot find a valid assets folder") !== -1) {
      return pluginApi?.tr("main.error.assetsMissing");
    }

    if (lower.indexOf("at least one background id must be specified") !== -1) {
      return pluginApi?.tr("main.error.noBackground");
    }

    if (lower.indexOf("opengl") !== -1 || lower.indexOf("glfw") !== -1) {
      return pluginApi?.tr("main.error.opengl");
    }

    const lines = text.split(/\r?\n/)
      .map(line => (line || "").trim())
      .filter(line => line.length > 0);

    if (lines.length === 0) {
      return "";
    }

    let summary = lines[0];
    for (const line of lines) {
      const normalized = line.toLowerCase();
      if (normalized.indexOf("error") !== -1 || normalized.indexOf("failed") !== -1) {
        summary = line;
        break;
      }
    }

    const maxLength = 220;
    if (summary.length > maxLength) {
      summary = summary.substring(0, maxLength) + "...";
    }

    return summary;
  }

  function setRuntimeErrorFromStderr(stderrText) {
    const raw = (stderrText || "").trim();
    if (raw.length === 0) {
      return false;
    }

    const summary = extractRuntimeError(raw);
    if (summary.length === 0) {
      return false;
    }

    lastError = summary;
    lastErrorDetails = raw;
    return true;
  }

  function markErrorAsRecovered() {
    const hintRaw = pluginApi?.tr("main.error.autoRecovered");
    if (hintRaw === undefined || hintRaw === null) {
      return;
    }

    const hint = hintRaw.trim();
    const current = (lastError || "").trim();
    if (hint.length === 0 || current.length === 0) {
      return;
    }

    if (current.indexOf(hint) !== -1) {
      return;
    }

    lastError = current + " (" + hint + ")";
  }

  // Command construction and engine lifecycle.
  function buildCommand() {
    const command = ["linux-wallpaperengine"];
    let firstPath = "";
    const appendedWallpaperIds = {};
    let runtimeOptions = {
      volume: defaultVolume,
      muted: defaultMuted,
      audioReactiveEffects: defaultAudioReactiveEffects,
      noAutomute: defaultNoAutomute,
      disableMouse: defaultDisableMouse,
      disableParallax: defaultDisableParallax
    };

    command.push("--fps");
    command.push(String(defaultFps));

    const runtimeClamp = String(defaultClamp || "clamp").trim();
    if (runtimeClamp.length > 0) {
      command.push("--clamp");
      command.push(runtimeClamp);
    }

    if (runtimeOptions.muted) {
      command.push("--silent");
    } else {
      command.push("--volume");
      command.push(String(runtimeOptions.volume));
    }

    if (!runtimeOptions.audioReactiveEffects) {
      command.push("--no-audio-processing");
    }

    if (runtimeOptions.noAutomute) {
      command.push("--noautomute");
    }

    if (runtimeOptions.disableMouse) {
      command.push("--disable-mouse");
    }

    if (runtimeOptions.disableParallax) {
      command.push("--disable-parallax");
    }

    if (defaultNoFullscreenPause) {
      command.push("--no-fullscreen-pause");
    }

    if (defaultFullscreenPauseOnlyActive) {
      command.push("--fullscreen-pause-only-active");
    }

    const maybeAssetsDir = normalizedPath(assetsDir);
    if (maybeAssetsDir.length > 0) {
      command.push("--assets-dir");
      command.push(maybeAssetsDir);
    }

    for (const screen of Quickshell.screens) {
      const screenCfg = getScreenConfig(screen.name);
      const path = normalizedPath(screenCfg.path);
      if (!path || path.length === 0) {
        continue;
      }

      if (firstPath.length === 0) {
        firstPath = path;
      }

      command.push("--screen-root");
      command.push(screen.name);
      command.push("--bg");
      command.push(path);

      command.push("--scaling");
      command.push(String(screenCfg.scaling));

      const wallpaperId = wallpaperIdFromPath(path);
      if (wallpaperId.length > 0 && !appendedWallpaperIds[wallpaperId]) {
        const customProperties = getWallpaperProperties(path);
        for (const propertyKey of Object.keys(customProperties)) {
          const propertyValue = customProperties[propertyKey];
          if (propertyValue === undefined || propertyValue === null || String(propertyKey || "").trim().length === 0) {
            continue;
          }
          command.push("--set-property");
          command.push(String(propertyKey) + "=" + String(propertyValue));
        }
        appendedWallpaperIds[wallpaperId] = true;
      }
    }

    return command;
  }

  function stopAll(showToast = false) {
    Logger.i("LWEController", "Stopping engine process");
    pendingCommand = [];

    if (engineProcess.running) {
      stopRequested = true;
      engineProcess.running = false;
    } else {
      stopRequested = false;
    }

    // Always run terminate command to stop detached processes too.
    if (!forceStopProcess.running) {
      forceStopProcess.running = true;
    }

    isApplying = false;
    statusMessage = pluginApi?.tr("main.status.stopped");
    if (showToast) {
      ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.stopped"), "player-stop");
    }
  }

  function startEngineWithCommand(command) {
    if (!engineAvailable) {
      Logger.w("LWEController", "Skip start: engine unavailable");
      return;
    }

    if (!command || command.length <= 1) {
      Logger.w("LWEController", "Skip start: empty command");
      stopAll();
      return;
    }

    Logger.d("LWEController", "Starting engine command", JSON.stringify(command));

    if (!recoveryInProgress) {
      lastError = "";
      lastErrorDetails = "";
    }
    statusMessage = pluginApi?.tr("main.status.starting");
    isApplying = true;

    engineProcess.command = command;
    engineProcess.running = true;
    stableRunTimer.restart();
  }

  function restartEngine() {
    if (!engineAvailable) {
      Logger.w("LWEController", "Skip restart: engine unavailable");
      return;
    }

    if (!hasAnyConfiguredWallpaper()) {
      Logger.i("LWEController", "Skip restart: no configured wallpaper; stopping engine");
      stopAll();
      return;
    }

    const command = buildCommand();
    if (!command || command.length <= 1) {
      Logger.w("LWEController", "Restart resolved to empty command; stopping engine");
      stopAll();
      return;
    }

    if (engineProcess.running) {
      Logger.d("LWEController", "Engine already running; queue restart command");
      pendingCommand = command;
      stopRequested = true;
      engineProcess.running = false;

      // Ensure termination also reaches detached processes before restart.
      if (!forceStopProcess.running) {
        forceStopProcess.running = true;
      }
      return;
    }

    startEngineWithCommand(command);
  }

  function reload(showToast = false) {
    if (!hasAnyConfiguredWallpaper()) {
      lastError = "";
      lastErrorDetails = "";
      statusMessage = pluginApi?.tr("main.status.ready");
      Logger.i("LWEController", "Reload skipped: no configured wallpaper paths");
      if (showToast) {
        ToastService.showWarning(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.reloadSkippedNoWallpaper"), "alert-circle");
      }
      return;
    }

    restartEngine();
    if (showToast) {
      ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.reloaded"), "refresh");
    }
  }

  // External command and IPC integration.
  Process {
    id: wallpaperScanProcess

    onExited: function (exitCode) {
      const parsed = [];
      const lines = String(stdout.text || "").split("\n");
      const stderrText = String(stderr.text || "").trim();

      root.wallpapersFolderAccessible = (exitCode === 0);

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line.length === 0) {
          continue;
        }

        const parts = line.split("\t");
        const path = parts.length > 0 ? parts[0] : "";
        const name = parts.length > 1 && parts[1].length > 0 ? parts[1] : String(path || "").split("/").pop();
        const thumb = parts.length > 2 ? parts[2] : "";
        const motionPreview = parts.length > 3 ? parts[3] : "";
        const dynamic = parts.length > 4 ? parts[4] === "1" : false;
        const id = parts.length > 5 ? parts[5] : String(path || "").split("/").pop();
        const type = parts.length > 6 ? parts[6] : "unknown";
        const resolution = parts.length > 7 ? parts[7] : "unknown";
        const sizeMtime = parts.length > 8 ? parts[8] : "0:0";
        const sizeParts = String(sizeMtime).split(":");
        const bytes = sizeParts.length > 0 ? Number(sizeParts[0]) : 0;
        const mtime = sizeParts.length > 1 ? Number(sizeParts[1]) : 0;

        if (path.length > 0) {
          parsed.push({
            path: path,
            name: name,
            thumb: thumb,
            motionPreview: motionPreview,
            dynamic: dynamic,
            id: id,
            type: type,
            resolution: resolution,
            bytes: bytes,
            mtime: mtime
          });
        }
      }

      root.cachedWallpaperItems = parsed;
      root.scanningWallpapers = false;
      root.lastWallpaperScanAt = exitCode === 0 ? Date.now() : 0;

      if (root.wallpaperScanShowToast && exitCode === 0) {
        ToastService.showNotice(
          pluginApi?.tr("panel.title"),
          pluginApi?.tr("toast.refreshedWallpapers", { count: parsed.length }),
          "refresh"
        );
      }
      root.wallpaperScanShowToast = false;

      if (!root.wallpapersFolderAccessible) {
        if (stderrText.length > 0) {
          Logger.e("LWEController", "Wallpaper scan failed", "folder=", Settings.preprocessPath(String(cfg.wallpapersFolder ?? defaults.wallpapersFolder ?? "")), "exitCode=", exitCode, "stderr=", stderrText);
        } else {
          Logger.e("LWEController", "Wallpaper scan failed", "exitCode=", exitCode);
        }
      }

      Logger.i("LWEController", "Wallpaper cache updated", "count=", parsed.length, "exitCode=", exitCode);
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: engineCheck
    running: true
    command: ["sh", "-c", "command -v linux-wallpaperengine >/dev/null 2>&1"]

    onExited: function (exitCode) {
      root.engineAvailable = (exitCode === 0);
      root.checkingEngine = false;

      Logger.i("LWEController", "Engine check finished", "exitCode=", exitCode, "available=", root.engineAvailable);

      if (!root.engineAvailable) {
        root.lastError = root.pluginApi?.tr("main.error.notInstalled");
        root.lastErrorDetails = "";
        root.statusMessage = root.pluginApi?.tr("main.status.unavailable");
        Logger.e("LWEController", "linux-wallpaperengine binary not found in PATH");
        return;
      }

      root.statusMessage = root.pluginApi?.tr("main.status.ready");

      root.refreshWallpaperCache(false, false);

      root.recoverPendingLayoutOnStartup();

      if (root.defaultAutoApply && root.hasAnyConfiguredWallpaper()) {
        Logger.i("LWEController", "Auto apply enabled with configured wallpapers; restarting engine");
        root.restartEngine();
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: engineProcess

    onExited: function (exitCode, exitStatus) {
      root.isApplying = false;
      stableRunTimer.stop();

      Logger.i("LWEController", "Engine process exited", "exitCode=", exitCode, "exitStatus=", exitStatus, "stopRequested=", root.stopRequested);

      if (root.stopRequested) {
        root.stopRequested = false;
        root.recoveryInProgress = false;

        if (root.pendingCommand.length > 0) {
          const nextCommand = root.pendingCommand;
          root.pendingCommand = [];
          Logger.d("LWEController", "Applying pending command after stop");
          root.startEngineWithCommand(nextCommand);
          return;
        }

        root.statusMessage = root.pluginApi?.tr("main.status.stopped");
        return;
      }

      if (exitCode !== 0 || exitStatus !== Process.NormalExit) {
        if (root.setRuntimeErrorFromStderr(stderr.text)) {
          Logger.e("LWEController", "Engine runtime error", root.lastError);
        }
        root.tryAutoRecoverFromRuntimeError("runtime-crash");
        root.statusMessage = root.pluginApi?.tr("main.status.crashed");
      } else {
        root.recoveryInProgress = false;
        root.statusMessage = root.pluginApi?.tr("main.status.stopped");
      }
    }

    stdout: StdioCollector {}

    stderr: StdioCollector {
      onStreamFinished: {
        if (root.stopRequested) {
          return;
        }

        if (root.setRuntimeErrorFromStderr(text)) {
          Logger.w("LWEController", "Engine stderr", root.lastError);
        }
      }
    }
  }

  Process {
    id: forceStopProcess
    running: false
    command: {
      const pluginDir = root.pluginApi?.pluginDir || "";
      const scriptPath = pluginDir + "/scripts/force-stop-engine.sh";
      return ["bash", scriptPath];
    }

    onExited: function (exitCode) {
      Logger.d("LWEController", "Force stop command finished", "exitCode=", exitCode);
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: wallpaperColorProcess
    running: false

    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      const requestPath = root.wallpaperColorRequestPath;
      const screenshotPath = root.wallpaperColorScreenshotPath;
      const screenName = root.wallpaperColorScreenName;
      const stderrText = String(stderr.text || "").trim();

      root.applyingWallpaperColors = false;
      root.wallpaperColorRequestPath = "";
      root.wallpaperColorScreenshotPath = "";
      root.wallpaperColorScreenName = "";
      root.wallpaperColorScaling = "fill";

      if (exitCode !== 0) {
        Logger.w("LWEController", "Wallpaper screenshot generation failed", "path=", requestPath, "screen=", screenName, "exitCode=", exitCode, "stderr=", stderrText);
        ToastService.showError(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsFailed"), "alert-circle");
        return;
      }

      saveWallpaperColorScreenshot(screenName, screenshotPath, requestPath, root.wallpaperColorScaling);

      if (wallpaperColorsEnabled && screenName === activeColorMonitor) {
        root.applyWallpaperColorsFromScreenshot(screenName, screenshotPath);
        Logger.i("LWEController", "Wallpaper screenshot generated and applied for active color monitor", "path=", requestPath, "screen=", screenName, "screenshot=", screenshotPath);
        ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsApplied"), "palette");
        return;
      }

      Logger.i("LWEController", "Wallpaper screenshot cached for color extraction", "path=", requestPath, "screen=", screenName, "screenshot=", screenshotPath);
      ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsCached"), "palette");
    }
  }

  Process {
    id: reusedWallpaperColorCheckProcess
    running: false

    onExited: function (exitCode) {
      const request = root.pendingWallpaperColorReuseRequest;
      root.pendingWallpaperColorReuseRequest = null;
      if (!request) {
        return;
      }

      if (exitCode === 0) {
        Logger.i("LWEController", "Reusing cached wallpaper color screenshot", "path=", request.wallpaperPath, "screen=", request.screenName, "scaling=", request.scaling, "screenshot=", request.screenshotPath);

        if (root.wallpaperColorsEnabled && request.screenName === root.activeColorMonitor) {
          root.applyWallpaperColorsFromScreenshot(request.screenName, request.screenshotPath);
          ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsApplied"), "palette");
        } else {
          ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("toast.wallpaperColorsCached"), "palette");
        }
        return;
      }

      Logger.w("LWEController", "Cached wallpaper color screenshot missing; regenerating", "path=", request.wallpaperPath, "screen=", request.screenName, "scaling=", request.scaling, "screenshot=", request.screenshotPath);
      root.startWallpaperColorCapture(request.wallpaperPath, request.screenName, request.scaling);
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Process {
    id: cachedWallpaperColorSyncCheckProcess
    running: false

    onExited: function (exitCode) {
      const screenshotPath = root.pendingCachedWallpaperColorPath;
      const screenName = root.pendingCachedWallpaperColorScreenName;

      if (exitCode !== 0 || screenshotPath.length === 0) {
        Logger.w("LWEController", "Cached wallpaper color screenshot missing for active monitor", "screen=", screenName, "path=", screenshotPath, "exitCode=", exitCode);
        root.pendingCachedWallpaperColorPath = "";
        root.pendingCachedWallpaperColorScreenName = "";
        return;
      }

      cachedWallpaperColorSyncTimer.restart();
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  Timer {
    id: wallpaperColorStartTimer
    interval: 1500

    onTriggered: {
      const request = root.pendingWallpaperColorRequest;
      root.pendingWallpaperColorRequest = null;
      if (!request || String(request.path || "").length === 0) {
        return;
      }
      root.applyWallpaperColorsFromPath(request.path, request);
    }
  }

  Timer {
    id: cachedWallpaperColorSyncTimer
    interval: 250

    onTriggered: {
      const screenshotPath = root.pendingCachedWallpaperColorPath;
      const screenName = root.pendingCachedWallpaperColorScreenName;
      root.pendingCachedWallpaperColorPath = "";
      root.pendingCachedWallpaperColorScreenName = "";
      if (screenshotPath.length === 0 || !root.wallpaperColorsEnabled) {
        return;
      }
      Logger.i("LWEController", "Applying cached wallpaper colors for active monitor", "screen=", screenName || root.activeColorMonitor, "path=", screenshotPath);
      root.applyWallpaperColorsFromScreenshot(screenName || root.activeColorMonitor, screenshotPath);
    }
  }

  IpcHandler {
    target: "plugin:linux-wallpaperengine-controller"

    function toggle() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
          root.pluginApi.togglePanel(screen);
        });
      }
    }

    function apply(screenName: string, bgPath: string) {
      if (!screenName || !bgPath) {
        Logger.w("LWEController", "IPC apply ignored due to invalid args", screenName, bgPath);
        return;
      }

      Logger.i("LWEController", "IPC apply", screenName, bgPath);

      root.setScreenWallpaper(screenName, bgPath);
    }

    function stop(screenName: string) {
      if (!screenName || screenName === "all") {
        Logger.i("LWEController", "IPC stop all");
        root.stopAll();
        return;
      }

      Logger.i("LWEController", "IPC stop screen", screenName);

      root.clearScreenWallpaper(screenName);
    }

    function reload() {
      root.reload();
    }

    function refreshWallpapers() {
      root.refreshWallpaperCache(true, true);
    }
  }

  Connections {
    target: Quickshell

    function onScreensChanged() {
      root.handleScreenTopologyChanged();
    }
  }

  onActiveColorMonitorChanged: scheduleCachedWallpaperColorsForMonitor("monitor-changed")
  onWallpaperColorsEnabledChanged: scheduleCachedWallpaperColorsForMonitor("wallpaper-colors-toggled")
  onWallpaperColorDarkModeChanged: scheduleCachedWallpaperColorsForMonitor("dark-mode-changed")
  onWallpaperColorGenerationMethodChanged: scheduleCachedWallpaperColorsForMonitor("generation-method-changed")

  Timer {
    id: stableRunTimer
    interval: 2500
    repeat: false

    onTriggered: {
      if (!engineProcess.running || stopRequested) {
        return;
      }

      if (saveCurrentLayoutAsLastKnownGood("stable-run")) {
        recoveryInProgress = false;
      }
    }
  }

  Timer {
    id: screenTopologyRestartDebounce
    interval: 800
    repeat: false

    onTriggered: {
      if (!root.engineAvailable) {
        return;
      }

      if (!root.hasAnyConfiguredWallpaper()) {
        return;
      }

      Logger.i("LWEController", "Reapplying wallpapers after screen topology change");
      root.restartEngine();
    }
  }
}
