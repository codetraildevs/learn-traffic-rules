# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep reflection-based classes
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep serialization classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep model classes for JSON serialization
-keep class com.trafficrules.master.models.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep HTTP client classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep file picker classes
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep notification classes
-keep class com.dexterous.** { *; }

# Keep device info classes
-keep class com.trafficrules.master.** { *; }

# Keep Google Play Core classes (required for deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# General Android rules
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Suppress warnings for deprecated APIs
-dontwarn android.content.pm.PackageManager
-dontwarn android.view.WindowManager
-dontwarn android.view.Display
-dontwarn android.os.Build
-dontwarn java.lang.reflect.Method
-dontwarn java.lang.reflect.Field

# Keep deprecated methods that are still used
-keep class android.content.pm.PackageManager {
    public android.content.pm.PackageInfo getPackageInfo(java.lang.String, int);
}

-keep class android.view.WindowManager {
    public android.view.Display getDefaultDisplay();
}

-keep class android.view.Display {
    public void getRealMetrics(android.util.DisplayMetrics);
    public void getMetrics(android.util.DisplayMetrics);
}

-keep class android.os.Build {
    public static final java.lang.String SERIAL;
}
