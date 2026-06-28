// ISOLATED world, document_start. Bridges the resolved User-Agent onto the root
// element for ua-override.js (MAIN world) to read. storage.local is async and loses
// the race against an inline navigator.userAgent read during parse, so we also keep
// a synchronous localStorage warm cache: reads from the 2nd visit on win the race.
const UNAGENT_UA_ATTR = "data-unagent-ua";
const UNAGENT_UA_CACHE_KEY = "__unagentUA";
// Read synchronously from localStorage by browser-emulation.js (MAIN world).
const UNAGENT_ENGINE_CACHE_KEY = "__unagentEngine";

// Anchored host match, mirroring the DNR rule's urlFilter "||"+domain.
function unagentResolveUserAgent(result) {
    const host = window.location.hostname;
    const siteSettings = result.siteSettings || [];
    for (const setting of siteSettings) {
        if (setting.userAgent && (host === setting.domain || host.endsWith("." + setting.domain))) {
            return setting.userAgent;
        }
    }
    return result.userAgent || "";
}

// The "webkit" profile (desktop Safari): only flattens the iOS device-class
// signals — see browser-emulation.js. No userAgentData/window.chrome (engine matches).
function unagentWebkitProfile() {
    return { engine: "webkit", navPlatform: "MacIntel", maxTouchPoints: 0 };
}

// The "gecko" profile (Firefox): Firefox-only navigator props (vendor ""/oscpu/
// buildID/productSub, applied in browser-emulation.js) plus device-class flatten.
function unagentGeckoProfile(userAgent) {
    const mobile = /\bMobile\b/.test(userAgent) || /\bAndroid\b/.test(userAgent);
    let navPlatform = "Win32", oscpu = "Windows NT 10.0; Win64; x64";
    if (/\bAndroid\b/.test(userAgent)) {
        navPlatform = "Linux armv8l"; oscpu = "Linux armv8l";
    } else if (/Mac OS X/.test(userAgent)) {
        navPlatform = "MacIntel"; oscpu = "Intel Mac OS X 10.15";
    } else if (/\bLinux\b/.test(userAgent)) {
        navPlatform = "Linux x86_64"; oscpu = "Linux x86_64";
    }
    return { engine: "gecko", navPlatform: navPlatform, oscpu: oscpu, mobile: mobile,
             maxTouchPoints: mobile ? 5 : 0 };
}

// Build the "chromium" (Blink) profile from a UA. Used for both auto-detection and
// forced emulation, so it tolerates a missing Chrome token. Refresh the brand/
// GREASE/version values alongside the preset UAs on Chrome's ~4-week cadence.
function unagentChromiumProfile(userAgent) {
    const chromeMatch = userAgent.match(/Chrome\/(\d+)/);
    const major = chromeMatch ? chromeMatch[1] : "120";
    const mobile = /\bMobile\b/.test(userAgent);
    const edgeMatch = userAgent.match(/\bEdgA?\/(\d+(?:\.\d+){3})/);
    const isEdge = edgeMatch !== null;

    // platform: userAgentData token; navPlatform: navigator.platform;
    // platformVersion: high-entropy value (not the frozen UA token).
    let platform = "Windows", navPlatform = "Win32", platformVersion = "15.0.0";
    let architecture = "x86", bitness = "64";
    if (/\bAndroid\b/.test(userAgent)) {
        platform = "Android"; navPlatform = "Linux armv8l"; platformVersion = "14.0.0";
        architecture = ""; bitness = "";
    } else if (/\bCrOS\b/.test(userAgent)) {
        platform = "Chrome OS"; navPlatform = "Linux x86_64";
        const cros = userAgent.match(/CrOS \S+ ([\d.]+)/);
        platformVersion = cros ? cros[1] : "14541.0.0";
    } else if (/Mac OS X/.test(userAgent)) {
        platform = "macOS"; navPlatform = "MacIntel"; platformVersion = "15.1.0";
        architecture = "arm";
    } else if (/\bLinux\b/.test(userAgent)) {
        platform = "Linux"; navPlatform = "Linux x86_64"; platformVersion = "";
    }

    const brandName = isEdge ? "Microsoft Edge" : "Google Chrome";
    // GREASE brand — a maintained approximation, not Chromium's exact algorithm.
    const grease = { brand: "Not;A=Brand", version: "99" };
    const brands = [
        grease,
        { brand: "Chromium", version: major },
        { brand: brandName, version: major }
    ];
    const fullVersion = isEdge ? edgeMatch[1] : major + ".0.0.0";
    const fullVersionList = [
        grease,
        { brand: "Chromium", version: major + ".0.0.0" },
        { brand: brandName, version: fullVersion }
    ];

    return {
        engine: "chromium",
        vendor: "Google Inc.",
        platform: platform,
        navPlatform: navPlatform,
        platformVersion: platformVersion,
        architecture: architecture,
        bitness: bitness,
        wow64: false,
        model: "",
        mobile: mobile,
        brands: brands,
        fullVersionList: fullVersionList,
        uaFullVersion: fullVersion,
        hardwareConcurrency: 8,
        deviceMemory: 8,
        maxTouchPoints: mobile ? 5 : 0,
        windowChrome: !mobile,
        webgl: null   // P1: set { vendor, renderer } to enable ANGLE-string spoofing
    };
}

