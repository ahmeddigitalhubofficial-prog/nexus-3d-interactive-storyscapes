package com.interactive.story.interactive_story_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.interactive.story/test_lab"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isTestLab") {
                val testLabSetting = Settings.System.getString(contentResolver, "firebase.test.lab")
                result.success("true" == testLabSetting)
            } else {
                result.notImplemented()
            }
        }
    }
}
