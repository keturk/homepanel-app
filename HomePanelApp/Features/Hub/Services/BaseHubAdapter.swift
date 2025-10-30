import Foundation

// MARK: - Base Hub Adapter

/// Base class for hub adapters with common functionality
actor BaseHubAdapter {
    let hubId: String
    let hubType: HubType
    let connection: HubConnection
    private let session: URLSession
    
    init(hubId: String, hubType: HubType, connection: HubConnection, session: URLSession = URLSession.shared) {
        self.hubId = hubId
        self.hubType = hubType
        self.connection = connection
        self.session = session
    }
    
    /// Get the base URL for this hub's connection
    var baseURL: String {
        let scheme = connection.useHTTPS ? "https" : "http"
        let port = connection.port ?? HubConnection.defaultVeraPort
        return "\(scheme)://\(connection.address):\(port)"
    }
    
    /// Get credentials for authenticated requests
    var credentials: HubCredentials? {
        return connection.credentials
    }
    
    /// Build URL with embedded credentials if available
    func buildAuthenticatedURL(_ path: String) -> String {
        let base = baseURL
        guard let credentials = credentials,
              let username = credentials.username,
              let password = credentials.password else {
            return "\(base)\(path)"
        }
        
        // Embed credentials in URL (http://username:password@host:port/path)
        if let url = URL(string: base),
           let host = url.host,
           let port = url.port {
            return "http://\(username):\(password)@\(host):\(port)\(path)"
        } else {
            return "\(base)\(path)"
        }
    }
    
    /// Check if hub is reachable with a simple ping
    var isReachable: Bool {
        get async {
            do {
                let url = URL(string: "\(baseURL)/ping") ?? URL(string: "\(baseURL)/")!
                // Use shorter timeout for reachability check
                let (_, response) = try await withTimeout(seconds: TimeoutConfiguration.reachabilityCheck) { [self] in
                    try await session.data(from: url)
                }
                let isReachable = (response as? HTTPURLResponse)?.statusCode == 200
                DebugLogger.log("🔍 Hub reachability check for \(baseURL): \(isReachable ? "reachable" : "unreachable")", feature: .hubService)
                return isReachable
            } catch {
                // IMPORTANT: Return true on error to enable fallback device mechanism.
                //
                // This design choice prioritizes availability over strict connectivity checks.
                // When the hub is unreachable, returning true allows the app to show fallback
                // devices (last known state) rather than blocking the UI completely.
                //
                // The actual connection will fail later when specific operations are attempted,
                // at which point users will see stale/cached data. This provides a better UX
                // than showing "hub offline" with no device controls at all.
                //
                // Rationale: Home automation should degrade gracefully - show last known state
                // even when the hub is temporarily offline.
                DebugLogger.log("⚠️ Reachability check failed, returning true to allow fallback: \(error.localizedDescription)", feature: .hubService)
                return true
            }
        }
    }
    
    /// Make a network request with proper error handling
    func makeRequest(to path: String, timeout: TimeInterval = TimeoutConfiguration.standardRequest) async throws -> (Data, HTTPURLResponse) {
        let urlString = buildAuthenticatedURL(path)
        guard let url = URL(string: urlString) else {
            throw HubError.invalidConfiguration
        }
        
        DebugLogger.log("🌐 [BaseHubAdapter] Making request to: \(urlString) (timeout: \(timeout)s)", feature: .hubService)
        
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add API key or token if available
        if let credentials = credentials {
            if let apiKey = credentials.apiKey {
                request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            } else if let token = credentials.token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        let startTime = Date()
        
        do {
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DebugLogger.log("❌ [BaseHubAdapter] Invalid response type for: \(urlString)", feature: .hubService)
                throw HubError.invalidResponse
            }
            
            // Log response size to track bandwidth optimization
            let sizeKB = Double(data.count) / 1024.0
            let endpoint = path.contains("sdata") ? "sdata" : (path.contains("status") ? "status" : "other")
            DebugLogger.log("✅ [BaseHubAdapter] Request completed in \(String(format: "%.2f", duration))s - Status: \(httpResponse.statusCode) - Size: \(String(format: "%.1f", sizeKB))KB (\(endpoint)) - URL: \(urlString)", feature: .hubService)

            guard httpResponse.statusCode == 200 else {
                DebugLogger.log("❌ [BaseHubAdapter] HTTP error \(httpResponse.statusCode) for: \(urlString)", feature: .hubService)
                throw HubError.networkError(URLError(.badServerResponse))
            }

            return (data, httpResponse)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            DebugLogger.log("❌ [BaseHubAdapter] Request failed after \(String(format: "%.2f", duration))s - Error: \(error.localizedDescription) - URL: \(urlString)", feature: .hubService)
            throw HubError.networkError(error)
        }
    }
}