// An explicit per-preset emulation value wins; when unset, auto-detect from the UA.
// iOS browsers are all WebKit and never shimmed.
function unagentEngineProfile(userAgent, emulation) {
    if (!userAgent) { return null; }
    if (emulation === "none") { return null; }
    if (emulation === "chromium") { return unagentChromiumProfile(userAgent); }
    if (emulation === "safari") { return unagentWebkitProfile(); }
    if (emulation === "firefox") { return unagentGeckoProfile(userAgent); }
    // Auto: derive from the UA.
    if (/\b(iPhone|iPad|iPod)\b/.test(userAgent)) { return null; }
    if (userAgent.indexOf("AppleWebKit/537.36") === -1) {
        // Non-Blink: desktop Safari or Firefox.
        if (/Mac OS X/.test(userAgent) && / Version\//.test(userAgent) && / Safari\//.test(userAgent)) {
            return unagentWebkitProfile();
        }
        if (/\bFirefox\/\d/.test(userAgent) && /Gecko\//.test(userAgent)) {
            return unagentGeckoProfile(userAgent);
        }
        return null;
    }
    if (/\bEdge\/\d/.test(userAgent)) { return null; }       // legacy EdgeHTML
    if (!/Chrome\/(\d+)/.test(userAgent)) { return null; }
    return unagentChromiumProfile(userAgent);
}

// Per-site emulation override, paired with the per-site UA (mirrors UA resolution).
function unagentResolveEmulation(result) {
    const host = window.location.hostname;
    for (const setting of result.siteSettings || []) {
        if (setting.userAgent && (host === setting.domain || host.endsWith("." + setting.domain))) {
            return setting.emulation;
        }
    }
    return result.globalEmulation;
}

// Synchronous fast path: last-known UA + engine for this origin. The warm engine is
// what the shim actually consumed, so the reconcile check below compares against it.
let unagentWarmUserAgent = null;
let unagentWarmEngine = "";
try {
    unagentWarmUserAgent = window.localStorage.getItem(UNAGENT_UA_CACHE_KEY);
    if (unagentWarmUserAgent) {
        document.documentElement.setAttribute(UNAGENT_UA_ATTR, unagentWarmUserAgent);
    }
    const warmEngineRaw = window.localStorage.getItem(UNAGENT_ENGINE_CACHE_KEY);
    if (warmEngineRaw) {
        try { unagentWarmEngine = (JSON.parse(warmEngineRaw) || {}).engine || ""; } catch (e) {}
    }
} catch (error) {}

// Authoritative async path: resolve from storage, bridge it in, refresh the cache.
browser.storage.local.get(["userAgent", "siteSettings", "globalEmulation"], (result) => {
    const userAgent = unagentResolveUserAgent(result);
    const emulation = unagentResolveEmulation(result);
    if (userAgent) {
        document.documentElement.setAttribute(UNAGENT_UA_ATTR, userAgent);
        try { window.localStorage.setItem(UNAGENT_UA_CACHE_KEY, userAgent); } catch (error) {}
    } else {
        document.documentElement.removeAttribute(UNAGENT_UA_ATTR);
        try { window.localStorage.removeItem(UNAGENT_UA_CACHE_KEY); } catch (error) {}
    }

    // Engine profile for browser-emulation.js. Cleared when no shim applies so a previous
    // profile never lingers onto a "Don't Emulate" / Safari / Firefox preset.
    const profile = userAgent ? unagentEngineProfile(userAgent, emulation) : null;
    try {
        if (profile) {
            window.localStorage.setItem(UNAGENT_ENGINE_CACHE_KEY, JSON.stringify(profile));
        } else {
            window.localStorage.removeItem(UNAGENT_ENGINE_CACHE_KEY);
        }
    } catch (error) {}

    // The shim runs once off the warm cache, so after a preset switch it can act on
    // a stale engine. If the authoritative engine differs from the warm value, reload
    // once to re-evaluate. Guarded against loops; top frame, genuine switches only.
    try {
        if (window.top === window.self && unagentWarmUserAgent) {
            const authEngine = profile ? profile.engine : "";
            const RELOAD_GUARD = "__unagentEngineReload";
            if (unagentWarmEngine !== authEngine &&
                window.sessionStorage.getItem(RELOAD_GUARD) !== userAgent) {
                window.sessionStorage.setItem(RELOAD_GUARD, userAgent);
                window.location.reload();
            }
        }
    } catch (error) {}
});
