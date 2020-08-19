package com.cn21.example

import android.os.Bundle
import com.cn21.example.platform.MethodChannelExExample

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    MethodChannelExExample.registerWith(this.registrarFor("MethodChannelExExample"))
  }
}
