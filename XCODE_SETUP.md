# Xcode 프로젝트 설정 가이드

## 현재 문제

SnappingManager.swift에서 다음 에러 발생:
- ❌ Cannot find type 'CustomZone' in scope
- ❌ Cannot find 'CustomLayoutManager' in scope

**원인**: CustomLayout 폴더의 Swift 파일들이 Xcode 프로젝트에 추가되지 않음

---

## 해결 방법 (5분 소요)

### Step 1: Xcode에서 프로젝트 열기

1. Finder에서 다음 경로로 이동:
   ```
   /Users/jd/code/rectangle/Rectangle/
   ```

2. `Rectangle.xcodeproj` 더블클릭하여 Xcode 실행

### Step 2: CustomLayout 파일들을 프로젝트에 추가

1. **Xcode 메뉴**: `File` → `Add Files to "Rectangle"...`

2. 파일 선택 다이얼로그에서:
   - 경로: `/Users/jd/code/rectangle/Rectangle/Rectangle/CustomLayout/`
   - 다음 파일들 **전부 선택** (⌘ + 클릭으로 다중 선택):
     ```
     ✅ CustomLayoutModel.swift
     ✅ LayoutEditorView.swift
     ✅ LayoutEditorViewModel.swift
     ✅ LayoutManagerView.swift
     ✅ CustomLayoutDefaults.swift
     ```

3. 하단 옵션 설정:
   ```
   ✅ Copy items if needed           ← 체크 해제!
   ✅ Create groups                  ← 선택
   ✅ Add to targets: Rectangle      ← 체크!
   ```

4. **"Add"** 버튼 클릭

### Step 3: 파일 추가 확인

Xcode 좌측 네비게이터에서 확인:
```
Rectangle
├── Rectangle
│   ├── CustomLayout          ← 새로 생긴 폴더
│   │   ├── CustomLayoutModel.swift
│   │   ├── LayoutEditorView.swift
│   │   ├── LayoutEditorViewModel.swift
│   │   ├── LayoutManagerView.swift
│   │   └── CustomLayoutDefaults.swift
│   ├── Snapping
│   │   └── SnappingManager.swift
│   └── ...
```

### Step 4: SwiftUI 프레임워크 추가

1. Xcode 좌측에서 **Rectangle 프로젝트** (파란 아이콘) 클릭

2. **TARGETS** → **Rectangle** 선택

3. **General** 탭 선택

4. 아래로 스크롤하여 **"Frameworks, Libraries, and Embedded Content"** 섹션 찾기

5. **`+`** 버튼 클릭

6. 검색창에 `SwiftUI` 입력

7. **SwiftUI.framework** 선택 후 **Add** 클릭

8. Status 컬럼이 **"Do Not Embed"**로 설정되어 있는지 확인

### Step 5: 빌드 테스트

1. **⌘ + B** (Product → Build) 눌러서 빌드

2. 에러 확인:
   - ✅ CustomZone, CustomLayoutManager 에러 사라짐
   - ⚠️ 다른 에러가 있다면 아래 "추가 에러 해결" 참조

### Step 6: 실행 테스트

1. **⌘ + R** (Product → Run) 눌러서 실행

2. 메뉴바에 앱 아이콘 확인

3. 환경설정 열기 (아이콘 클릭 → Preferences)

---

## 추가 에러 해결

### Error: "Missing arguments for parameters 'subAction', 'count'"
**파일**: SnappingManager.swift 라인 567 근처

**원인**: RectangleAction 초기화 파라미터 불일치

**해결**: 다음과 같이 수정
```swift
// 기존 (잘못됨)
AppDelegate.windowHistory.lastRectangleActions[windowId] = RectangleAction(
    action: .specified,
    rect: finalRect,
    visibleFrameOfScreen: screen.adjustedVisibleFrame()
)

// 수정
AppDelegate.windowHistory.lastRectangleActions[windowId] = RectangleAction(
    action: .specified,
    rect: finalRect,
    visibleFrameOfScreen: screen.adjustedVisibleFrame(),
    subAction: nil
)
```

---

### Error: "Extra argument 'visibleFrameOfScreen'"
**파일**: SnappingManager.swift

**원인**: RectangleAction 구조체 정의 확인 필요

**해결**: Rectangle의 WindowHistory.swift에서 RectangleAction 정의 확인 후 맞춰 수정

---

### Error: "Value of type 'NSScreen' has no member 'adjustedVisibleFrame'"
**파일**: SnappingManager.swift, CustomLayoutModel.swift

**원인**: Rectangle의 NSScreen extension 찾지 못함

