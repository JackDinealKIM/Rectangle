# Bundle Identifier 변경 가이드

## 현재 상태

### ✅ 코드 레벨 변경 완료
- Info.plist에 CFBundleDisplayName = "ZoneSnap" 추가
- FootprintWindow.swift: title = "ZoneSnap"
- Config.swift: bundleId = "com.zonesnap.ZoneSnap"
- Config.swift: 설정 폴더 = "ZoneSnap"
- Config.swift: 설정 파일명 = "ZoneSnapConfig.json"
- SettingsViewController.swift: UI 텍스트 "ZoneSnap"

### ❌ 아직 변경 필요 (Xcode에서)
- PRODUCT_BUNDLE_IDENTIFIER = "com.knollsoft.Rectangle" → "com.zonesnap.ZoneSnap"

---

## Xcode에서 Bundle Identifier 변경하기

### 방법 1: GUI로 변경 (권장)

#### Step 1: 프로젝트 열기
```bash
cd /Users/jd/code/rectangle/Rectangle
open Rectangle.xcodeproj
```

#### Step 2: Rectangle 타겟 설정
1. **좌측 Project Navigator**에서 **Rectangle** 프로젝트 (파란 아이콘) 클릭
2. **TARGETS** 섹션에서 **Rectangle** 선택
3. **General** 탭 클릭
4. **Identity** 섹션에서 **Bundle Identifier** 찾기
5. 현재 값: `com.knollsoft.Rectangle`
6. **변경할 값** (선택):
   - **옵션 A** (권장): `com.zonesnap.ZoneSnap`
   - **옵션 B**: `com.yourname.ZoneSnap` (본인 도메인)
   - **옵션 C**: `com.knollsoft.ZoneSnap` (기존 도메인 유지)

#### Step 3: RectangleLauncher 타겟 설정
1. TARGETS에서 **RectangleLauncher** 선택
2. General → Bundle Identifier 변경
3. 추천 값:
   - Rectangle이 `com.zonesnap.ZoneSnap`이면
   - Launcher는 `com.zonesnap.ZoneSnapLauncher`

#### Step 4: 빌드 및 테스트
```bash
# Clean Build
⇧⌘K (Shift + Command + K)

# Rebuild
⌘B (Command + B)

# Run
⌘R (Command + R)
```

---

### 방법 2: project.pbxproj 직접 편집 (고급 사용자)

**⚠️ 경고: Xcode가 닫혀있을 때만 수정하세요!**

```bash
# Xcode 종료 확인
killall Xcode

# 백업
cp Rectangle.xcodeproj/project.pbxproj Rectangle.xcodeproj/project.pbxproj.backup

# 변경 (sed 사용)
sed -i '' 's/com\.knollsoft\.Rectangle/com.zonesnap.ZoneSnap/g' Rectangle.xcodeproj/project.pbxproj
sed -i '' 's/com\.knollsoft\.RectangleLauncher/com.zonesnap.ZoneSnapLauncher/g' Rectangle.xcodeproj/project.pbxproj

# Xcode 다시 열기
open Rectangle.xcodeproj
```

---

## 변경 후 확인사항

### 1. Xcode에서 확인
- [ ] Rectangle 타겟 → General → Bundle Identifier = `com.zonesnap.ZoneSnap`
- [ ] RectangleLauncher 타겟 → General → Bundle Identifier = `com.zonesnap.ZoneSnapLauncher`

### 2. 빌드 성공 확인
```bash
# Clean + Build
⇧⌘K, ⌘B
```
**예상 결과**: Build Succeeded

### 3. 실행 후 확인
```bash
# Run
⌘R
```

**확인 항목**:
- [ ] 메뉴바에 앱 아이콘 표시
- [ ] 아이콘 클릭 → "ZoneSnap" 메뉴 표시
- [ ] About 메뉴 → "About ZoneSnap" 표시 (Info.plist의 CFBundleDisplayName)
- [ ] 환경설정 정상 작동

### 4. 설정 파일 경로 확인
```bash
# 새 설정 위치 (자동 생성됨)
ls ~/Library/Preferences/com.zonesnap.ZoneSnap.plist

# 새 Support 폴더 (필요시 생성)
ls ~/Library/Application\ Support/ZoneSnap/
```

### 5. Activity Monitor 확인
1. **Activity Monitor** 앱 열기
2. "ZoneSnap" 검색
3. Bundle Identifier 더블클릭 → `com.zonesnap.ZoneSnap` 확인

---

## Bundle Identifier 선택 가이드

### 옵션 A: com.zonesnap.ZoneSnap (권장)
**장점**:
- 완전히 새로운 앱 정체성
- Rectangle과 동시 설치 가능
- 깔끔한 브랜딩
- 향후 zonesnap.com 도메인 구매 가능

**단점**:
- 기존 Rectangle 설정 상속 안 됨 (마이그레이션 코드 필요)
- zonesnap 도메인 소유 필요 없음 (실제로는 관례일 뿐)

