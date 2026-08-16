# ==========================================
# TensorFlow Lite ProGuard / R8 Rules
# ==========================================
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# ==========================================
# Isar Database ProGuard / R8 Rules
# ==========================================
-dontwarn io.isar.**
-keep class io.isar.** { *; }

# ==========================================
# Google ML Kit ProGuard / R8 Rules
# ==========================================
-dontwarn com.google.mlkit.**
-dontwarn com.google_mlkit_commons.**
-dontwarn com.google_mlkit_face_detection.**
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# ==========================================
# General Flutter / Kotlin ProGuard Rules
# ==========================================
-dontwarn io.flutter.**
-dontwarn kotlin.**
-keep class io.flutter.** { *; }
