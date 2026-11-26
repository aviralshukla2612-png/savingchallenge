# Keep RoomDatabase subclasses & reflective constructors (WorkManager startup)
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
-keep class androidx.work.** { *; }
-keep class * extends androidx.startup.Initializer {
    public <init>();
}

# Keep Google Play Services Dynamite, UMP consent SDK, and Flutter Google Mobile Ads plugin
# (play-services-ads:25.5.0 ships its own consumer proguard.txt for internal ads classes so R8 can shrink unused ones)
-keep class com.google.android.gms.dynamite.** { *; }
-keep class com.google.android.gms.dynamic.** { *; }
-keep class com.google.android.gms.ads.MobileAds { *; }
-keep class com.google.android.gms.ads.MobileAdsInitProvider { *; }
-keep class com.google.android.gms.ads.internal.ClientApi { <init>(); }
-keep class com.google.android.ump.** { *; }
-keep class com.google.android.gms.internal.consent_sdk.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }
-dontwarn com.google.android.gms.internal.ads.**

# Keep flutter_local_notifications & reflection metadata
-keep class com.dexterous.** { *; }
-keepattributes Signature, InnerClasses, EnclosingMethod
