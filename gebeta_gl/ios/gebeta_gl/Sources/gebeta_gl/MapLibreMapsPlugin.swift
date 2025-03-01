import Flutter
import Foundation
import MapLibre
import UIKit

// Add a custom URL protocol to intercept all requests
class AuthorizationURLProtocol: URLProtocol {
    static var apiKey: String?
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Only handle requests to tiles.gebeta.app
        if request.url?.host?.contains("gebeta.app") ?? false {
            // Log all requests to gebeta.app for debugging
            NSLog("AuthorizationURLProtocol canInit: \(request.url?.absoluteString ?? "unknown URL")")
            
            // Check if the request already has an Authorization header
            if request.value(forHTTPHeaderField: "Authorization") == nil {
                NSLog("Request to gebeta.app without Authorization header - will handle")
                return true
            } else {
                NSLog("Request to gebeta.app already has Authorization header: \(request.value(forHTTPHeaderField: "Authorization") ?? "nil")")
            }
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let apiKey = AuthorizationURLProtocol.apiKey, !apiKey.isEmpty else {
            NSLog("No API key available in AuthorizationURLProtocol")
            
            // If no API key, just pass through the original request
            let session = URLSession.shared
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.client?.urlProtocol(self, didFailWithError: error)
                    return
                }
                
                if let response = response {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
                }
                
                if let data = data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                
                self.client?.urlProtocolDidFinishLoading(self)
            }
            task.resume()
            return
        }
        
        // Create a mutable copy of the request
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        // Add the API key as a query parameter instead of an Authorization header
        if let url = mutableRequest.url {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            var queryItems = urlComponents?.queryItems ?? []
            
            // Check if apiKey is already in the query parameters
            let hasApiKey = queryItems.contains { $0.name == "apiKey" }
            
            if !hasApiKey {
                queryItems.append(URLQueryItem(name: "apiKey", value: apiKey))
                urlComponents?.queryItems = queryItems
                
                if let newUrl = urlComponents?.url {
                    mutableRequest.url = newUrl
                    NSLog("Modified URL to include API key as query parameter: \(newUrl)")
                }
            }
        }
        
        // Log the request headers for debugging
        NSLog("AuthorizationURLProtocol modifying request to: \(mutableRequest.url?.absoluteString ?? "unknown URL")")
        if let headers = mutableRequest.allHTTPHeaderFields {
            NSLog("Request headers: \(headers)")
        }
        
        // Create a new URLSession for this request
        let config = URLSessionConfiguration.default
        config.protocolClasses = nil  // Prevent infinite recursion
        let session = URLSession(configuration: config)
        
        // Start the data task
        let task = session.dataTask(with: mutableRequest as URLRequest) { data, response, error in
            if let error = error {
                NSLog("AuthorizationURLProtocol request failed: \(error.localizedDescription)")
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            guard let response = response else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            // Log the response
            NSLog("AuthorizationURLProtocol received response: \(response)")
            
            // Forward the response to the client
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            
            self.client?.urlProtocolDidFinishLoading(self)
        }
        
        task.resume()
    }
    
    override func stopLoading() {
        // Nothing to do here
    }
}

public class MapLibreMapsPlugin: NSObject, FlutterPlugin {
    static var downloadOfflineRegionChannelHandler: OfflineChannelHandler? = nil
    static var apiKey: String?
    
    // Register our custom URL protocol
    private static func registerURLProtocol() {
        // Set the API key in the URL protocol
        AuthorizationURLProtocol.apiKey = Self.apiKey
        
        // Register with the default configuration
        let defaultConfig = URLSessionConfiguration.default
        var protocolClasses = defaultConfig.protocolClasses ?? []
        protocolClasses.insert(AuthorizationURLProtocol.self, at: 0)
        defaultConfig.protocolClasses = protocolClasses
        
        // Also register with the shared session
        URLProtocol.registerClass(AuthorizationURLProtocol.self)
        
        NSLog("Registered AuthorizationURLProtocol with URLSessionConfiguration")
        
        // Also register with MLNNetworkConfiguration
        if let mlnConfig = MLNNetworkConfiguration.sharedManager.sessionConfiguration {
            var mlnProtocolClasses = mlnConfig.protocolClasses ?? []
            mlnProtocolClasses.insert(AuthorizationURLProtocol.self, at: 0)
            mlnConfig.protocolClasses = mlnProtocolClasses
            MLNNetworkConfiguration.sharedManager.sessionConfiguration = mlnConfig
            NSLog("Registered AuthorizationURLProtocol with MLNNetworkConfiguration")
        } else {
            NSLog("Could not register AuthorizationURLProtocol with MLNNetworkConfiguration - no session configuration")
        }
    }

