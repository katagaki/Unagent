// Get viewport settings and apply if needed
browser.storage.local.get(["viewportSettings", "globalViewport"], (result) => {
    let currentDomain = window.location.hostname;
    let viewportToApply = null;
    
    // First check for site-specific viewport
    if (result.viewportSettings) {
        for (let domain in result.viewportSettings) {
            if (currentDomain.includes(domain)) {
                viewportToApply = result.viewportSettings[domain];
                break;
            }
        }
    }
    
    // If no site-specific viewport, use global viewport
    if (!viewportToApply && result.globalViewport) {
        viewportToApply = result.globalViewport;
    }
    
    if (viewportToApply) {
        applyViewport(viewportToApply);
    }
});

function applyViewport(viewport) {
    // Remove existing viewport meta tag if present
    let existingViewport = document.querySelector('meta[name="viewport"]');
    if (existingViewport) {
        existingViewport.remove();
    }
    
    // Create and insert new viewport meta tag
    let viewportMeta = document.createElement('meta');
    viewportMeta.name = 'viewport';
    
    if (viewport === 'Desktop') {
        // Desktop viewport - FHD resolution (1920x1080)
        viewportMeta.content = 'width=1920, initial-scale=1.0';
    } else if (viewport === 'Mobile') {
        // Mobile viewport - iPhone size (390x844 for iPhone 13/14/15)
        viewportMeta.content = 'width=390, initial-scale=1.0';
    }
    
    if (viewportMeta.content) {
        document.head.insertBefore(viewportMeta, document.head.firstChild);
    }
}

let sending = browser.runtime.sendMessage({});
sending.then(null, null);
