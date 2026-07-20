# Flutter / plugin keep rules for R8 release shrinking.

# Flutter engine & embedding.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_tts (accesses Android TextToSpeech via the plugin).
-keep class com.tundralabs.fluttertts.** { *; }

# audioplayers.
-keep class xyz.luan.audioplayers.** { *; }

# Kotlin metadata sometimes read reflectively by plugins.
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
