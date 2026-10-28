# Live shows (livekit_client / flutter_webrtc): R8 must not strip the
# WebRTC classes reached through JNI in release builds.
-keep class org.webrtc.** { *; }
-keep class io.livekit.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn org.webrtc.**
