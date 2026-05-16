import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io

import qs.Commons
import qs.Services.UI
import qs.Widgets

import "components"
import "helpers/WallpaperMetaHelpers.js" as WallpaperMetaHelpers
import "helpers/PropertyHelpers.js" as PropertyHelpers

Item {
  id: root

  // Core plugin and settings access.
  property var pluginApi: null

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property var geometryPlaceholder: panelContainer

  property real contentPreferredWidth: 1480 * Style.uiScaleRatio
  property real contentPreferredHeight: 860 * Style.uiScaleRatio

  readonly property bool allowAttach: true
  readonly property bool panelAnchorHorizontalCenter: false
  readonly property bool panelAnchorVerticalCenter: false

  // Panel state and current selection.
  readonly property string wallpapersFolder: cfg.wallpapersFolder ?? defaults.wallpapersFolder ?? ""
  readonly property string resolvedWallpapersFolder: Settings.preprocessPath(wallpapersFolder)
  property string selectedScreenName: pluginApi?.panelOpenScreen?.name ?? ""
  property string selectedPath: ""
  property string pendingPath: ""
  property string selectedScaling: "fill"
  property string selectedClamp: "clamp"
  property int selectedVolume: 100
  property bool selectedMuted: true
  property bool selectedAudioReactiveEffects: true
  property bool selectedDisableMouse: false
  property bool selectedDisableParallax: false
  property bool applyWallpaperColorsOnApply: cfg.applyWallpaperColorsOnApply ?? defaults.applyWallpaperColorsOnApply ?? false
  readonly property bool applyingWallpaperColors: mainInstance?.applyingWallpaperColors ?? false
  readonly property bool scanningWallpapers: mainInstance?.scanningWallpapers ?? false
  property bool loadingWallpaperProperties: false
  property bool scanningCompatibility: false
  property bool pendingCompatibilityScan: false
  readonly property bool folderAccessible: mainInstance?.wallpapersFolderAccessible ?? true

  property string searchText: ""
  property string selectedType: "all"
  property string selectedResolution: "all"
  property string sortMode: "name"
  property bool sortAscending: true
  property int currentPage: 0
  property int pageSize: 24
  readonly property bool singleScreenMode: Quickshell.screens.length <= 1
  property bool applyAllDisplays: !singleScreenMode && root._applyAllDisplays
  property bool _applyAllDisplays: true
  property bool applyTargetExpanded: false
  property bool filterDropdownOpen: false
  property bool resolutionDropdownOpen: false
  property bool sortDropdownOpen: false
  property bool errorDetailsExpanded: false
  property real filterDropdownX: 0
  property real filterDropdownY: 0
  property real filterDropdownWidth: 220 * Style.uiScaleRatio
  property real resolutionDropdownX: 0
  property real resolutionDropdownY: 0
  property real resolutionDropdownWidth: 220 * Style.uiScaleRatio
  property real sortDropdownX: 0
  property real sortDropdownY: 0
  property real sortDropdownWidth: 220 * Style.uiScaleRatio

  // Data models and derived UI state.
  property var screenModel: []
  readonly property var wallpaperItems: mainInstance?.cachedWallpaperItems || []
  property var visibleWallpapers: []
  property var pagedWallpapers: []
  property var wallpaperPropertyLoadFailedByPath: ({})
  property var wallpaperPropertyDefinitions: []
  property var wallpaperPropertyValues: ({})
  property string wallpaperPropertyError: ""
  property string wallpaperPropertyRequestPath: ""
  readonly property bool extraPropertiesEditorEnabled: cfg.enableExtraPropertiesEditor ?? defaults.enableExtraPropertiesEditor ?? true
  readonly property string engineStatusBadgeText: {
    if (mainInstance?.checkingEngine ?? false) {
      return pluginApi?.tr("panel.statusChecking");
    }
    if (!(mainInstance?.engineAvailable ?? false)) {
      return pluginApi?.tr("panel.statusUnavailable");
    }
    if (mainInstance?.engineRunning ?? false) {
      return pluginApi?.tr("panel.statusRunning");
    }
    if (mainInstance?.hasAnyConfiguredWallpaper && mainInstance.hasAnyConfiguredWallpaper()) {
      return pluginApi?.tr("panel.statusReady");
    }
    return pluginApi?.tr("panel.statusStopped");
  }
  readonly property color engineStatusBadgeFg: {
    if (mainInstance?.checkingEngine ?? false) {
      return Color.mSecondary;
    }
    if (!(mainInstance?.engineAvailable ?? false)) {
      return Color.mError;
    }
    if (mainInstance?.engineRunning ?? false) {
      return Color.mPrimary;
    }
    if (mainInstance?.hasAnyConfiguredWallpaper && mainInstance.hasAnyConfiguredWallpaper()) {
      return Color.mTertiary;
    }
    return Color.mOnSurfaceVariant;
  }
  readonly property color engineStatusBadgeBg: Qt.alpha(engineStatusBadgeFg, 0.16)
  readonly property int pageCount: Math.max(1, Math.ceil(visibleWallpapers.length / Math.max(pageSize, 1)))
  readonly property bool paginationVisible: visibleWallpapers.length > pageSize
  readonly property int currentPageDisplay: visibleWallpapers.length === 0 ? 0 : currentPage + 1
  readonly property int currentPageStartIndex: visibleWallpapers.length === 0 ? 0 : currentPage * pageSize + 1
  readonly property int currentPageEndIndex: Math.min((currentPage + 1) * pageSize, visibleWallpapers.length)
  readonly property var selectedWallpaperData: {
    const target = String(pendingPath || "");
    if (target.length === 0) {
      return null;
    }
    for (const item of wallpaperItems) {
      if (String(item.path || "") === target) {
        return item;
      }
    }
    return null;
  }

  // Basic file and metadata helpers.
  function basename(path) {
    return WallpaperMetaHelpers.basename(path);
  }

  function workshopUrlForWallpaper(item) {
    return WallpaperMetaHelpers.workshopUrlForWallpaper(item);
  }

  function fileExt(path) {
    return WallpaperMetaHelpers.fileExt(path);
  }

  function isVideoMotion(path) {
    return WallpaperMetaHelpers.isVideoMotion(path);
  }

  function typeLabel(value) {
    const key = String(value || "all").toLowerCase();
    if (key === "scene") return pluginApi?.tr("panel.typeScene");
    if (key === "video") return pluginApi?.tr("panel.typeVideo");
    if (key === "web") return pluginApi?.tr("panel.typeWeb");
    if (key === "application") return pluginApi?.tr("panel.typeApplication");
    return pluginApi?.tr("panel.filterAll");
  }

  function formatBytes(bytesValue) {
    return WallpaperMetaHelpers.formatBytes(bytesValue);
  }

  function sortLabel(value) {
    if (value === "date") return pluginApi?.tr("panel.sortDateAdded");
    if (value === "size") return pluginApi?.tr("panel.sortSize");
    if (value === "recent") return pluginApi?.tr("panel.sortRecent");
    return pluginApi?.tr("panel.sortName");
  }

  // Resolution helpers for badges and filtering.
  function resolutionBadgeIcon(value) {
    return WallpaperMetaHelpers.resolutionBadgeIcon(value);
  }

  function resolutionBadgeLabel(value) {
    return WallpaperMetaHelpers.resolutionBadgeLabel(value);
  }

  function resolutionFilterKey(value) {
    return WallpaperMetaHelpers.resolutionFilterKey(value);
  }

  function resolutionFilterLabel(value) {
    if (value === "8k") return pluginApi?.tr("panel.filterRes8k");
    if (value === "4k") return pluginApi?.tr("panel.filterRes4k");
    if (value === "unknown") return pluginApi?.tr("panel.filterResUnknown");
    return pluginApi?.tr("panel.filterResAll");
  }

  // Extra property parsing and normalization helpers.
  function stripHtml(rawText) {
    return PropertyHelpers.stripHtml(rawText);
  }

  function cleanedPropertyLabel(rawText, fallbackKey) {
    return PropertyHelpers.cleanedPropertyLabel(rawText, fallbackKey, key => pluginApi?.tr(key));
  }

  function normalizePropertyLabel(value) {
    return PropertyHelpers.normalizePropertyLabel(value, key => pluginApi?.tr(key));
  }

  function isNoisePropertyKey(value) {
    return PropertyHelpers.isNoisePropertyKey(value);
  }

  function isNoisePropertyLabel(value) {
    return PropertyHelpers.isNoisePropertyLabel(value);
  }

  function parsePropertyValue(rawValue, type) {
    return PropertyHelpers.parsePropertyValue(rawValue, type, (r, g, b, a) => Qt.rgba(r, g, b, a));
  }

  function serializePropertyValue(value, type) {
    return PropertyHelpers.serializePropertyValue(value, type);
  }

  // Extra property value accessors.
  function propertyValueFor(definition) {
    const key = String(definition?.key || "");
    if (key.length === 0) {
      return "";
    }
    const raw = wallpaperPropertyValues || ({});
    if (raw[key] !== undefined) {
      return raw[key];
    }
    return definition.defaultValue;
  }

  function comboChoicesFor(definition) {
    return PropertyHelpers.comboChoicesFor(definition);
  }

  function ensureColorValue(value) {
    return PropertyHelpers.ensureColorValue(
      value,
      (rawValue, type) => parsePropertyValue(rawValue, type),
      (r, g, b, a) => Qt.rgba(r, g, b, a)
    );
  }

  function numberOr(value, fallback) {
    return PropertyHelpers.numberOr(value, fallback);
  }

  function formatSliderValue(value, step) {
    return PropertyHelpers.formatSliderValue(value, step);
  }

  function setPropertyValue(key, value) {
    const current = wallpaperPropertyValues || ({});
    const next = Object.assign({}, current);
    next[String(key)] = value;
    wallpaperPropertyValues = next;
  }

  // Property loading and compatibility scan actions.
  function parseWallpaperPropertiesOutput(rawText) {
    const lines = String(rawText || "").split(/\r?\n/);
    const definitions = [];
    let current = null;
    let parsingValues = false;

    function commitCurrent() {
      if (!current) {
        return;
      }
      if (["boolean", "slider", "combo", "textinput", "color", "text"].indexOf(current.type) === -1) {
        current = null;
        parsingValues = false;
        return;
      }
      current.label = cleanedPropertyLabel(current.label, current.key);
      if (current.type === "text") {
        if (current.label.length === 0 || isNoisePropertyLabel(current.label)) {
          current = null;
          parsingValues = false;
          return;
        }
        definitions.push({
          key: current.key,
          type: "text",
          label: current.label,
          defaultValue: ""
        });
        current = null;
        parsingValues = false;
        return;
      }
      if (isNoisePropertyKey(current.key) || isNoisePropertyLabel(current.label)) {
        current = null;
        parsingValues = false;
        return;
      }
      definitions.push(current);
      current = null;
      parsingValues = false;
    }

    for (const rawLine of lines) {
      const line = String(rawLine || "");
      const trimmed = line.trim();
      if (trimmed.length === 0) {
        commitCurrent();
        continue;
      }

      if (trimmed.indexOf("Unknown object type found:") === 0
          || trimmed.indexOf("ScriptEngine [evaluate]:") === 0
          || trimmed.indexOf("Text objects are not supported yet") === 0
          || trimmed.indexOf("Applying override value for ") === 0) {
        continue;
      }

      const headerMatch = trimmed.match(/^([^\s].*?)\s+-\s+(slider|boolean|combo|textinput|color|text|scene texture)$/i);
      if (headerMatch) {
        commitCurrent();
        current = {
          key: headerMatch[1].trim(),
          type: headerMatch[2].toLowerCase(),
          label: undefined,
          min: undefined,
          max: undefined,
          step: undefined,
          defaultValue: "",
          choices: []
        };
        parsingValues = false;
        continue;
      }

      if (!current) {
        continue;
      }

      if (trimmed.indexOf("Text:") === 0) {
        current.label = trimmed.substring(5).trim();
        parsingValues = false;
        continue;
      }
      if (trimmed.indexOf("Min:") === 0) {
        const parsed = Number(trimmed.substring(4).trim());
        current.min = isNaN(parsed) ? undefined : parsed;
        parsingValues = false;
        continue;
      }
      if (trimmed.indexOf("Max:") === 0) {
        const parsed = Number(trimmed.substring(4).trim());
        current.max = isNaN(parsed) ? undefined : parsed;
        parsingValues = false;
        continue;
      }
      if (trimmed.indexOf("Step:") === 0) {
        const parsed = Number(trimmed.substring(5).trim());
        current.step = isNaN(parsed) ? undefined : parsed;
        parsingValues = false;
        continue;
      }
      if (trimmed.indexOf("Value:") === 0) {
        current.defaultValue = parsePropertyValue(trimmed.substring(6).trim(), current.type);
        parsingValues = false;
        continue;
      }
      if (trimmed === "Values:") {
        parsingValues = true;
        continue;
      }

      if (parsingValues && current.type === "combo") {
        const valueMatch = trimmed.match(/^(.*?)\s*=\s*(.*)$/);
        if (valueMatch) {
          const choiceKey = valueMatch[1].trim();
          const choiceName = valueMatch[2].trim();
          current.choices.push({
            key: choiceKey,
            name: choiceName,
            label: choiceName,
            value: choiceKey,
            text: choiceName
          });
        }
      }
    }

    commitCurrent();
    return definitions;
  }

  function loadWallpaperProperties(path) {
    const wallpaperPath = String(path || "").trim();
    wallpaperPropertyDefinitions = [];
    wallpaperPropertyValues = ({});
    wallpaperPropertyError = "";
    wallpaperPropertyRequestPath = wallpaperPath;

    if (!extraPropertiesEditorEnabled || wallpaperPath.length === 0 || !(mainInstance?.engineAvailable ?? false)) {
      loadingWallpaperProperties = false;
      return;
    }

    loadingWallpaperProperties = true;
    wallpaperPropertyProcess.command = ["linux-wallpaperengine", wallpaperPath, "--list-properties"];
    wallpaperPropertyProcess.running = true;
  }

  function setWallpaperPropertyLoadFailed(path, failed) {
    const wallpaperPath = String(path || "").trim();
    if (wallpaperPath.length === 0) {
      return;
    }

    const nextState = Object.assign({}, wallpaperPropertyLoadFailedByPath);
    if (failed) {
      nextState[wallpaperPath] = true;
    } else {
      delete nextState[wallpaperPath];
    }
    wallpaperPropertyLoadFailedByPath = nextState;
  }

  function startCompatibilityScan() {
    const folderPath = String(resolvedWallpapersFolder || "").trim();
    if (folderPath.length === 0 || !(mainInstance?.engineAvailable ?? false)) {
      pendingCompatibilityScan = false;
      return;
    }

    const pluginDir = pluginApi?.pluginDir || "";
    const scriptPath = pluginDir + "/scripts/scan-properties-compatibility.sh";

    pendingCompatibilityScan = false;
    scanningCompatibility = true;
    compatibilityScanProcess.command = ["bash", scriptPath, folderPath];
    compatibilityScanProcess.running = true;
  }

  function applyCompatibilityScanOutput(rawText) {
    const nextState = {};
    const lines = String(rawText || "").split(/\r?\n/);
    let totalCount = 0;

    for (const rawLine of lines) {
      const line = String(rawLine || "").trim();
      if (line.length === 0) {
        continue;
      }

      const parts = line.split("\t");
      const path = String(parts[0] || "").trim();
      const failed = String(parts[1] || "0").trim() === "1";
      if (path.length === 0) {
        continue;
      }

      totalCount += 1;

      if (failed) {
        nextState[path] = true;
      }
    }

    wallpaperPropertyLoadFailedByPath = nextState;
    return {
      totalCount: totalCount,
      failedCount: Object.keys(nextState).length
    };
  }

  // Dropdown state helpers.
  function closeDropdowns() {
    filterDropdownOpen = false;
    resolutionDropdownOpen = false;
    sortDropdownOpen = false;
  }

  function openFilterDropdown(x, y, width) {
    filterDropdownX = x;
    filterDropdownY = y;
    filterDropdownWidth = width;
    resolutionDropdownOpen = false;
    sortDropdownOpen = false;
    filterDropdownOpen = true;
  }

  function openSortDropdown(x, y, width) {
    sortDropdownX = x;
    sortDropdownY = y;
    sortDropdownWidth = width;
    filterDropdownOpen = false;
    resolutionDropdownOpen = false;
    sortDropdownOpen = true;
  }

  function openResolutionDropdown(x, y, width) {
    resolutionDropdownX = x;
    resolutionDropdownY = y;
    resolutionDropdownWidth = width;
    filterDropdownOpen = false;
    sortDropdownOpen = false;
    resolutionDropdownOpen = true;
  }

  function applyFilterAction(action) {
    if (String(action).indexOf("type:") === 0) {
      selectedType = String(action).substring(5);
    }
    closeDropdowns();
  }

  function applyResolutionFilterAction(action) {
    if (String(action).indexOf("res:") === 0) {
      selectedResolution = String(action).substring(4);
    }
    closeDropdowns();
  }

  function applySortAction(action) {
    if (action === "sort:toggleAscending") {
      sortAscending = !sortAscending;
    } else if (String(action).indexOf("sort:") === 0) {
      sortMode = String(action).substring(5);
    }
    closeDropdowns();
  }

  // Panel memory and selection synchronization.
  function loadPanelMemory() {
    if (!pluginApi) {
      return;
    }

    const remembered = String(pluginApi?.pluginSettings?.panelLastSelectedPath || "").trim();
    if (remembered.length > 0) {
      pendingPath = remembered;
    }
  }

  function persistPanelMemory(flushToDisk = false) {
    if (!pluginApi) {
      return;
    }

    const current = String(pluginApi?.pluginSettings?.panelLastSelectedPath || "");
    const next = String(pendingPath || "");
    if (current === next) {
      return;
    }

    pluginApi.pluginSettings.panelLastSelectedPath = next;
    if (flushToDisk) {
      pluginApi.saveSettings();
    }
  }

  function resetPendingToGlobalDefaults() {
    selectedScaling = String(defaults.defaultScaling || "fill");
    syncGlobalRuntimeOptions();
  }

  function syncGlobalRuntimeOptions() {
    selectedClamp = String(cfg.defaultClamp ?? defaults.defaultClamp ?? "clamp");
    selectedVolume = Math.max(0, Math.min(100, Number(cfg.defaultVolume ?? defaults.defaultVolume ?? 100)));
    selectedMuted = !!(cfg.defaultMuted ?? defaults.defaultMuted ?? true);
    selectedAudioReactiveEffects = !!(cfg.defaultAudioReactiveEffects ?? defaults.defaultAudioReactiveEffects ?? true);
    selectedDisableMouse = !!(cfg.defaultDisableMouse ?? defaults.defaultDisableMouse ?? false);
    selectedDisableParallax = !!(cfg.defaultDisableParallax ?? defaults.defaultDisableParallax ?? false);
  }

  function syncSelectionOptionsFromScreen() {
    syncGlobalRuntimeOptions();

    const fallbackScreenName = root.singleScreenMode ? (Quickshell.screens[0]?.name || selectedScreenName) : selectedScreenName;
    if (root.singleScreenMode && selectedScreenName.length === 0 && fallbackScreenName.length > 0) {
      selectedScreenName = fallbackScreenName;
    }

    const screenCfg = mainInstance?.getScreenConfig(fallbackScreenName);
    if (!screenCfg) {
      selectedScaling = String(defaults.defaultScaling || "fill");
      return;
    }

    selectedScaling = String(screenCfg.scaling || defaults.defaultScaling || "fill");
  }

  // Wallpaper application and list state refresh.
  function applyPendingSelection() {
    const path = String(pendingPath || "").trim();
    if (path.length === 0) {
      return;
    }

    const configuredColorScreen = String(Settings.data.colorSchemes.monitorForColors || "").trim();
    const colorApplyScreen = applyAllDisplays
      ? (configuredColorScreen || Quickshell.screens[0]?.name || "")
      : (root.singleScreenMode ? (Quickshell.screens[0]?.name || "") : (selectedScreenName || Quickshell.screens[0]?.name || ""));
    const colorApplyOptions = {
      "screenName": colorApplyScreen,
      "scaling": selectedScaling
    };

    const options = { "scaling": selectedScaling, "clamp": selectedClamp };
    options.volume = selectedVolume;
    options.muted = selectedMuted;
    options.audioReactiveEffects = selectedAudioReactiveEffects;
    options.noAutomute = !!(cfg.defaultNoAutomute ?? defaults.defaultNoAutomute ?? false);
    options.disableMouse = selectedDisableMouse;
    options.disableParallax = selectedDisableParallax;
    const customProperties = {};
    for (const definition of wallpaperPropertyDefinitions) {
      const propertyKey = String(definition?.key || "");
      if (propertyKey.length === 0) {
        continue;
      }
      customProperties[propertyKey] = serializePropertyValue(propertyValueFor(definition), definition.type);
    }
    options.customProperties = customProperties;
    selectedPath = path;

    if (applyAllDisplays) {
      Logger.i("LWEController", "Confirm apply to all displays", path, JSON.stringify(options));
      mainInstance?.setAllScreensWallpaperWithOptions(path, options);
      if (applyWallpaperColorsOnApply) {
        mainInstance?.scheduleWallpaperColorsFromPath(path, colorApplyOptions);
      }
      pendingPath = "";
      return;
    }

    if (!root.singleScreenMode && selectedScreenName.length === 0) {
      Logger.w("LWEController", "Confirm apply skipped due to empty selected screen", path);
      return;
    }

    const targetScreen = root.singleScreenMode ? (Quickshell.screens[0]?.name || "") : selectedScreenName;
    Logger.i("LWEController", "Confirm apply to screen", targetScreen, path, JSON.stringify(options));
    mainInstance?.setScreenWallpaperWithOptions(targetScreen, path, options);
    if (applyWallpaperColorsOnApply) {
      mainInstance?.scheduleWallpaperColorsFromPath(path, colorApplyOptions);
    }
    pendingPath = "";
  }

  function refreshVisibleWallpapers() {
    const query = String(searchText || "").trim().toLowerCase();
    let items = wallpaperItems.slice();

    if (selectedType !== "all") {
      items = items.filter(item => String(item.type || "unknown").toLowerCase() === selectedType);
    }

    if (selectedResolution !== "all") {
      items = items.filter(item => resolutionFilterKey(item.resolution) === selectedResolution);
    }

    if (query.length > 0) {
      items = items.filter(item => {
        return String(item.name || "").toLowerCase().indexOf(query) >= 0
          || String(item.id || "").toLowerCase().indexOf(query) >= 0;
      });
    }

    if (sortMode === "date") {
      items.sort((a, b) => Number(a.mtime || 0) - Number(b.mtime || 0));
    } else if (sortMode === "size") {
      items.sort((a, b) => Number(a.bytes || 0) - Number(b.bytes || 0));
    } else if (sortMode === "recent") {
      items.sort((a, b) => Number(b.mtime || 0) - Number(a.mtime || 0));
    } else {
      items.sort((a, b) => String(a.name || "").localeCompare(String(b.name || "")));
    }

    if (!sortAscending) {
      items.reverse();
    }

    visibleWallpapers = items;
    Logger.d("LWEController", "Visible wallpapers refreshed", "count=", visibleWallpapers.length, "type=", selectedType, "resolution=", selectedResolution, "sort=", sortMode, "ascending=", sortAscending, "query=", query);
  }

  function refreshPagedWallpapers() {
    const safePageSize = Math.max(1, Number(pageSize) || 1);
    const totalPages = Math.max(1, Math.ceil(visibleWallpapers.length / safePageSize));
    const nextPage = Math.max(0, Math.min(currentPage, totalPages - 1));

    if (nextPage !== currentPage) {
      currentPage = nextPage;
      return;
    }

    const startIndex = nextPage * safePageSize;
    pagedWallpapers = visibleWallpapers.slice(startIndex, startIndex + safePageSize);
  }

  function resetPagination() {
    if (currentPage !== 0) {
      currentPage = 0;
      return;
    }

    refreshPagedWallpapers();
  }

  function goToPreviousPage() {
    if (currentPage > 0) {
      currentPage -= 1;
    }
  }

  function goToNextPage() {
    if (currentPage < pageCount - 1) {
      currentPage += 1;
    }
  }

  function reconcilePendingSelection() {
    const current = String(pendingPath || "");
    if (current.length === 0) {
      return;
    }

    let exists = false;
    for (const item of wallpaperItems) {
      if (String(item.path || "") === current) {
        exists = true;
        break;
      }
    }

    if (!exists) {
      pendingPath = "";
    }
  }

  function refreshWallpaperList(force = false) {
    mainInstance?.refreshWallpaperCache(force, true);
  }

  function rebuildScreenModel() {
    const model = [];
    for (const screen of Quickshell.screens) {
      model.push({ key: screen.name, name: screen.name });
    }

    screenModel = model;

    if (!root.singleScreenMode && selectedScreenName.length === 0 && model.length > 0) {
      selectedScreenName = model[0].key;
    }
  }

  function applyPath(path) {
    if (!path || path.length === 0) {
      Logger.w("LWEController", "Apply skipped due to invalid path", path);
      return;
    }
    pendingPath = path;
  }

  // Reactive state updates.
  onWallpaperItemsChanged: {
    refreshVisibleWallpapers();
    reconcilePendingSelection();
  }
  onVisibleWallpapersChanged: refreshPagedWallpapers()
  onCurrentPageChanged: refreshPagedWallpapers()
  onPageSizeChanged: refreshPagedWallpapers()
  onSearchTextChanged: {
    refreshVisibleWallpapers();
    resetPagination();
  }
  onSelectedTypeChanged: {
    refreshVisibleWallpapers();
    resetPagination();
  }
  onSelectedResolutionChanged: {
    refreshVisibleWallpapers();
    resetPagination();
  }
  onSortModeChanged: {
    refreshVisibleWallpapers();
    resetPagination();
  }
  onSortAscendingChanged: {
    refreshVisibleWallpapers();
    resetPagination();
  }
  onSelectedScreenNameChanged: syncSelectionOptionsFromScreen()
  onPendingPathChanged: {
    persistPanelMemory();
    loadWallpaperProperties(pendingPath);
  }
  onWallpapersFolderChanged: {
    if (!root.pluginApi) {
      return;
    }
    mainInstance?.refreshWallpaperCache(true, false);
  }

  Component.onCompleted: {
    Logger.i("LWEController", "Panel opened", "screen=", selectedScreenName);
    rebuildScreenModel();
    loadPanelMemory();
    syncSelectionOptionsFromScreen();
    mainInstance?.refreshWallpaperCache(false, false);
    loadWallpaperProperties(pendingPath);
  }

  Component.onDestruction: {
    persistPanelMemory(true);
  }

  // Keep dropdowns aligned with panel width changes.
  onWidthChanged: {
    if (filterDropdownOpen) {
      openFilterDropdown(filterDropdownX, filterDropdownY, filterDropdownWidth);
    }
    if (resolutionDropdownOpen) {
      openResolutionDropdown(resolutionDropdownX, resolutionDropdownY, resolutionDropdownWidth);
    }
    if (sortDropdownOpen) {
      openSortDropdown(sortDropdownX, sortDropdownY, sortDropdownWidth);
    }
  }

  // Main instance state hooks.
  Connections {
    target: mainInstance

    function onLastErrorChanged() {
      root.errorDetailsExpanded = false;
    }
  }

  // Root layout and component composition.
  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      PanelHeader {
        pluginApi: root.pluginApi
        mainInstance: root.mainInstance
        positionTarget: root
        engineStatusBadgeText: root.engineStatusBadgeText
        engineStatusBadgeFg: root.engineStatusBadgeFg
        engineStatusBadgeBg: root.engineStatusBadgeBg
        scanningCompatibility: root.scanningCompatibility
        pendingCompatibilityScan: root.pendingCompatibilityScan
        searchText: root.searchText
        selectedType: root.selectedType
        selectedResolution: root.selectedResolution
        sortMode: root.sortMode
        sortAscending: root.sortAscending
        typeLabel: root.typeLabel
        resolutionFilterLabel: root.resolutionFilterLabel
        sortLabel: root.sortLabel
        resolutionButtonWidth: 172 * Style.uiScaleRatio
        filterButtonWidth: 172 * Style.uiScaleRatio
        sortButtonWidth: 172 * Style.uiScaleRatio
        onCompatibilityQuickCheckRequested: root.startCompatibilityScan()
        onReloadRequested: {
          root.refreshWallpaperList(true);
        }
        onToggleRunRequested: {
          if (mainInstance?.engineRunning) {
            mainInstance?.stopAll(true);
          } else {
            mainInstance?.reload(true);
          }
        }
        onSettingsRequested: {
          const screen = pluginApi?.panelOpenScreen;
          BarService.openPluginSettings(screen, pluginApi?.manifest);
          if (pluginApi) {
            pluginApi.togglePanel(screen);
          }
        }
        onCloseRequested: {
          const screen = pluginApi?.panelOpenScreen;
          if (pluginApi) {
            pluginApi.togglePanel(screen);
          }
        }
        onPendingCompatibilityScanRequested: value => root.pendingCompatibilityScan = value
        onSearchTextUpdateRequested: text => root.searchText = text
        onClearSearchRequested: root.searchText = ""
        onResolutionDropdownToggleRequested: (x, y, width) => {
          if (resolutionDropdownOpen) {
            root.closeDropdowns();
          } else {
            root.openResolutionDropdown(x, y, width);
          }
        }
        onFilterDropdownToggleRequested: (x, y, width) => {
          if (filterDropdownOpen) {
            root.closeDropdowns();
          } else {
            root.openFilterDropdown(x, y, width);
          }
        }
        onSortDropdownToggleRequested: (x, y, width) => {
          if (sortDropdownOpen) {
            root.closeDropdowns();
          } else {
            root.openSortDropdown(x, y, width);
          }
        }
      }

      RuntimeErrorBanner {
        pluginApi: root.pluginApi
        mainInstance: root.mainInstance
        errorDetailsExpanded: root.errorDetailsExpanded
        onErrorDetailsExpandedRequested: value => root.errorDetailsExpanded = value
        onDismissRequested: {
          if (mainInstance) {
            mainInstance.lastError = "";
            mainInstance.lastErrorDetails = "";
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Style.radiusL
        color: Qt.alpha(Color.mSurfaceVariant, 0.35)
        border.width: Style.borderS
        border.color: Qt.alpha(Color.mOutline, 0.35)

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Style.marginXS
            spacing: Style.marginM

            WallpaperGridSection {
              pluginApi: root.pluginApi
              mainInstance: root.mainInstance
              wallpapers: root.pagedWallpapers
              pendingPath: root.pendingPath
              selectedPath: root.selectedPath
              scanningWallpapers: root.scanningWallpapers
              wallpaperItemsCount: root.wallpaperItems.length
              visibleWallpaperCount: root.visibleWallpapers.length
              propertyLoadFailedByPath: root.wallpaperPropertyLoadFailedByPath
              currentPage: root.currentPage
              pageCount: root.pageCount
              currentPageDisplay: root.currentPageDisplay
              currentPageStartIndex: root.currentPageStartIndex
              currentPageEndIndex: root.currentPageEndIndex
              paginationVisible: root.paginationVisible
              resolutionBadgeIcon: root.resolutionBadgeIcon
              resolutionBadgeLabel: root.resolutionBadgeLabel
              typeLabel: root.typeLabel
              isVideoMotion: root.isVideoMotion
              onWallpaperActivated: path => root.applyPath(path)
              onPreviousPageRequested: root.goToPreviousPage()
              onNextPageRequested: root.goToNextPage()
            }

            WallpaperSidebar {
              pluginApi: root.pluginApi
              mainInstance: root.mainInstance
              selectedWallpaperData: root.selectedWallpaperData
              propertyLoadFailedByPath: root.wallpaperPropertyLoadFailedByPath
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
              resolutionBadgeIcon: root.resolutionBadgeIcon
              resolutionBadgeLabel: root.resolutionBadgeLabel
              typeLabel: root.typeLabel
              isVideoMotion: root.isVideoMotion
              formatBytes: root.formatBytes
              workshopUrlForWallpaper: root.workshopUrlForWallpaper
              propertyValueFor: root.propertyValueFor
              numberOr: root.numberOr
              formatSliderValue: root.formatSliderValue
              comboChoicesFor: root.comboChoicesFor
              ensureColorValue: root.ensureColorValue
              serializePropertyValue: root.serializePropertyValue
              setPropertyValue: root.setPropertyValue
              onApplyRequested: root.applyPendingSelection()
              onApplyAllDisplaysRequested: value => root._applyAllDisplays = value
              onApplyTargetExpandedRequested: value => root.applyTargetExpanded = value
              onSelectedScreenNameRequested: value => root.selectedScreenName = value
              onSelectedScalingRequested: value => root.selectedScaling = value
              onSelectedClampRequested: value => root.selectedClamp = value
              onSelectedVolumeRequested: value => root.selectedVolume = value
              onSelectedMutedRequested: value => root.selectedMuted = value
              onSelectedAudioReactiveEffectsRequested: value => root.selectedAudioReactiveEffects = value
              onSelectedDisableMouseRequested: value => root.selectedDisableMouse = value
              onSelectedDisableParallaxRequested: value => root.selectedDisableParallax = value
              onApplyWallpaperColorsOnApplyRequested: value => {
                root.applyWallpaperColorsOnApply = value;
                if (pluginApi) {
                  pluginApi.pluginSettings.applyWallpaperColorsOnApply = value;
                  pluginApi.saveSettings();
                }
              }
              onWorkshopLinkRequested: workshopUrl => {
                if (workshopUrl.length === 0) {
                  return;
                }

                const screen = pluginApi?.panelOpenScreen;
                if (pluginApi) {
                  pluginApi.togglePanel(screen);
                }
                Qt.openUrlExternally(workshopUrl);
              }
            }
          }

          NText {
            visible: !(mainInstance?.engineAvailable ?? false)
            text: pluginApi?.tr("panel.installHint")
            color: Color.mOnSurfaceVariant
            wrapMode: Text.Wrap
          }

          NText {
            visible: !root.folderAccessible
            text: pluginApi?.tr("panel.folderInvalid")
            color: Color.mError
            wrapMode: Text.WrapAnywhere
          }

          NText {
            visible: root.scanningWallpapers
            text: pluginApi?.tr("panel.scanning")
            color: Color.mOnSurfaceVariant
          }
        }
      }

    }

  }

  PanelDropdowns {
    pluginApi: root.pluginApi
    resolutionDropdownOpen: root.resolutionDropdownOpen
    filterDropdownOpen: root.filterDropdownOpen
    sortDropdownOpen: root.sortDropdownOpen
    selectedResolution: root.selectedResolution
    selectedType: root.selectedType
    sortMode: root.sortMode
    sortAscending: root.sortAscending
    resolutionDropdownX: root.resolutionDropdownX
    resolutionDropdownY: root.resolutionDropdownY
    resolutionDropdownWidth: root.resolutionDropdownWidth
    filterDropdownX: root.filterDropdownX
    filterDropdownY: root.filterDropdownY
    filterDropdownWidth: root.filterDropdownWidth
    sortDropdownX: root.sortDropdownX
    sortDropdownY: root.sortDropdownY
    sortDropdownWidth: root.sortDropdownWidth
    onCloseRequested: root.closeDropdowns()
    onResolutionActionTriggered: action => root.applyResolutionFilterAction(action)
    onFilterActionTriggered: action => root.applyFilterAction(action)
    onSortActionTriggered: action => root.applySortAction(action)
  }

  // Processes.
  Process {
    id: wallpaperPropertyProcess

    stdout: StdioCollector {
      id: wallpaperPropertyStdout
    }

    stderr: StdioCollector {
      id: wallpaperPropertyStderr
    }

    onExited: function(exitCode) {
      const requestPath = root.wallpaperPropertyRequestPath;
      root.loadingWallpaperProperties = false;

      const outputText = [String(wallpaperPropertyStdout.text || ""), String(wallpaperPropertyStderr.text || "")]
        .filter(part => part.trim().length > 0)
        .join("\n");

      if (requestPath.length === 0 || requestPath !== String(root.pendingPath || "")) {
        Logger.d("LWEController", "Ignoring stale wallpaper property result", "requestPath=", requestPath, "pendingPath=", root.pendingPath, "exitCode=", exitCode);
        return;
      }

      if (exitCode !== 0) {
        root.wallpaperPropertyDefinitions = [];
        root.wallpaperPropertyValues = ({});
        root.setWallpaperPropertyLoadFailed(requestPath, true);
        root.wallpaperPropertyError = pluginApi?.tr("panel.propertiesLoadFailed");
        Logger.w("LWEController", "Wallpaper properties load failed", "path=", requestPath, "exitCode=", exitCode, "stderr=", wallpaperPropertyStderr.text);
        return;
      }

      const definitions = root.parseWallpaperPropertiesOutput(outputText);
      root.setWallpaperPropertyLoadFailed(requestPath, false);
      root.wallpaperPropertyDefinitions = definitions;
      for (const definition of definitions) {
        if (definition.type === "combo") {
          Logger.d("LWEController", "Combo property parsed", "key=", definition.key, "choices=", JSON.stringify(root.comboChoicesFor(definition)));
        }
      }

      const savedProperties = mainInstance?.getWallpaperProperties(requestPath) || ({});
      const nextValues = {};
      for (const definition of definitions) {
        const propertyKey = String(definition.key || "");
        if (savedProperties[propertyKey] !== undefined) {
          nextValues[propertyKey] = root.parsePropertyValue(savedProperties[propertyKey], definition.type);
        } else {
          nextValues[propertyKey] = definition.defaultValue;
        }
      }
      root.wallpaperPropertyValues = nextValues;
      root.wallpaperPropertyError = "";
      Logger.i("LWEController", "Wallpaper properties loaded", "path=", requestPath, "count=", definitions.length);
    }
  }

  Process {
    id: compatibilityScanProcess

    stdout: StdioCollector {
      id: compatibilityScanStdout
    }

    stderr: StdioCollector {
      id: compatibilityScanStderr
    }

    onExited: function(exitCode) {
      root.scanningCompatibility = false;

      const stdoutText = String(compatibilityScanStdout.text || "");
      const stderrText = String(compatibilityScanStderr.text || "").trim();

      if (exitCode !== 0) {
        if (stderrText.length > 0) {
          Logger.w("LWEController", "Compatibility scan failed", "exitCode=", exitCode, "stderr=", stderrText);
        } else {
          Logger.w("LWEController", "Compatibility scan failed", "exitCode=", exitCode);
        }
        return;
      }

      const result = root.applyCompatibilityScanOutput(stdoutText);
      Logger.i("LWEController", "Compatibility scan completed", "totalCount=", result.totalCount, "failedCount=", result.failedCount);
      ToastService.showNotice(
        pluginApi?.tr("panel.title"),
        pluginApi?.tr("panel.compatibilityQuickCheckFinished", {
          total: result.totalCount,
          failed: result.failedCount
        }),
        result.failedCount > 0 ? "alert-triangle" : "check"
      );
    }
  }

}
