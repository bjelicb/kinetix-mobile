# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Isar classes
-keep class dev.isar.** { *; }
-keep class * extends dev.isar.IsarCollection { *; }

# Keep Dio classes
-keep class dio.** { *; }
-keep class retrofit2.** { *; }

# Keep Riverpod generated classes
-keep class * extends *Provider { *; }
-keep class * extends *Notifier { *; }

# Keep JSON serializable classes
-keepattributes *Annotation*, EnclosingMethod
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
