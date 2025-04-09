package app.gebeta.gebetagl;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;

public class GebetaGlPlugin implements FlutterPlugin {
  private MethodChannel channel;
  private GlobalMethodHandler methodHandler;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "app.gebeta.gebetagl");
    methodHandler = new GlobalMethodHandler(binding);
    channel.setMethodCallHandler(methodHandler);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
} 