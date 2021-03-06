package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;

/**
 * Generated file. Do not edit.
 * This file is generated by the Flutter tool based on the
 * plugins that support the Android platform.
 */
@Keep
public final class GeneratedPluginRegistrant {
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(flutterEngine);
    flutterEngine.getPlugins().add(new io.flutter.plugins.camera.CameraPlugin());
      com.example.cn21base.Cn21basePlugin.registerWith(shimPluginRegistry.registrarFor("com.example.cn21base.Cn21basePlugin"));
    flutterEngine.getPlugins().add(new io.flutter.plugins.connectivity.ConnectivityPlugin());
    flutterEngine.getPlugins().add(new io.flutter.plugins.deviceinfo.DeviceInfoPlugin());
    flutterEngine.getPlugins().add(new com.pauldemarco.flutter_blue.FlutterBluePlugin());
      com.idlefish.flutterboost.FlutterBoostPlugin.registerWith(shimPluginRegistry.registrarFor("com.idlefish.flutterboost.FlutterBoostPlugin"));
    flutterEngine.getPlugins().add(new io.github.ponnamkarthik.toast.fluttertoast.FlutterToastPlugin());
    flutterEngine.getPlugins().add(new io.flutter.plugins.pathprovider.PathProviderPlugin());
      com.cn21.network.restfulapi.RestfulClientPlugin.registerWith(shimPluginRegistry.registrarFor("com.cn21.network.restfulapi.RestfulClientPlugin"));
    flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
    flutterEngine.getPlugins().add(new com.tekartik.sqflite.SqflitePlugin());
      com.cn21.app.navigation.flutter.UniRouterPlugin.registerWith(shimPluginRegistry.registrarFor("com.cn21.app.navigation.flutter.UniRouterPlugin"));
    flutterEngine.getPlugins().add(new io.flutter.plugins.videoplayer.VideoPlayerPlugin());
  }
}
