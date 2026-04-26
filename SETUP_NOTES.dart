// ==============================================
// ANDROID CONFIGURATION — android/app/build.gradle
// ==============================================
// Add these to your android/app/build.gradle:
//
// android {
//     compileSdk 34
//     
//     defaultConfig {
//         applicationId "com.insightboard.app"
//         minSdk 23
//         targetSdk 34
//         versionCode 1
//         versionName "1.0.0"
//         multiDexEnabled true
//     }
// }
//
// dependencies {
//     implementation platform('com.google.firebase:firebase-bom:32.7.0')
// }

// ==============================================
// ANDROID CONFIGURATION — android/build.gradle
// ==============================================
// Make sure you have:
//
// buildscript {
//     dependencies {
//         classpath 'com.google.gms:google-services:4.4.0'
//     }
// }

// ==============================================
// IOS CONFIGURATION — ios/Podfile
// ==============================================
// Set minimum deployment target:
// platform :ios, '14.0'
//
// In Runner/Info.plist add:
// <key>NSPhotoLibraryUsageDescription</key>
// <string>InsightBoard needs access to save exported reports</string>

// ==============================================
// FIREBASE SETUP COMMANDS
// ==============================================
// 1. Install FlutterFire CLI:
//    dart pub global activate flutterfire_cli
//
// 2. Configure Firebase:
//    flutterfire configure
//
// 3. This generates firebase_options.dart automatically
//
// 4. Update main.dart to use:
//    await Firebase.initializeApp(
//      options: DefaultFirebaseOptions.currentPlatform,
//    );