### 옵션 B: com.yourname.ZoneSnap
**예시**: `com.johndoe.ZoneSnap`

**장점**:
- 개인 소유 명확
- Apple Developer 계정 이름과 일치시키기 좋음

**단점**:
- 본인 도메인이나 이름 노출

### 옵션 C: com.knollsoft.ZoneSnap
**⚠️ 비권장**

**이유**:
- knollsoft는 Ryan Hanson (Rectangle 원작자)의 도메인
- 라이선스적으로 혼동 가능
- Rectangle과 충돌 가능성

---

## 기존 Rectangle 설정 마이그레이션 (선택사항)

Bundle Identifier를 변경하면 **UserDefaults가 초기화**됩니다.

기존 사용자를 위한 마이그레이션:

### AppDelegate.swift에 추가

```swift
// AppDelegate.swift

func applicationDidFinishLaunching(_ aNotification: Notification) {
    // 기존 코드...

    // 마이그레이션 실행
    migrateFromRectangle()

    // 기존 코드 계속...
}

private func migrateFromRectangle() {
    // 이미 마이그레이션 했으면 스킵
    if UserDefaults.standard.bool(forKey: "migratedFromRectangle") {
        return
    }

    // 구 Bundle ID의 UserDefaults
    if let oldDefaults = UserDefaults(suiteName: "com.knollsoft.Rectangle") {
        let currentDefaults = UserDefaults.standard

        // 모든 설정 복사
        for (key, value) in oldDefaults.dictionaryRepresentation() {
            // 기존에 값이 없을 때만 복사 (덮어쓰기 방지)
            if currentDefaults.object(forKey: key) == nil {
                currentDefaults.set(value, forKey: key)
            }
        }

        Logger.log("Migrated settings from Rectangle")
    }

    // 마이그레이션 완료 표시
    UserDefaults.standard.set(true, forKey: "migratedFromRectangle")
}
```

---

## 문제 해결

### "Code signing entitlements file is missing"
1. Xcode → TARGETS → Rectangle → Signing & Capabilities
2. Team 선택
3. Bundle Identifier가 고유한지 확인

### "App still shows as Rectangle"
- Info.plist에 `CFBundleDisplayName` 추가했는지 확인
- Clean Build 했는지 확인
- 앱 완전히 종료 후 재실행

### "Settings are lost after changing Bundle ID"
- 정상 현상입니다
- UserDefaults 위치가 Bundle ID 기반으로 변경됨
- 위의 마이그레이션 코드 추가 권장

### "Launch on Login not working"
- RectangleLauncher의 Bundle ID도 변경했는지 확인
- AppDelegate의 `launcherAppId` 변수 확인 필요

---

## 최종 변경 사항 요약

### 파일 변경 (✅ 완료)
1. `Rectangle/Info.plist`
   - ✅ CFBundleDisplayName = "ZoneSnap"
   - ✅ CFBundleURLSchemes = "zonesnap"
   - ✅ SUFeedURL = "https://zonesnap.app/downloads/updates.xml"
   - ✅ NSHumanReadableCopyright = "Based on Rectangle by Ryan Hanson..."

2. `Rectangle/Snapping/FootprintWindow.swift`
   - ✅ title = "ZoneSnap"

3. `Rectangle/PrefsWindow/Config.swift`
   - ✅ bundleId = "com.zonesnap.ZoneSnap"
   - ✅ 폴더명 = "ZoneSnap"
   - ✅ 파일명 = "ZoneSnapConfig.json"

4. `Rectangle/PrefsWindow/SettingsViewController.swift`
   - ✅ 기본 단축키 = "ZoneSnap"
   - ✅ 설정 파일명 = "ZoneSnapConfig"

### Xcode 설정 변경 (❌ 남은 작업)
1. **Rectangle** 타겟
   - Bundle Identifier: `com.zonesnap.ZoneSnap`

2. **RectangleLauncher** 타겟
   - Bundle Identifier: `com.zonesnap.ZoneSnapLauncher`

---

## 지금 바로 실행하기

### 5분 퀵 가이드

```bash
# 1. Xcode 열기
open /Users/jd/code/rectangle/Rectangle/Rectangle.xcodeproj

# 2. Xcode에서:
# - 좌측 Rectangle 프로젝트 클릭
# - TARGETS → Rectangle 선택
# - General → Bundle Identifier
# - 변경: com.zonesnap.ZoneSnap

# - TARGETS → RectangleLauncher 선택
# - General → Bundle Identifier
# - 변경: com.zonesnap.ZoneSnapLauncher

# 3. 빌드
⇧⌘K (Clean)
⌘B (Build)
⌘R (Run)

# 4. 확인
# 메뉴바 아이콘 클릭 → "ZoneSnap" 표시 확인
```

---

**작성일**: 2026-01-02
**목적**: Rectangle → ZoneSnap Bundle Identifier 변경
