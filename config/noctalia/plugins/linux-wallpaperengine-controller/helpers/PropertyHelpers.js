.pragma library

function stripHtml(rawText) {
  return String(rawText || "")
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;?/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/\s+/g, " ")
    .trim();
}

function normalizePropertyLabel(value, translatePropertyLabelKey) {
  const raw = String(value || "").trim();
  if (raw.length === 0) {
    return "";
  }

  const looksLikeKey = /^[a-z0-9_]+$/i.test(raw) && raw.indexOf("_") >= 0;
  if (!looksLikeKey) {
    return raw;
  }

  const normalizedKey = raw
    .replace(/^ui_browse_properties_/i, "")
    .replace(/^ui_/i, "")
    .replace(/^properties_/i, "");

  if (normalizedKey.toLowerCase() === "scheme_color" && translatePropertyLabelKey) {
    return translatePropertyLabelKey("panel.propertyLabelThemeColor");
  }

  return normalizedKey
    .split("_")
    .filter(part => part.length > 0)
    .map(part => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

function cleanedPropertyLabel(rawText, fallbackKey, translatePropertyLabelKey) {
  const stripped = stripHtml(rawText)
    .replace(/^[\-–—•·*_#\s]+/, "")
    .replace(/^[^\p{L}\p{N}]+/u, "")
    .trim();
  if (stripped.length > 0) {
    return normalizePropertyLabel(stripped, translatePropertyLabelKey);
  }
  return normalizePropertyLabel(String(fallbackKey || ""), translatePropertyLabelKey);
}

function isNoisePropertyKey(value) {
  const key = String(value || "").toLowerCase().trim();
  if (key.length === 0) {
    return true;
  }
  return key.indexOf("imgsrc") === 0
    || key.indexOf("brahref") === 0
    || key.indexOf("centerbrahref") === 0
    || key.indexOf("bigweixin") === 0
    || key.indexOf("viewer_4") >= 0
    || key.indexOf("photogz") >= 0
    || key.indexOf("mqpic") >= 0
    || key.indexOf("width") >= 0 && key.indexOf("height") >= 0;
}

function isNoisePropertyLabel(value) {
  const label = String(value || "").toLowerCase().trim();
  if (label.length === 0) {
    return true;
  }
  return label.indexOf("imgsrc") >= 0
    || label.indexOf("photogz") >= 0
    || label.indexOf("mqpic") >= 0
    || label.indexOf("viewer_4") >= 0;
}

function comboChoicesFor(definition) {
  const rawChoices = definition && definition.choices || [];
  const normalized = [];
  for (let i = 0; i < rawChoices.length; i++) {
    const choice = rawChoices[i];
    const key = String(choice && (choice.key ?? choice.value) || "").trim();
    const name = String(choice && (choice.name ?? choice.label ?? choice.text) || key).trim();
    if (key.length === 0) {
      continue;
    }
    normalized.push({ key: key, name: name.length > 0 ? name : key });
  }
  return normalized;
}

function numberOr(value, fallback) {
  const parsed = Number(value);
  return isNaN(parsed) ? fallback : parsed;
}

function formatSliderValue(value, step) {
  const numericValue = numberOr(value, 0);
  const numericStep = Math.max(numberOr(step, 1), 0.001);
  let decimals = 0;
  if (numericStep < 1) {
    const stepText = String(numericStep);
    if (stepText.indexOf("e-") >= 0) {
      decimals = Number(stepText.split("e-")[1]) || 0;
    } else if (stepText.indexOf(".") >= 0) {
      decimals = stepText.split(".")[1].length;
    }
  }
  return numericValue.toFixed(Math.min(decimals, 6));
}

function parsePropertyValue(rawValue, type, createColor) {
  const trimmed = String(rawValue || "").trim();
  if (type === "boolean") {
    return trimmed === "1";
  }
  if (type === "slider") {
    const parsed = Number(trimmed);
    return isNaN(parsed) ? 0 : parsed;
  }
  if (type === "combo") {
    return String(trimmed);
  }
  if (type === "textinput") {
    return trimmed.replace(/^"|"$/g, "");
  }
  if (type === "color") {
    const parts = trimmed.split(",").map(part => Number(String(part).trim()));
    if (parts.length >= 3 && parts.every(part => !isNaN(part))) {
      const maxChannel = Math.max(parts[0], parts[1], parts[2]);
      if (createColor) {
        if (maxChannel > 1) {
          return createColor(parts[0] / 255, parts[1] / 255, parts[2] / 255, 1);
        }
        return createColor(parts[0], parts[1], parts[2], 1);
      }
    }
    return createColor ? createColor(1, 1, 1, 1) : trimmed;
  }
  return trimmed;
}

function serializePropertyValue(value, type) {
  if (type === "boolean") {
    return value ? "1" : "0";
  }
  if (type === "slider") {
    return String(value);
  }
  if (type === "combo") {
    return String(value);
  }
  if (type === "textinput") {
    return String(value);
  }
  if (type === "color") {
    const color = value;
    const r = Math.round((color && color.r !== undefined ? color.r : 1) * 255);
    const g = Math.round((color && color.g !== undefined ? color.g : 1) * 255);
    const b = Math.round((color && color.b !== undefined ? color.b : 1) * 255);
    return String(r) + "," + String(g) + "," + String(b);
  }
  return String(value);
}

function ensureColorValue(value, parseColorValue, createColor) {
  if (value === undefined || value === null || value === "") {
    return createColor ? createColor(1, 1, 1, 1) : value;
  }
  if (typeof value === "string") {
    return parseColorValue ? parseColorValue(value, "color") : value;
  }
  if (value.r !== undefined && value.g !== undefined && value.b !== undefined) {
    return createColor ? createColor(value.r, value.g, value.b, value.a !== undefined ? value.a : 1) : value;
  }
  return createColor ? createColor(1, 1, 1, 1) : value;
}
