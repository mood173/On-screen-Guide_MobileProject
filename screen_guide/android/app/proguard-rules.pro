# release 빌드의 코드 축소(R8)가 ML Kit 내부 클래스를 지우거나 이름을 바꾸면
# 앱이 시작하자마자 종료된다 (골격 README, 제작범위 N4).
# ML Kit는 컴포넌트 등록(ComponentRegistrar)·JNI·리플렉션으로 클래스를 찾으므로 통째로 남긴다.

# 공개 API와 컴포넌트 등록 (text-recognition-korean, entity-extraction, common, vision-common)
-keep class com.google.mlkit.** { *; }

# ML Kit가 쓰는 Play services 내부 구현 (난독화된 zz* 클래스, 내장 protobuf 포함)
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google.android.gms.common.internal.** { *; }

# JNI로 불리는 native 메서드
-keepclasseswithmembernames class * {
    native <methods>;
}

-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_**
