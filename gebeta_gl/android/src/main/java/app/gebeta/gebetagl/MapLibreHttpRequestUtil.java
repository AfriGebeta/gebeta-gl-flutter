package app.gebeta.gebetagl;

import org.maplibre.android.module.http.HttpRequestUtil;
import io.flutter.plugin.common.MethodChannel;
import java.util.Map;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import android.util.Log;

abstract class MapLibreHttpRequestUtil {
  private static final String TAG = "MapLibreHttpRequestUtil";

  public static void setHttpHeaders(Map<String, String> headers, MethodChannel.Result result) {
    if (headers == null || headers.isEmpty()) {
      Log.w(TAG, "No headers provided to setHttpHeaders");
      if (result != null) {
        result.success(null);
      }
      return;
    }
    
    try {
      OkHttpClient.Builder clientBuilder = getOkHttpClient(headers);
      if (clientBuilder != null) {
        HttpRequestUtil.setOkHttpClient(clientBuilder.build());
        Log.i(TAG, "HTTP headers set successfully");
      }
      
      if (result != null) {
        result.success(null);
      }
    } catch (Exception e) {
      Log.e(TAG, "Error setting HTTP headers: " + e.getMessage());
      if (result != null) {
        result.error("HTTP_HEADERS_ERROR", "Failed to set HTTP headers: " + e.getMessage(), null);
      }
    }
  }

  private static OkHttpClient.Builder getOkHttpClient(Map<String, String> headers) {
    try {
      return new OkHttpClient.Builder()
          .addNetworkInterceptor(
              chain -> {
                Request.Builder builder = chain.request().newBuilder();
                for (Map.Entry<String, String> header : headers.entrySet()) {
                  if (header.getKey() == null || header.getKey().trim().isEmpty()) {
                    continue;
                  }
                  if (header.getValue() == null || header.getValue().trim().isEmpty()) {
                    builder.removeHeader(header.getKey());
                  } else {
                    builder.header(header.getKey(), header.getValue());
                  }
                }
                return chain.proceed(builder.build());
              });
    } catch (Exception e) {
      Log.e(TAG, "Error creating OkHttpClient: " + e.getMessage());
      return null;
    }
  }
}
