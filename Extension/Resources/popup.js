const GLOBAL_RULE_ID = 9999;
const SUPPORTED_RESOURCE_TYPES = [
    "main_frame", "sub_frame", "stylesheet", "script", "image",
    "font", "xmlhttprequest", "ping", "media", "websocket", "other"
];

// Localized string lookup. browser.i18n is always present in the extension;
// the fallback keeps things sane in non-extension contexts (e.g. previews).
function t(key, ...substitutions) {
    if (typeof browser !== "undefined" && browser.i18n && browser.i18n.getMessage) {
        const message = browser.i18n.getMessage(key, substitutions.length ? substitutions : undefined);
        if (message) {
            return message;
        }
    }
    return key;
}

function localizeStaticElements() {
    document.querySelectorAll("[data-i18n]").forEach((element) => {
        const message = t(element.dataset.i18n);
        if (message !== element.dataset.i18n) {
            element.textContent = message;
        }
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach((element) => {
        const message = t(element.dataset.i18nPlaceholder);
        if (message !== element.dataset.i18nPlaceholder) {
            element.placeholder = message;
        }
    });
}

const state = {
    scope: "site",          // "site" | "global"
    domain: null,           // hostname of the active tab, or null
    tabId: null,
    presets: [],
    userAgent: "",          // active global user agent
    globalViewport: null,
    globalEmulation: "",    // active global emulation ("" = auto-detect)
    siteSettings: [],       // [{ domain, userAgent, viewport, emulation }]
    filter: ""
};

// ---------- User-agent token resolution ----------

// Presets store tokens like %OS_MAJOR% that the native app fills in from the
// device OS version. The popup resolves them from the real device user agent so
// the value sent to sites is realistic even when applied without the app.
function deviceOSVersion() {
    const match = navigator.userAgent.match(/(?:iPhone OS|CPU OS) (\d+)_(\d+)(?:_(\d+))?/);
    if (match) {
        return { major: match[1], minor: match[2], patch: match[3] || "0" };
    }
    return { major: "18", minor: "5", patch: "0" };
}

function resolveTokens(userAgent) {
    const version = deviceOSVersion();
    return userAgent
        .split("%OS_MAJOR%").join(version.major)
        .split("%OS_MINOR%").join(version.minor)
        .split("%OS_PATCH%").join(version.patch);
}

// ---------- Monogram colours ----------

function colorFor(preset) {
    const key = preset.imageName || preset.name;
    let hash = 0;
    for (let i = 0; i < key.length; i++) {
        hash = (hash * 31 + key.charCodeAt(i)) % 360;
    }
    return `hsl(${hash}, 58%, 48%)`;
}

function monogram(preset) {
    const match = preset.name.match(/[A-Za-z0-9]/);
    return match ? match[0].toUpperCase() : "?";
}

// Browser-engine icons referenced remotely (same source as the app's bundled
// copies), so custom presets show them in the popup instead of a monogram.
const REMOTE_ICONS = {
    "WebKit": "https://commons.wikimedia.org/wiki/Special:FilePath/WebKit_logo.svg?width=512",
    "Chromium": "https://commons.wikimedia.org/wiki/Special:FilePath/Chromium_Logo.svg?width=512",
    "Gecko": "https://commons.wikimedia.org/wiki/Special:FilePath/Mozillagecko-logo.svg?width=512",
    "IE": "https://commons.wikimedia.org/wiki/Special:FilePath/Internet_Explorer_10%2B11_logo.svg?width=512",
    "Ladybird": "https://commons.wikimedia.org/wiki/Special:FilePath/Ladybird_icon_png.png?width=512"
};

// App Store, Play Store, and Apple (apple-touch) icons are square artwork
// cropped to a rounded rect; other logos/favicons render flat.
function shouldRound(url) {
    return url.includes("mzstatic.com")
        || url.includes("play-lh.googleusercontent.com")
        || url.includes("apple.com");
}

// A remote image, rounded only for store app icons.
function remoteIconHtml(preset, url) {
    const rounded = shouldRound(url) ? " icon-rounded" : "";
    return `<img class="icon icon-img${rounded}" src="${escapeHtml(url)}" alt="" loading="lazy">`;
}

function iconHtml(preset, isDefault) {
    // The default ("Don't Change") row uses a circle-slash glyph.
    if (isDefault) {
        return `<span class="icon" style="background:transparent">`
            + `<svg viewBox="0 0 24 24" fill="none" stroke="var(--secondary-label)" `
            + `stroke-width="1.8" stroke-linecap="round" style="width:22px;height:22px" aria-hidden="true">`
            + `<circle cx="12" cy="12" r="9"></circle>`
            + `<line x1="6.5" y1="17.5" x2="17.5" y2="6.5"></line>`
            + `</svg></span>`;
    }
    // Remote store icon.
    if (preset.iconURL) {
        return remoteIconHtml(preset, preset.iconURL);
    }
    // Browser-engine icon (custom presets), referenced remotely.
    if (REMOTE_ICONS[preset.imageName]) {
        return remoteIconHtml(preset, REMOTE_ICONS[preset.imageName]);
    }
    // No remote icon: monogram tile.
    return `<span class="icon" style="background:${colorFor(preset)}">${escapeHtml(monogram(preset))}</span>`;
}

// ---------- Active-preset detection ----------

function activeUserAgent() {
    if (state.scope === "global") {
        return state.userAgent || "";
    }
    const entry = state.siteSettings.find((s) => s.domain === state.domain);
    return entry ? entry.userAgent : "";
}

function isActive(preset) {
    const active = activeUserAgent();
    if (preset.userAgent === "") {
        return active === "";
    }
    return resolveTokens(preset.userAgent) === active;
}

// ---------- Rendering ----------

function escapeHtml(value) {
    return value.replace(/[&<>"']/g, (c) => ({
        "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[c]));
}

const CHECK_SVG = '<svg class="check" viewBox="0 0 16 16" aria-hidden="true"><path d="M6.2 11.8 2.6 8.2a.9.9 0 1 1 1.3-1.3l2.3 2.3 5.6-5.6a.9.9 0 1 1 1.3 1.3l-6.3 6.3a.9.9 0 0 1-1.3 0z"/></svg>';

const VIEWPORT_SUBTITLES = {
    Mobile: "subtitleMobile",
    Tablet: "subtitleTablet",
    Desktop: "subtitleDesktop"
};

function rowHtml(preset, index) {
    const isDefault = preset.userAgent === "";
    const icon = iconHtml(preset, isDefault);
    const name = isDefault ? t("defaultName") : preset.name;
    const subtitleKey = isDefault
        ? "subtitleDefault"
        : (VIEWPORT_SUBTITLES[preset.viewport] || "subtitleUserAgent");
    return `<button type="button" class="row${isActive(preset) ? " active" : ""}" data-index="${index}">
        ${icon}
        <span class="text">
            <span class="name">${escapeHtml(name)}</span>
            <span class="subtitle">${escapeHtml(t(subtitleKey))}</span>
        </span>
        ${CHECK_SVG}
    </button>`;
}

function render() {
    const list = document.getElementById("presetList");
    list.removeAttribute("aria-busy");

    const filter = state.filter.trim().toLowerCase();
    const matches = (p) => !filter || p.name.toLowerCase().includes(filter)
        || p.userAgent.toLowerCase().includes(filter);

    let html = "";

    // Default ("Don't Change") is pinned at the top, outside the sections.
    const defaultIndex = state.presets.findIndex((p) => p.userAgent === "");
    if (defaultIndex !== -1 && matches(state.presets[defaultIndex])) {
        html += `<div class="card">${rowHtml(state.presets[defaultIndex], defaultIndex)}</div>`;
    }

    const rows = [];
    state.presets.forEach((preset, index) => {
        if (preset.userAgent === "" || !matches(preset)) {
            return;
        }
        rows.push({ preset, index });
    });

    if (rows.length > 0) {
        html += `<div class="section-header">${escapeHtml(t("sectionPresets"))}</div>`;
        html += `<div class="card">${rows.map((r) => rowHtml(r.preset, r.index)).join("")}</div>`;
    }

    if (!html) {
        html = `<p class="empty-state">${escapeHtml(t("emptyState"))}</p>`;
    }

    list.innerHTML = html;
    list.querySelectorAll(".row").forEach((row) => {
        row.addEventListener("click", () => {
            applyPreset(state.presets[Number(row.dataset.index)]);
        });
    });
}

function renderScope() {
    document.querySelectorAll(".segment").forEach((segment) => {
        segment.classList.toggle("selected", segment.dataset.scope === state.scope);
    });
}

// ---------- Applying ----------

let applying = false;

async function applyPreset(preset) {
    if (applying || !preset) {
        return;
    }
    if (state.scope === "site" && !state.domain) {
        return;
    }
    applying = true;

    const userAgent = resolveTokens(preset.userAgent);
    const viewport = preset.viewport || null;
    // "" (built-in presets have no emulation field) => the extension auto-detects.
    const emulation = userAgent === "" ? "" : (preset.emulation || "");

    try {
        if (state.scope === "global") {
            await setGlobalUserAgent(userAgent);
            await setGlobalViewport(userAgent === "" ? null : viewport);
            await setGlobalEmulation(emulation);
        } else {
            await upsertSiteSetting(state.domain, userAgent, userAgent === "" ? null : viewport, emulation);
        }
        await persistToApp();
        render();
        await reloadActiveTab();
    } catch (error) {
        console.error("Failed to apply preset", error);
    } finally {
        applying = false;
    }
}

async function setGlobalUserAgent(userAgent) {
    if (userAgent !== "") {
        await browser.declarativeNetRequest.updateDynamicRules({
            removeRuleIds: [GLOBAL_RULE_ID],
            addRules: [{
                id: GLOBAL_RULE_ID,
                priority: 1,
                condition: { urlFilter: "*", resourceTypes: SUPPORTED_RESOURCE_TYPES },
                action: {
                    type: "modifyHeaders",
                    requestHeaders: [{ header: "User-Agent", operation: "set", value: userAgent }]
                }
            }]
        });
    } else {
        await browser.declarativeNetRequest.updateDynamicRules({ removeRuleIds: [GLOBAL_RULE_ID] });
    }
    state.userAgent = userAgent;
    await browser.storage.local.set({ userAgent });
}

async function setGlobalViewport(viewport) {
    state.globalViewport = viewport;
    await browser.storage.local.set({ globalViewport: viewport || "" });
}

async function setGlobalEmulation(emulation) {
    state.globalEmulation = emulation || "";
    await browser.storage.local.set({ globalEmulation: state.globalEmulation });
}

async function upsertSiteSetting(domain, userAgent, viewport, emulation) {
    // Rebuild the per-site list, then regenerate every per-site rule (ids 1..N),
    // matching how background.js maps siteSettings to dynamic rules.
    let settings = state.siteSettings.filter((s) => s.domain !== domain);
    if (userAgent !== "") {
        settings.push({ domain, userAgent, viewport: viewport || null, emulation: emulation || null });
    }

    const existing = await browser.declarativeNetRequest.getDynamicRules();
    const removeRuleIds = existing
        .filter((rule) => rule.id !== GLOBAL_RULE_ID)
        .map((rule) => rule.id);

    const addRules = settings.map((setting, index) => ({
        id: index + 1,
        priority: index + 2,
        condition: { urlFilter: "||" + setting.domain, resourceTypes: SUPPORTED_RESOURCE_TYPES },
        action: {
            type: "modifyHeaders",
            requestHeaders: [{ header: "User-Agent", operation: "set", value: setting.userAgent }]
        }
    }));

    await browser.declarativeNetRequest.updateDynamicRules({ removeRuleIds, addRules });

    state.siteSettings = settings;
    await browser.storage.local.set({ siteSettings: settings });

    // Keep viewportSettings in sync for the content script.
    const stored = await browser.storage.local.get(["viewportSettings"]);
    const viewportSettings = stored.viewportSettings || {};
    if (userAgent !== "" && viewport) {
        viewportSettings[domain] = viewport;
    } else {
        delete viewportSettings[domain];
    }
    await browser.storage.local.set({ viewportSettings });
}

// Write the change back to the app's shared settings so the main app's UI
// (bound to these keys via @AppStorage) reflects what was set in the popup.
async function persistToApp() {
    try {
        if (state.scope === "global") {
            await browser.runtime.sendNativeMessage({
                function: "saveSettings",
                userAgent: state.userAgent,
                globalViewport: state.globalViewport || "",
                globalEmulation: state.globalEmulation || ""
            });
        } else {
            await browser.runtime.sendNativeMessage({
                function: "saveSettings",
                siteSettings: JSON.stringify(state.siteSettings)
            });
        }
    } catch (error) {
        console.warn("Could not sync settings to app", error);
    }
}

async function reloadActiveTab() {
    if (state.tabId != null) {
        try {
            await browser.tabs.reload(state.tabId);
        } catch (error) {
            console.warn("Could not reload tab", error);
        }
    }
}

// ---------- Troubleshooting (reset) ----------

function setupTroubleshooting() {
    document.getElementById("btnToggleTrouble").addEventListener("click", (event) => {
        const expanded = document.getElementById("troubleSection").classList.toggle("expanded");
        event.currentTarget.classList.toggle("expanded", expanded);
        event.currentTarget.setAttribute("aria-expanded", String(expanded));
    });
    document.getElementById("btnResetRules").addEventListener("click", resetAllSettings);
}

async function resetAllSettings() {
    const button = document.getElementById("btnResetRules");
    button.disabled = true;
    try {
        const rules = await browser.declarativeNetRequest.getDynamicRules();
        if (rules.length > 0) {
            await browser.declarativeNetRequest.updateDynamicRules({
                removeRuleIds: rules.map((rule) => rule.id)
            });
        }
        await browser.storage.local.set({ schemaVersion: -1 });
        browser.runtime.sendNativeMessage({ function: "forceExtensionReset" });

        const message = document.createElement("p");
        message.className = "success";
        message.textContent = t("resetSuccess");
        button.parentNode.replaceChild(message, button);
    } catch (error) {
        console.error("Failed to reset settings", error);
        button.disabled = false;
    }
}

// ---------- Init ----------

function setupScopeControl() {
    document.querySelectorAll(".segment").forEach((segment) => {
        segment.addEventListener("click", () => {
            if (segment.disabled || segment.dataset.scope === state.scope) {
                return;
            }
            state.scope = segment.dataset.scope;
            renderScope();
            render();
        });
    });
}

function setupSearch() {
    document.getElementById("searchInput").addEventListener("input", (event) => {
        state.filter = event.target.value;
        render();
    });
}

async function loadActiveTab() {
    try {
        const tabs = await browser.tabs.query({ active: true, currentWindow: true });
        const tab = tabs && tabs[0];
        if (tab) {
            state.tabId = tab.id;
            if (tab.url && /^https?:/.test(tab.url)) {
                state.domain = new URL(tab.url).hostname;
            }
        }
    } catch (error) {
        console.warn("Could not read active tab", error);
    }
    if (!state.domain) {
        // No site to scope to — fall back to global and disable the site segment.
        state.scope = "global";
        const siteSegment = document.querySelector('.segment[data-scope="site"]');
        if (siteSegment) {
            siteSegment.disabled = true;
        }
    }
}

async function loadSettings() {
    const stored = await browser.storage.local.get(["userAgent", "globalViewport", "globalEmulation", "siteSettings"]);
    state.userAgent = stored.userAgent || "";
    state.globalViewport = stored.globalViewport || null;
    state.globalEmulation = stored.globalEmulation || "";
    state.siteSettings = Array.isArray(stored.siteSettings) ? stored.siteSettings : [];
}

// Ensure exactly one "default" row exists, regardless of the source list.
function normalizePresets(list) {
    const presets = Array.isArray(list) ? list.slice() : [];
    if (!presets.some((preset) => preset.userAgent === "")) {
        presets.unshift({ name: "Default", imageName: "Safari", userAgent: "" });
    }
    return presets;
}

async function loadPresets() {
    // Prefer the live list from the app (reflects online version updates,
    // custom presets, and hidden/visible choices); fall back to the bundle.
    try {
        const response = await browser.runtime.sendNativeMessage({ function: "getPresets" });
        if (response && response.presets) {
            const parsed = JSON.parse(response.presets);
            if (Array.isArray(parsed) && parsed.length > 0) {
                state.presets = normalizePresets(parsed);
                return;
            }
        }
    } catch (error) {
        console.warn("Could not load presets from app, using bundled set", error);
    }
    const bundled = await (await fetch(browser.runtime.getURL("presets.json"))).json();
    state.presets = normalizePresets(bundled);
}

async function init() {
    localizeStaticElements();
    setupScopeControl();
    setupSearch();
    setupTroubleshooting();

    await Promise.all([loadActiveTab(), loadSettings(), loadPresets()]);

    renderScope();
    render();
}

// iPhone uses a full-width sheet; iPad/macOS keep the fixed popover (see
// popup.css). Only iPhone reports "iPhone" in the popup's genuine Safari UA.
if (/iPhone|iPod/.test(navigator.userAgent)) {
    document.documentElement.classList.add("is-iphone");
}

init();
