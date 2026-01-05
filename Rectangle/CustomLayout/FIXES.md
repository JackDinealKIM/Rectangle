# ZoneSnap - 컴파일 에러 수정 내역

## 수정 사항

### 1. CustomLayoutSnapping.swift 삭제
**문제**: SnappingManager에서 CustomZone, customLayoutZoneContainingCursor, snapToCustomZone을 찾을 수 없음

**원인**:
- CustomLayoutSnapping.swift는 extension으로 작성되었으나 별도 파일이라 컴파일 타임에 타입을 찾지 못함
- Swift는 extension 메서드가 다른 파일에 있어도 import만 되면 찾을 수 있지만, CustomZone 타입은 찾지 못함

**해결**:
- CustomLayoutSnapping.swift 파일 삭제
- SnappingManager.swift 파일 끝에 직접 메서드 추가
- `customLayoutZoneContainingCursor()` 메서드 추가
- `snapToCustomZone()` 메서드 추가
- `applyGapsToRect()` helper 메서드 추가

### 2. 앱 이름 변경: Rectangle → ZoneSnap

**변경 파일: Info.plist**

```xml
<!-- URL Scheme -->
<string>rectangle</string> → <string>zonesnap</string>

<!-- Copyright -->
<string>Copyright © 2019-2025 Ryan Hanson. All rights reserved.</string>
→ <string>Based on Rectangle by Ryan Hanson. Enhanced with Custom Layouts. MIT License.</string>

<!-- Update URL -->
<string>https://rectangleapp.com/downloads/updates.xml</string>
→ <string>https://zonesnap.app/downloads/updates.xml</string>

<!-- Update Check Interval -->
<integer>172800</integer> (2일)
→ <integer>604800</integer> (7일)
```

### 3. 새로운 파일 추가

#### /Rectangle/CustomLayout/
- ✅ CustomLayoutModel.swift - 데이터 모델
- ✅ LayoutEditorView.swift - Canvas 에디터 UI
- ✅ LayoutEditorViewModel.swift - 에디터 로직
- ✅ LayoutManagerView.swift - 레이아웃 관리 UI
- ✅ CustomLayoutDefaults.swift - UserDefaults 설정
- ✅ README.md - 상세 가이드
- ✅ FIXES.md - 이 문서
- ❌ CustomLayoutSnapping.swift - 삭제됨 (SnappingManager.swift로 통합)

#### 루트 디렉토리
- ✅ ZONESNAP.md - 앱 소개 및 사용 가이드

## Xcode에서 해야 할 작업

### 1. 새 파일을 프로젝트에 추가

1. Xcode에서 Rectangle.xcodeproj 열기
2. File → Add Files to "Rectangle"...
3. 다음 파일들 선택:
   - CustomLayout/CustomLayoutModel.swift
   - CustomLayout/LayoutEditorView.swift
   - CustomLayout/LayoutEditorViewModel.swift
   - CustomLayout/LayoutManagerView.swift
   - CustomLayout/CustomLayoutDefaults.swift
4. "Copy items if needed" 체크 해제
5. "Add to targets: Rectangle" 체크
6. Add 클릭

### 2. SwiftUI 프레임워크 추가

1. 프로젝트 네비게이터에서 Rectangle 프로젝트 선택
2. TARGETS → Rectangle 선택
3. General 탭 → Frameworks, Libraries, and Embedded Content
4. `+` 버튼 클릭
5. "SwiftUI.framework" 검색 후 추가

### 3. 빌드 설정 확인

**Minimum Deployment Target:**
- macOS 12.0 이상 (SwiftUI Picker 등 사용)

**Swift Language Version:**
- Swift 5.x

### 4. 컴파일 및 테스트

```bash
# Xcode에서
⌘B (Build)
⌘R (Run)
```

## 예상되는 추가 에러 및 해결

### Error: "Cannot find 'CustomZone' in scope"
**위치**: SnappingManager.swift:41, 206, 288, 306

**해결**: CustomLayoutModel.swift가 프로젝트에 추가되었는지 확인

---

### Error: "Cannot find 'CustomLayoutManager' in scope"
**위치**: SnappingManager.swift:526, 558

**해결**: CustomLayoutModel.swift가 Rectangle 타겟에 포함되었는지 확인

---

### Error: "Value of type 'NSScreen' has no member 'adjustedVisibleFrame'"
**위치**: CustomLayoutModel.swift:36, SnappingManager.swift:555

**해결**:
Rectangle의 기존 extension을 사용합니다. 이미 구현되어 있어야 합니다.
없다면 다음 추가:

```swift
extension NSScreen {
    func adjustedVisibleFrame(_ ignoreTodo: Bool = false) -> CGRect {
        // Rectangle의 기존 구현 사용
        return visibleFrame
    }
}
```

---

### Error: "Cannot find 'RectangleAction' in scope"
**위치**: SnappingManager.swift:567

**해결**:
Rectangle의 기존 타입입니다. WindowHistory.swift에 정의되어 있어야 합니다.

---

### Error: SwiftUI Preview 관련
**위치**: LayoutEditorView.swift:최하단, LayoutManagerView.swift:최하단

**해결**:
Preview는 개발 편의용이므로 무시해도 됩니다.
또는 `#if DEBUG` 블록으로 감싸기:

```swift
#if DEBUG
struct LayoutEditorView_Previews: PreviewProvider {
    // ...
}
#endif
```

## 빌드 성공 후 확인 사항

### 1. 앱 실행
- ✅ 메뉴바에 아이콘 표시
- ✅ 기존 Rectangle 기능 동작
- ✅ 환경설정 열림

### 2. Custom Layouts 기능 테스트
- ✅ Preferences → "Custom Layouts" 탭 확인
- ✅ "Create New Layout" 버튼 클릭
- ✅ 에디터 창 열림
- ✅ Zone 추가/드래그/리사이즈
- ✅ 저장 후 목록에 표시

### 3. Shift 드래그 테스트
- ✅ 레이아웃 활성화
- ✅ 윈도우 드래그 + Shift 키
- ✅ Zone 하이라이트 표시
- ✅ Zone에 스냅됨

## 라이선스 준수 확인

### MIT License 요구사항 충족

1. ✅ **저작권 표시**
   - Info.plist에 "Based on Rectangle by Ryan Hanson" 명시
   - ZONESNAP.md에 크레딧 섹션 추가

2. ✅ **라이선스 포함**
   - 원본 Rectangle LICENSE 파일 유지
   - ZONESNAP.md에 MIT 라이선스 전문 포함

3. ✅ **면책 조항**
   - MIT 라이선스 텍스트에 포함됨

### 판매 가능 여부: ✅ YES

MIT 라이선스이므로:
- 상업적 판매 가능
- 가격 책정 자유
- 소스코드 비공개 가능
- 단, Rectangle 크레딧 표시 필수

## 다음 단계

### 개발
1. Xcode에서 빌드 테스트
2. 기능 테스트 (체크리스트는 README.md 참조)
3. 버그 수정

### 배포 준비
1. 앱 아이콘 제작
2. Sparkle 업데이트 서버 설정
3. 공증(Notarization) 설정
4. DMG 패키징

### 마케팅
1. GitHub 저장소 생성
2. 웹사이트 제작 (zonesnap.app)
3. 스크린샷/비디오 제작
4. App Store 등록 (선택)

## 참고 자료

- Rectangle 원본: https://github.com/rxhanson/Rectangle
- SwiftUI 문서: https://developer.apple.com/documentation/swiftui
- macOS App Distribution: https://developer.apple.com/distribution/

---

**작성일**: 2026-01-02
**버전**: 1.0.0
