browser.storage.local.get(["viewportSettings", "globalViewport"], (result) => {
    let currentDomain = window.location.hostname;
    let viewportToApply = null;
    
    if (result.viewportSettings) {
        for (let domain in result.viewportSettings) {
            if (currentDomain.includes(domain)) {
                viewportToApply = result.viewportSettings[domain];
                break;
            }
        }
    }
    
    if (!viewportToApply && result.globalViewport) {
        viewportToApply = result.globalViewport;
    }
    
    if (viewportToApply) {
        applyViewport(viewportToApply);
    }
});

function applyViewport(viewport) {
    let existingViewport = document.querySelector('meta[name="viewport"]');
    if (existingViewport) {
        existingViewport.remove();
    }
    
    let viewportMeta = document.createElement('meta');
    viewportMeta.name = 'viewport';
    
    if (viewport === 'Desktop') {
        viewportMeta.content = 'width=1200, initial-scale=1.0';
    } else if (viewport === 'Tablet') {
        viewportMeta.content = 'width=820, initial-scale=1.0';
    } else if (viewport === 'Mobile') {
        viewportMeta.content = 'width=390, initial-scale=1.0';
    }
    
    if (viewportMeta.content) {
        document.head.insertBefore(viewportMeta, document.head.firstChild);
    }
}

let sending = browser.runtime.sendMessage({});
sending.then(null, null);
