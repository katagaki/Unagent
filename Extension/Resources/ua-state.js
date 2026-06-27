// ISOLATED world, document_start. Bridges the resolved User-Agent onto the root
// element for ua-override.js (MAIN world) to read. storage.local is async and loses
// the race against an inline navigator.userAgent read during parse, so we also keep
// a synchronous localStorage warm cache: reads from the 2nd visit on win the race.
const UNAGENT_UA_ATTR = "data-unagent-ua";
const UNAGENT_UA_CACHE_KEY = "__unagentUA";

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

// Synchronous fast path: last-known UA for this origin.
try {
    const cached = window.localStorage.getItem(UNAGENT_UA_CACHE_KEY);
    if (cached) {
        document.documentElement.setAttribute(UNAGENT_UA_ATTR, cached);
    }
} catch (error) {}

// Authoritative async path: resolve from storage, bridge it in, refresh the cache.
browser.storage.local.get(["userAgent", "siteSettings"], (result) => {
    const userAgent = unagentResolveUserAgent(result);
    if (userAgent) {
        document.documentElement.setAttribute(UNAGENT_UA_ATTR, userAgent);
        try { window.localStorage.setItem(UNAGENT_UA_CACHE_KEY, userAgent); } catch (error) {}
    } else {
        document.documentElement.removeAttribute(UNAGENT_UA_ATTR);
        try { window.localStorage.removeItem(UNAGENT_UA_CACHE_KEY); } catch (error) {}
    }
});
