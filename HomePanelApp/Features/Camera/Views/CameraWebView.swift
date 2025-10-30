import SwiftUI
import WebKit

// MARK: - Camera Web View

struct CameraWebView: UIViewRepresentable {
    let url: URL?
    let onURLChange: ((URL) -> Void)?
    
    init(url: URL?, onURLChange: ((URL) -> Void)? = nil) {
        self.url = url
        self.onURLChange = onURLChange
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Enable inline media playback for video
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Additional settings for better video autoplay support
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        
        // Enable JavaScript (required for Blue Iris UI)
        configuration.preferences.javaScriptEnabled = true
        
        // Use default website data store for cookies/credentials
        configuration.websiteDataStore = .default()
        
        // Add message handler for JavaScript communication
        configuration.userContentController.add(context.coordinator, name: "urlChange")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else { return }
        
        // Only load if URL is different
        if webView.url != url {
            let request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                timeoutInterval: 30
            )
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onURLChange: onURLChange)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onURLChange: ((URL) -> Void)?
        
        init(onURLChange: ((URL) -> Void)? = nil) {
            self.onURLChange = onURLChange
        }
        
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            DebugLogger.error("Failed to load camera: \(error.localizedDescription)", feature: .camera)
        }
        
        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {
            // Log the current URL for debugging
            if let currentURL = webView.url {
                onURLChange?(currentURL)
            }
            
            // Inject minimal JavaScript for URL monitoring only
            injectURLMonitoringScript(webView)
            
            // Inject conservative autoplay script
            injectAutoplayScript(webView)
        }
        
        private func injectURLMonitoringScript(_ webView: WKWebView) {
            let script = """
            (function() {
                // Monitor for URL changes that don't trigger navigation
                let currentURL = window.location.href;
                let lastLoggedURL = currentURL;
                
                // Function to check for URL changes
                function checkURLChange() {
                    if (window.location.href !== lastLoggedURL) {
                        lastLoggedURL = window.location.href;
                        
                        // Send message to native code
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.urlChange) {
                            window.webkit.messageHandlers.urlChange.postMessage({
                                url: lastLoggedURL,
                                timestamp: new Date().toISOString()
                            });
                        }
                    }
                }
                
                // Check for URL changes every 500ms
                setInterval(checkURLChange, 500);
                
                // Also monitor for hash changes (for single-page app navigation)
                window.addEventListener('hashchange', function() {
                    checkURLChange();
                });
                
                // Monitor for popstate events (back/forward navigation)
                window.addEventListener('popstate', function() {
                    checkURLChange();
                });
                
            })();
            """
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    DebugLogger.error("Failed to inject URL monitoring script: \(error.localizedDescription)", feature: .camera)
                }
            }
        }
        
        private func injectAutoplayScript(_ webView: WKWebView) {
            let autoplayScript = """
            (function() {
                // Conservative autoplay approach - handle HTML5 messages and monitor for new feeds
                function handleHTML5Autoplay() {
                    // Look for the specific HTML5 autoplay message
                    const elements = document.querySelectorAll('*');
                    for (let element of elements) {
                        const text = element.textContent || element.innerText || '';
                        if (text.includes('Click anywhere to begin streaming') || 
                            text.includes('user input before playback')) {
                            console.log('HTML5 autoplay message detected, attempting to click');
                            element.click();
                            return true;
                        }
                    }
                    return false;
                }
                
                // Gentle video optimization
                function optimizeVideos() {
                    const videos = document.querySelectorAll('video');
                    videos.forEach(video => {
                        // Only set essential properties, don't override Blue Iris settings
                        if (video.paused && video.readyState >= 2) {
                            video.muted = true;
                            video.play().catch(e => {
                                console.log('Video autoplay failed:', e);
                            });
                        }
                    });
                }
                
                // Monitor for new camera feeds being added dynamically
                function monitorForNewFeeds() {
                    // Check for HTML5 messages every 3 seconds
                    if (handleHTML5Autoplay()) {
                        console.log('HTML5 autoplay message handled');
                    } else {
                        optimizeVideos();
                    }
                }
                
                // Initial attempt after page load
                setTimeout(() => {
                    monitorForNewFeeds();
                }, 2000);
                
                // Continue monitoring for dynamically loaded camera feeds
                setInterval(monitorForNewFeeds, 3000);
                
                // Also monitor DOM changes for new elements
                const observer = new MutationObserver((mutations) => {
                    mutations.forEach((mutation) => {
                        if (mutation.addedNodes.length > 0) {
                            // New elements added, check for HTML5 messages
                            setTimeout(handleHTML5Autoplay, 500);
                        }
                    });
                });
                
                // Start observing
                observer.observe(document.body, {
                    childList: true,
                    subtree: true
                });
                
            })();
            """
            
            webView.evaluateJavaScript(autoplayScript) { result, error in
                if let error = error {
                    DebugLogger.error("Failed to inject autoplay script: \(error.localizedDescription)", feature: .camera)
                } else {
                    DebugLogger.log("Autoplay script injected successfully", feature: .camera)
                }
            }
        }
        
        
        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            DebugLogger.error("Camera navigation failed: \(error.localizedDescription)", feature: .camera)
        }
        
        // This method is called when the URL changes (including navigation within the same page)
        func webView(_ webView: WKWebView, 
                     decidePolicyFor navigationAction: WKNavigationAction, 
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // Log the navigation action for debugging
            if let url = navigationAction.request.url {
                DebugLogger.log("Navigation to: \(url.absoluteString)", feature: .camera)
                
                // Check if this is a Blue Iris camera navigation
                if url.absoluteString.contains("ui3.htm") {
                    DebugLogger.log("Blue Iris UI navigation detected", feature: .camera)
                    
                    // Parse and log the URL parameters
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let queryItems = components.queryItems {
                        DebugLogger.log("URL Parameters:", feature: .camera)
                        for item in queryItems {
                            DebugLogger.log("   \(item.name): \(item.value ?? "nil")", feature: .camera)
                        }
                    }
                }
                
                // Notify about URL change
                onURLChange?(url)
            }
            
            // Allow the navigation to proceed
            decisionHandler(.allow)
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "urlChange" {
                guard let body = message.body as? [String: Any],
                      let urlString = body["url"] as? String,
                      let url = URL(string: urlString) else {
                    DebugLogger.error("Invalid URL change message from JavaScript", feature: .camera)
                    return
                }
                
                onURLChange?(url)
            }
        }
    }
}