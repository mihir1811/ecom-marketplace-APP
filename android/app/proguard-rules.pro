# Live shows (livekit_client / flutter_webrtc): R8 must not strip the
# WebRTC classes reached through JNI in release builds.
-keep class org.webrtc.** { *; }
-keep class io.livekit.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn org.webrtc.**

# Razorpay checkout (rules from the razorpay_flutter README). The SDK calls
# its payment callbacks by name, so they must survive shrinking.
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Strip verbose/debug/info android.util.Log calls from release bytecode.
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Crashlytics: keep file/line info and custom exception names readable.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