    public static func setGlobalApiKey(_ apiKey: String) {
        if !apiKey.isEmpty {
            Self.apiKey = apiKey
            
            // Set the API key in the URL protocol
            AuthorizationURLProtocol.apiKey = apiKey
            
            // Create a new session configuration
            let sessionConfig = URLSessionConfiguration.default
            
            // Set the Authorization header
            sessionConfig.httpAdditionalHeaders = ["Authorization": "Bearer \(apiKey)"]
            
            // Set request timeout and cache policy
            sessionConfig.timeoutIntervalForRequest = 30.0
            sessionConfig.requestCachePolicy = .useProtocolCachePolicy
            
            NSLog("Setting global API key in Authorization header: Bearer \(apiKey)")
            
            // Apply the configuration to MapLibre
            MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
            
            // Register the URL protocol
            registerURLProtocol()
            
            // Force apply the headers to all future requests
            forceApplyHeaders()
            
            // Log the current configuration
            logNetworkConfiguration()
        }
    }
    
    // Force apply headers to all future requests
    private static func forceApplyHeaders() {
        guard let apiKey = Self.apiKey, !apiKey.isEmpty else {
            NSLog("No API key set, cannot force apply headers")
            return
        }
        
        // This is a workaround to ensure the headers are applied
        // We're creating a new session configuration and setting it again
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["Authorization": "Bearer \(apiKey)"]
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.requestCachePolicy = .useProtocolCachePolicy
        
        // Apply the configuration to MapLibre
        MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
        
        // Patch the MLNNetworkConfiguration class to ensure it's using our API key
        patchNetworkConfiguration()
        
        NSLog("Forced application of headers to all future requests")
    }
    
    // Patch the MLNNetworkConfiguration class to ensure it's using our API key
    private static func patchNetworkConfiguration() {
        guard let apiKey = Self.apiKey, !apiKey.isEmpty else {
            return
        }
        
        // Create a custom NSURLSessionConfiguration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(apiKey)"]
        
        // Set it directly on the MLNNetworkConfiguration
        MLNNetworkConfiguration.sharedManager.sessionConfiguration = config
        
        NSLog("Patched MLNNetworkConfiguration to use our API key")
    }

