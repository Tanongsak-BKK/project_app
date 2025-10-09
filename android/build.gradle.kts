// android/build.gradle.kts

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
    id("com.google.gms.google-services") apply false
}

/* ✅ ให้ปลั๊กอินของ third-party (เช่น cloud_firestore) อ่านค่าจาก rootProject.ext ได้เหมือนเดิม */
extra["compileSdkVersion"] = 34
extra["minSdkVersion"] = 23
extra["targetSdkVersion"] = 34
extra["kotlinVersion"] = "1.9.24"   // เผื่อปลั๊กอินต้องอ่าน
extra["ndkVersion"] = "26.1.10909125" // ถ้าไม่รู้ค่า ปล่อยหรือคอมเมนต์ได้

// (ไม่ต้องมี buildscript { classpath(...) } แบบ Groovy อีกแล้ว)
