# InsightBoard - Complete Android Setup Fix
# This script: deletes android/, regenerates it, adds Firebase + desugaring
Write-Host "=== InsightBoard Complete Fix ===" -ForegroundColor Cyan

# Step 1: Delete android folder completely
Write-Host "`n[1/5] Deleting android folder..." -ForegroundColor Yellow
if (Test-Path "android") { Remove-Item -Recurse -Force "android" }
Write-Host "  Done." -ForegroundColor Green

# Step 2: Flutter clean
Write-Host "`n[2/5] Flutter clean..." -ForegroundColor Yellow
flutter clean 2>$null

# Step 3: Regenerate android folder
Write-Host "`n[3/5] Regenerating android folder..." -ForegroundColor Yellow
flutter create . --project-name insightboard --org com.insightboard 2>$null
Write-Host "  Done." -ForegroundColor Green

# Step 4: Modify android files for Firebase + desugaring
Write-Host "`n[4/5] Applying Firebase + desugaring config..." -ForegroundColor Yellow

# --- Fix android/settings.gradle.kts: Add google-services plugin ---
$settingsFile = "android/settings.gradle.kts"
if (Test-Path $settingsFile) {
    $content = Get-Content $settingsFile -Raw
    if ($content -notmatch "google-services") {
        $content = $content -replace '(id\("com\.android\.application"\)\s+version\s+"[^"]+"\s+apply\s+false)', "`$1`n    id(`"com.google.gms.google-services`") version `"4.4.0`" apply false"
        Set-Content $settingsFile $content -NoNewline
        Write-Host "  settings.gradle.kts: Added google-services plugin" -ForegroundColor Gray
    }
}

# --- Fix android/app/build.gradle.kts: Add Firebase + desugaring ---
$appBuildFile = "android/app/build.gradle.kts"
if (Test-Path $appBuildFile) {
    $content = Get-Content $appBuildFile -Raw

    # Add google-services plugin
    if ($content -notmatch "google-services") {
        $content = $content -replace '(id\("dev\.flutter\.flutter-gradle-plugin"\))', "`$1`n    id(`"com.google.gms.google-services`")"
        Write-Host "  app/build.gradle.kts: Added google-services plugin" -ForegroundColor Gray
    }

    # Add coreLibraryDesugaring to compileOptions
    if ($content -notmatch "isCoreLibraryDesugaringEnabled") {
        $content = $content -replace '(compileOptions\s*\{)', "`$1`n        isCoreLibraryDesugaringEnabled = true"
        Write-Host "  app/build.gradle.kts: Added coreLibraryDesugaring option" -ForegroundColor Gray
    }

    # Set minSdk to 23
    $content = $content -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23'
    Write-Host "  app/build.gradle.kts: Set minSdk = 23" -ForegroundColor Gray

    # Add multiDexEnabled
    if ($content -notmatch "multiDexEnabled") {
        $content = $content -replace '(versionName\s*=\s*flutter\.versionName)', "`$1`n        multiDexEnabled = true"
        Write-Host "  app/build.gradle.kts: Added multiDexEnabled" -ForegroundColor Gray
    }

    # Add dependencies block or append to existing
    if ($content -notmatch "firebase-bom") {
        if ($content -match "dependencies\s*\{") {
            $content = $content -replace '(dependencies\s*\{)', "`$1`n    implementation(platform(`"com.google.firebase:firebase-bom:32.7.0`"))`n    implementation(`"com.google.firebase:firebase-analytics`")`n    coreLibraryDesugaring(`"com.android.tools:desugar_jdk_libs:2.0.4`")"
        } else {
            $content += "`n`ndependencies {`n    implementation(platform(`"com.google.firebase:firebase-bom:32.7.0`"))`n    implementation(`"com.google.firebase:firebase-analytics`")`n    coreLibraryDesugaring(`"com.android.tools:desugar_jdk_libs:2.0.4`")`n}`n"
        }
        Write-Host "  app/build.gradle.kts: Added Firebase BOM + desugaring deps" -ForegroundColor Gray
    }

    Set-Content $appBuildFile $content -NoNewline
}

# Step 5: Flutter pub get
Write-Host "`n[5/5] Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n=== All Done! ===" -ForegroundColor Green
Write-Host "Now run: flutter run" -ForegroundColor Cyan
