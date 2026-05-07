# Gson TypeToken: R8이 제네릭 타입 정보를 제거하면 Missing type parameter 발생
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*

# flutter_local_notifications 예약 알림 캐시 역직렬화
-keep class com.dexterous.flutterlocalnotifications.** { *; }