    // Add a method to log the current network configuration
    public static func logNetworkConfiguration() {
        let config = MLNNetworkConfiguration.sharedManager.sessionConfiguration
        
        NSLog("Current MLNNetworkConfiguration:")
        if let headers = config?.httpAdditionalHeaders {
            NSLog("  HTTP Headers: \(headers)")
        } else {
            NSLog("  No HTTP Headers set")
        }
        
        if let cachePolicy = config?.requestCachePolicy {
            NSLog("  Cache Policy: \(cachePolicy.rawValue)")
        }
        
        if let timeout = config?.timeoutIntervalForRequest {
            NSLog("  Request Timeout: \(timeout)")
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Register our custom URL protocol
        registerURLProtocol()
        
        let instance = MapLibreMapsPlugin()
        let channel = FlutterMethodChannel(
            name: "plugins.flutter.io/gebeta_gl",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: channel)

        let factory = MapLibreMapFactory(withRegistrar: registrar)
        registrar.register(
            factory,
            withId: "plugins.flutter.io/gebeta_gl",
            gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded
        )

        channel.setMethodCallHandler { methodCall, result in
            switch methodCall.method {
            case "setHttpHeaders":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let headers = arguments["headers"] as? [String: String]
                else {
                    result(FlutterError(
                        code: "setHttpHeadersError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    result(nil)
                    return
                }
                
                NSLog("setHttpHeaders called with headers: \(headers)")
                
                // Create a new session configuration
                let sessionConfig = URLSessionConfiguration.default
                
                // Start with the headers from the arguments
                var allHeaders = headers
                
                // Add our API key if it exists
                if let apiKey = Self.apiKey, !apiKey.isEmpty {
                    allHeaders["Authorization"] = "Bearer \(apiKey)"
                    NSLog("Adding API key to headers in setHttpHeaders: Bearer \(apiKey)")
                    
                    // Also update the URL protocol
                    AuthorizationURLProtocol.apiKey = apiKey
                }
                
                // Set the headers
                sessionConfig.httpAdditionalHeaders = allHeaders
                
                // Register our URL protocol with this configuration
                var protocolClasses = sessionConfig.protocolClasses ?? []
                if !protocolClasses.contains(where: { $0 == AuthorizationURLProtocol.self }) {
                    protocolClasses.insert(AuthorizationURLProtocol.self, at: 0)
                    sessionConfig.protocolClasses = protocolClasses
                    NSLog("Added AuthorizationURLProtocol to session configuration")
                }
                
                // Set the configuration for MapLibre
                MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
                
                // Force apply the headers
                forceApplyHeaders()
                
                // Log the current configuration
                logNetworkConfiguration()
                
                // Also register the URL protocol globally
                URLProtocol.registerClass(AuthorizationURLProtocol.self)
                
                result(nil)
            case "setApiKey":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let apiKey = arguments["apiKey"] as? String
                else {
                    result(FlutterError(
                        code: "setApiKeyError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                
                Self.setGlobalApiKey(apiKey)
                result(true)
            case "installOfflineMapTiles":
                guard let arguments = methodCall.arguments as? [String: String] else { return }
                let tilesdb = arguments["tilesdb"]
                installOfflineMapTiles(registrar: registrar, tilesdb: tilesdb!)
                result(nil)
            case "downloadOfflineRegion#setup":
                guard let args = methodCall.arguments as? [String: Any],
                      let channelName = args["channelName"] as? String
                else {
                    print(
                        "downloadOfflineRegion#setup unexpected arguments: \(String(describing: methodCall.arguments))"
                    )
                    result(nil)
                    return
                }

                downloadOfflineRegionChannelHandler = OfflineChannelHandler(
                    messenger: registrar.messenger(),
                    channelName: channelName
                )

                result(nil)
            case "downloadOfflineRegion":
                guard let args = methodCall.arguments as? [String: Any],
                      let definitionDictionary = args["definition"] as? [String: Any],
                      let metadata = args["metadata"] as? [String: Any],
                      let defintion = OfflineRegionDefinition.fromDictionary(definitionDictionary)
                else {
                    print(
                        "downloadOfflineRegion unexpected arguments: \(String(describing: methodCall.arguments))"
                    )
                    result(nil)
                    return
                }

                if (downloadOfflineRegionChannelHandler == nil) {
                    result(FlutterError(
                        code: "downloadOfflineRegion#setup NOT CALLED",
                        message: "The setup has not been called, please call downloadOfflineRegion#setup before",
                        details: nil
                    ))
                    return
                }

                OfflineManagerUtils.downloadRegion(
                    definition: defintion,
                    metadata: metadata,
                    result: result,
                    registrar: registrar,
                    channelHandler: downloadOfflineRegionChannelHandler!
                )
                downloadOfflineRegionChannelHandler = nil;
            case "setOfflineTileCountLimit":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let limit = arguments["limit"] as? UInt64
                else {
                    result(FlutterError(
                        code: "SetOfflineTileCountLimitError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                OfflineManagerUtils.setOfflineTileCountLimit(result: result, maximumCount: limit)
            case "getListOfRegions":
                OfflineManagerUtils.regionsList(result: result)
            case "deleteOfflineRegion":
                guard let args = methodCall.arguments as? [String: Any],
                      let id = args["id"] as? Int
                else {
                    result(nil)
                    return
                }
                OfflineManagerUtils.deleteRegion(result: result, id: id)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func getTilesUrl() -> URL {
        guard var cachesUrl = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first,
            let bundleId = Bundle.main
            .object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String
        else {
            fatalError("Could not get map tiles directory")
        }
        cachesUrl.appendPathComponent(bundleId)
        cachesUrl.appendPathComponent(".mapbox")
        cachesUrl.appendPathComponent("cache.db")
        return cachesUrl
    }

    private static func installOfflineMapTiles(registrar: FlutterPluginRegistrar, tilesdb: String) {
        var tilesUrl = getTilesUrl()
        let bundlePath = getTilesDbPath(registrar: registrar, tilesdb: tilesdb)
        NSLog(
            "Cached tiles not found, copying from bundle... \(String(describing: bundlePath)) ==> \(tilesUrl)"
        )
        do {
            let parentDir = tilesUrl.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: parentDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            if FileManager.default.fileExists(atPath: tilesUrl.path) {
                try FileManager.default.removeItem(atPath: tilesUrl.path)
            }
            try FileManager.default.copyItem(atPath: bundlePath!, toPath: tilesUrl.path)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try tilesUrl.setResourceValues(resourceValues)
        } catch {
            NSLog("Error copying bundled tiles: \(error)")
        }
    }

    private static func getTilesDbPath(registrar: FlutterPluginRegistrar,
                                       tilesdb: String) -> String?
    {
        if tilesdb.starts(with: "/") {
            return tilesdb
        } else {
            let key = registrar.lookupKey(forAsset: tilesdb)
            return Bundle.main.path(forResource: key, ofType: nil)
        }
    }
}

