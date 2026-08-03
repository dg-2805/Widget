# WorkManager / Room generated implementations
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public <init>();
}
-dontwarn androidx.work.**