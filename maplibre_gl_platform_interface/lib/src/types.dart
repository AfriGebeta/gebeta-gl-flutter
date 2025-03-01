// A callback function that can transform tile requests by modifying URLs and adding headers
typedef TransformRequestCallback = Map<String, dynamic> Function(String url, String resourceType); 