**해결**:
1. 옵션 A - Rectangle 기존 extension 사용 (권장)
   - Rectangle 프로젝트에 이미 구현되어 있어야 함
   - Utilities/ 폴더 확인

2. 옵션 B - 임시로 간단한 구현 추가
   ```swift
   extension NSScreen {
       func adjustedVisibleFrame(_ ignoreTodo: Bool = false) -> CGRect {
           return self.visibleFrame
       }
   }
   ```

---

## 빌드 성공 후 다음 단계

### 1. 기능 테스트

**기본 기능 (기존 Rectangle)**
- ✅ 윈도우 드래그 → 화면 가장자리 스냅
- ✅ 키보드 단축키 (⌃⌥ 화살표)
- ✅ 환경설정 열기

**커스텀 레이아웃 (새 기능)**
1. 환경설정 열기
2. "Custom Layouts" 탭 확인 (없으면 아래 참조)
3. "Create New Layout" 클릭
4. 에디터 창 열림 확인
5. Zone 추가/드래그 테스트
6. 저장 후 목록 확인

**Shift 드래그 스냅**
1. 레이아웃 활성화
2. 아무 윈도우나 드래그 시작
3. **Shift 키 누르기**
4. Zone 하이라이트 확인
5. 마우스 릴리즈 → 스냅 확인

### 2. Custom Layouts 탭이 보이지 않는 경우

환경설정에 탭을 추가해야 합니다:

**방법 A - Storyboard 수정 (권장)**
1. Xcode에서 `Main.storyboard` 열기
2. Preferences Window Controller 찾기
3. Tab View Controller에 새 탭 추가:
   - Title: "Custom Layouts"
   - View Controller: LayoutManagerView (SwiftUI)

**방법 B - 별도 윈도우로 열기**
1. AppDelegate.swift에 메서드 추가:
   ```swift
   @IBAction func openCustomLayouts(_ sender: Any) {
       let hostingController = NSHostingController(rootView: LayoutManagerView())
       let window = NSWindow(contentViewController: hostingController)
       window.title = "Custom Layouts"
       window.setContentSize(NSSize(width: 900, height: 600))
       window.styleMask = [.titled, .closable, .resizable]
       window.center()
       window.makeKeyAndOrderFront(nil)
   }
   ```

2. Main.storyboard에서 메뉴 아이템 추가:
   - Menu: Rectangle → "Custom Layouts..."
   - Action: openCustomLayouts:

---

## 문제 해결 체크리스트

빌드 에러가 계속된다면:

### 파일 추가 확인
- [ ] CustomLayout 폴더가 Xcode 네비게이터에 보임
- [ ] 5개 Swift 파일 모두 추가됨
- [ ] 파일 오른쪽에 타겟 체크박스 확인 (Inspector)

### 타겟 멤버십 확인
1. 파일 하나 선택 (예: CustomLayoutModel.swift)
2. 오른쪽 **File Inspector** (⌥⌘1) 열기
3. **Target Membership** 섹션에서:
   - [ ] ✅ Rectangle (체크됨)
   - [ ] ❌ RectangleLauncher (체크 안 됨)
   - [ ] ❌ RectangleTests (체크 안 됨)

### 빌드 설정 확인
1. 프로젝트 설정 → Build Settings
2. 검색: "Swift Language Version"
3. 값: Swift 5 이상
4. Deployment Target: macOS 12.0 이상

---

## 대안: 터미널에서 파일 추가 (고급)

GUI 사용이 어렵다면:

```bash
# Xcode 프로젝트 파일 백업
cp Rectangle.xcodeproj/project.pbxproj Rectangle.xcodeproj/project.pbxproj.backup

# Python 스크립트로 자동 추가 (직접 실행 권장하지 않음)
# 대신 Xcode GUI 사용하세요!
```

---

## 최종 확인

빌드 성공 후:

```bash
# 1. 빌드 성공
✅ Build succeeded - 0 errors, 0 warnings

# 2. 앱 실행
✅ App runs without crash

# 3. 메뉴바 아이콘
✅ Icon appears in menu bar

# 4. 환경설정
✅ Preferences window opens

# 5. 커스텀 레이아웃
✅ "Custom Layouts" accessible
✅ Editor opens
✅ Zones can be created

# 6. Shift 드래그
✅ Shift + Drag shows zones
✅ Windows snap to custom zones
```

---

## 도움이 필요하면

1. **에러 메시지 전체** 복사해서 보내주세요
2. **어느 파일 몇 번째 줄**인지 알려주세요
3. 스크린샷 첨부하면 더 좋습니다

---

**작성일**: 2026-01-02
**예상 소요 시간**: 5-10분
