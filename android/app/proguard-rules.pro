# ==============================================================================
# NEXA Player — Proguard & R8 Release Optimization Rules
# ==============================================================================

# 1. Flutter Engine & Platform Channels
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# 2. SQLite3 Native Bindings (sqlite3_flutter_libs)
-keep class org.sqlite.** { *; }
-keep class com.simonbinder.sqlite3_flutter_libs.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# 3. AudioService & MediaBrowser Foreground Architecture
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.AudioAttributesCompat { *; }
-keep class androidx.media.session.MediaButtonReceiver { *; }

# 4. Android Automotive & MediaSession Interop
-keep class com.google.android.gms.car.** { *; }
-keep class androidx.car.app.** { *; }

# 5. Serialization & Safe JSON Monads
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn okio.**
-dontwarn javax.annotation.**
