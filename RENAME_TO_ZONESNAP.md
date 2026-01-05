# ZoneSnap 리브랜딩 체크리스트

## 현재 상태

### ✅ 완료된 항목
1. **Info.plist**
   - ✅ URL Scheme: `zonesnap://`
   - ✅ Copyright: "Based on Rectangle by Ryan Hanson..."
   - ✅ Update URL: `https://zonesnap.app/downloads/updates.xml`

### ❌ 변경 필요 항목

1. **Bundle Identifier** (가장 중요!)
   - 현재: `com.knollsoft.Rectangle`
   - 변경: `com.zonesnap.ZoneSnap` 또는 `com.knollsoft.ZoneSnap`

2. **Product Name**
   - 현재: `Rectangle` (TARGET_NAME 기반)
   - 변경: `ZoneSnap`

3. **Display Name** (메뉴바/Dock에 표시되는 이름)
   - 확인 필요

---

## Xcode에서 변경하는 방법

### Step 1: Bundle Identifier 변경

1. **Xcode 열기**
   ```
   open Rectangle.xcodeproj
   ```

2. **프로젝트 설정 열기**
   - 좌측 네비게이터에서 **Rectangle** 프로젝트 (파란 아이콘) 클릭
   - TARGETS → **Rectangle** 선택

3. **General 탭**
   - **Bundle Identifier** 찾기
   - 현재 값: `com.knollsoft.Rectangle`
   - 새 값으로 변경:
     ```
     com.zonesnap.ZoneSnap
     ```
     또는 기존 도메인 유지:
     ```
     com.knollsoft.ZoneSnap
     ```

4. **RectangleLauncher도 변경**
   - TARGETS → **RectangleLauncher** 선택
   - Bundle Identifier 변경:
     ```
     com.zonesnap.ZoneSnapLauncher
     ```

### Step 2: Product Name 변경 (선택사항)

**방법 A: 타겟 이름 변경 (권장)**

1. TARGETS → **Rectangle** 선택
2. 타겟 이름 더블클릭
3. `ZoneSnap`으로 변경

**방법 B: Build Settings에서 PRODUCT_NAME 설정**

1. TARGETS → Rectangle 선택
2. **Build Settings** 탭
3. 검색: `Product Name`
4. **Packaging** → **Product Name** 찾기
5. 값을 `ZoneSnap`으로 변경

### Step 3: Display Name 추가 (메뉴바 표시 이름)

1. **Info.plist 열기**
   - Rectangle/Info.plist 파일 선택

2. **Bundle display name 추가**
   - 마우스 오른쪽 클릭 → Add Row
   - Key: `CFBundleDisplayName`
   - Type: String
   - Value: `ZoneSnap`

### Step 4: 소스 코드에서 "Rectangle" 문자열 변경

일부 UI 텍스트에 "Rectangle"이 하드코딩되어 있을 수 있습니다:

```bash
# 검색
grep -r "Rectangle" Rectangle/ --include="*.swift" --include="*.m" | grep -v "//.*Rectangle" | grep -v import
```

주의: 주석이나 Rectangle 프로젝트 크레딧은 유지해야 합니다!

---

## 변경 후 확인 사항

### 빌드 후 테스트

1. **Clean Build**
   ```
   ⇧⌘K (Shift + Command + K)
   ```

2. **Rebuild**
   ```
   ⌘B
   ```

3. **실행**
   ```
   ⌘R
   ```

### 확인할 것들

- [ ] 메뉴바 아이콘 클릭 → 앱 이름이 "ZoneSnap"으로 표시
- [ ] About 메뉴 → "About ZoneSnap" 표시
- [ ] Activity Monitor → 프로세스 이름 확인
- [ ] ~/Library/Preferences/com.zonesnap.ZoneSnap.plist 생성 확인

### UserDefaults 마이그레이션 (중요!)

Bundle Identifier를 변경하면 **기존 설정이 초기화**됩니다.

기존 사용자를 위해 마이그레이션 코드 추가 권장:

```swift
// AppDelegate.swift의 applicationDidFinishLaunching에 추가

func migrateFromRectangle() {
    let oldDefaults = UserDefaults(suiteName: "com.knollsoft.Rectangle")
    let newDefaults = UserDefaults.standard

    // 마이그레이션이 이미 완료되었는지 확인
    if newDefaults.bool(forKey: "migratedFromRectangle") {
        return
    }

    // 기존 설정이 있으면 복사
    if let oldDict = oldDefaults?.dictionaryRepresentation() {
        for (key, value) in oldDict {
            if newDefaults.object(forKey: key) == nil {
                newDefaults.set(value, forKey: key)
            }
        }
    }

    newDefaults.set(true, forKey: "migratedFromRectangle")
}
```

---

## 권장 Bundle Identifier

### 옵션 1: 새 도메인 (권장)
```
com.zonesnap.ZoneSnap
com.zonesnap.ZoneSnapLauncher
```

**장점**:
- 완전히 새로운 앱으로 인식
- Rectangle과 동시 설치 가능
- 깔끔한 브랜딩

**단점**:
- 기존 설정 마이그레이션 필요

### 옵션 2: 기존 도메인 유지
```
com.knollsoft.ZoneSnap
com.knollsoft.ZoneSnapLauncher
```

**장점**:
- 기존 Rectangle 사용자의 설정 일부 유지 가능
- 전환이 부드러움

**단점**:
- knollsoft 도메인 사용 (Rectangle 원작자 도메인)
- 라이선스적으로 애매할 수 있음

### 옵션 3: 본인 도메인
```
com.yourname.ZoneSnap
com.yourname.ZoneSnapLauncher
```

**가장 권장**: 본인 도메인이나 회사 도메인 사용!

---

## 주의사항

### MIT 라이선스 준수
- ✅ Rectangle 크레딧은 Info.plist와 문서에 유지
- ✅ LICENSE 파일 유지
- ✅ "Based on Rectangle" 문구 필수

### 변경하면 안 되는 것
- ❌ 소스 코드 주석의 "Rectangle" (역사적 기록)
- ❌ 원본 LICENSE 파일
- ❌ 크레딧/저작권 표시

### 변경해야 하는 것
- ✅ Bundle Identifier
- ✅ 사용자에게 보이는 앱 이름
- ✅ URL Scheme (이미 완료)
- ✅ 업데이트 서버 URL (이미 완료)

---

## 빠른 실행 가이드

**지금 당장 해야 할 것 (5분)**:

1. Xcode 열기
2. Rectangle 타겟 선택
3. General → Bundle Identifier → `com.zonesnap.ZoneSnap`
4. Info.plist → Add Row → `CFBundleDisplayName` = `ZoneSnap`
5. Clean Build (⇧⌘K) 후 Rebuild (⌘B)
6. 실행 (⌘R)
7. 메뉴바에서 앱 이름 확인

---

**작성일**: 2026-01-02
**목적**: Rectangle → ZoneSnap 리브랜딩
