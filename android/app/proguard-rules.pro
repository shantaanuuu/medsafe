# Keep ML Kit Text Recognition classes to prevent R8 minification errors
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
