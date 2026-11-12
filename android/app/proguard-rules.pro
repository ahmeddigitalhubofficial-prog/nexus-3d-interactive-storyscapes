# Flutter Keep Rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase Keep Rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Camera
-keep class io.flutter.plugins.camera.** { *; }

# Play Core (Deferred Components)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
