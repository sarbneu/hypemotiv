# ML Kit's acceleration library pulls in WorkManager/Room. Keep their generated
# classes so the release build can create WorkDatabase on first launch.
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
