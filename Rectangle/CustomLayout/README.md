# Custom Layout Feature - Implementation Guide

## 개요

Rectangle에 **FancyZones 스타일의 커스텀 레이아웃 에디터**와 **모니터별 개별 설정** 기능을 구현했습니다.

PRD 요구사항:
- ✅ GUI 레이아웃 에디터 (Canvas 기반)
- ✅ 모니터별 개별 레이아웃 저장
- ✅ 정규화된 좌표 (0.0 ~ 1.0) 사용
- ✅ JSON 기반 영속화
- ✅ Shift 키로 커스텀 존 트리거
- ✅ 드래그/리사이즈/병합 기능

---

## 파일 구조

```
Rectangle/CustomLayout/
├── CustomLayoutModel.swift          # 데이터 모델 (Zone, Layout, Manager)
├── LayoutEditorView.swift           # SwiftUI 레이아웃 에디터 UI
├── LayoutEditorViewModel.swift      # 에디터 뷰모델
├── LayoutManagerView.swift          # 레이아웃 목록 관리 UI
├── CustomLayoutSnapping.swift       # SnappingManager 확장
├── CustomLayoutDefaults.swift       # UserDefaults 설정
└── README.md                        # 이 문서
```

---

## 핵심 컴포넌트

### 1. CustomLayoutModel.swift

#### CustomZone
```swift
struct CustomZone {
    let id: UUID
    var rect: NormalizedRect  // 0.0 ~ 1.0
    var name: String?
}
```

**기능:**
- 정규화된 좌표로 화면 독립성 보장
- `absoluteRect(for:)` - 실제 화면 좌표로 변환
- `contains(normalizedPoint:)` - 커서 감지

#### CustomLayout
```swift
struct CustomLayout {
    let id: UUID
    var name: String
    var zones: [CustomZone]
    var screenIdentifier: String  // 모니터 고유 ID
    var gapSize: Int
}
```

**기능:**
- 모니터별 레이아웃 저장
- Zone CRUD 메서드
- `zone(at:)` - 커서 위치의 존 찾기

#### CustomLayoutManager (싱글톤)
```swift
class CustomLayoutManager: ObservableObject {
    @Published var layouts: [CustomLayout]
    @Published var activeLayoutPerScreen: [String: UUID]
}
```

**기능:**
- 모든 레이아웃 관리
- 모니터별 활성 레이아웃 추적
- UserDefaults 영속화
- 프리셋 레이아웃 제공

---

### 2. LayoutEditorView.swift

**SwiftUI 기반 Canvas 에디터**

주요 섹션:
- **Toolbar**: 이름, Add Zone, Grid Template 버튼
- **Canvas**: 드래그 가능한 Zone 시각화
- **Sidebar**: Zone 목록 및 속성 편집기
- **Bottom Bar**: Grid 표시 토글, 행/열 조절

**ZoneView 컴포넌트:**
- 드래그로 이동
- 8개 핸들(모서리 + 변)로 리사이즈
- 선택 시 파란 테두리 표시

**기능:**
- Real-time 미리보기
- Grid 스냅 (2~12 행/열)
- Grid Template 자동 생성 (NxM)
- Zone 속성 직접 입력 (%, 정규화)

---

### 3. LayoutEditorViewModel.swift

**에디터 로직 구현**

주요 메서드:
- `addDefaultZone()` - 새 Zone 추가
- `moveZone(id:by:canvasSize:)` - Zone 드래그
- `resizeZone(id:edge:by:canvasSize:)` - Zone 리사이즈 (8방향)
- `createGridTemplate()` - NxM Grid 자동 생성
- `mergeZones([UUID])` - 여러 Zone을 하나로 병합
- `duplicateZone(id:)` - Zone 복제

**경계 검증:**
- Zone이 화면(0.0~1.0) 밖으로 나가지 않도록 제한
- 최소 크기 5% 보장

---

### 4. LayoutManagerView.swift

**레이아웃 목록 및 관리 UI**

기능:
- **Screen Selector**: 모니터별 필터링
- **Layout Cards**: 각 레이아웃 카드에 미리보기, Active 상태, 편집/활성화/복제/삭제 버튼
- **Preset Templates**: 2분할, 3분할, 2x2 Grid, Coding Setup 등 즉시 생성

**LayoutCard:**
- 80x60 미리보기 (최대 4개 Zone 표시)
- Active 뱃지
- 수정 시간 표시
- 컨텍스트 메뉴 (Duplicate, Delete)

---

### 5. CustomLayoutSnapping.swift

**SnappingManager 확장**

추가 메서드:
- `customLayoutZoneContainingCursor()` - 커서 위치의 커스텀 존 감지
- `snapToCustomZone(zone:screen:windowElement:windowId:)` - 커스텀 존에 윈도우 스냅
- `showCustomLayoutOverlay(for:)` - 모든 존 오버레이 표시 (Shift 키 누를 때)
- `hideCustomLayoutOverlays()` - 오버레이 숨기기

**SnappingManager.swift 수정 사항:**
- `currentCustomZone`, `currentCustomScreen` 프로퍼티 추가
- `handle(event:)` 메서드에 Shift 키 감지 로직 추가
  - Shift 누름 → 커스텀 존 감지
  - Shift 놓음 → 기본 스냅 영역 감지
- `leftMouseUp` 시 커스텀 존 우선 처리

---

### 6. CustomLayoutDefaults.swift

**설정 항목:**
- `customLayoutsEnabled` - 커스텀 레이아웃 기능 활성화 (기본: false)
- `customLayoutModifier` - 트리거 모디파이어 키 (기본: Shift = 1)
- `showCustomLayoutOverlay` - 오버레이 표시 여부 (기본: true)
- `customZonePreviewColor` - 미리보기 색상

**Notification:**
- `customLayoutsToggled` - 기능 토글 시
- `customLayoutModifierChanged` - 모디파이어 변경 시

---

## 사용 방법

### 1. 레이아웃 생성

1. Rectangle 환경설정 열기
2. "Custom Layouts" 탭 이동
3. "Create New Layout" 버튼 클릭
4. 레이아웃 에디터에서 Zone 추가/편집
   - "Add Zone" 버튼으로 새 Zone 추가
   - 드래그로 위치 이동
   - 모서리/변 핸들로 크기 조절
   - "Grid Template"으로 N x M Grid 자동 생성
5. "Save" 버튼으로 저장

### 2. 레이아웃 활성화

1. LayoutManagerView에서 원하는 레이아웃 선택
2. "Activate" 버튼 클릭
3. 해당 모니터에 레이아웃 적용됨

### 3. 윈도우 스냅

**기본 스냅 (화면 가장자리):**
- 윈도우를 드래그하여 화면 가장자리로 이동
- 기존 Rectangle 동작과 동일

**커스텀 존 스냅 (Shift 키):**
1. 윈도우 드래그 시작
2. **Shift 키 누른 상태 유지**
3. 활성화된 커스텀 레이아웃의 Zone들이 하이라이트됨
4. 원하는 Zone 위에서 마우스 릴리즈
5. 윈도우가 해당 Zone으로 스냅됨

**모디파이어 변경:**
- Defaults에서 `customLayoutModifier` 값 변경
- 0 = 모디파이어 불필요
- 1 = Shift
- 2 = Control
- 4 = Option
- 8 = Command

---

## 데이터 구조

### JSON 저장 형식

**CustomLayout (UserDefaults: "customLayouts"):**
```json
[
  {
    "id": "UUID-STRING",
    "name": "Coding Setup",
    "screenIdentifier": "Screen_12345",
    "gapSize": 8,
    "createdAt": "2026-01-02T10:00:00Z",
    "modifiedAt": "2026-01-02T11:30:00Z",
    "zones": [
      {
        "id": "UUID-STRING",
        "rect": {
          "x": 0.0,
          "y": 0.0,
          "width": 0.6,
          "height": 1.0
        },
        "name": "Editor"
      },
      {
        "id": "UUID-STRING",
        "rect": {
          "x": 0.6,
          "y": 0.0,
          "width": 0.4,
          "height": 0.5
        },
        "name": "Terminal"
      }
    ]
  }
]
```

**activeLayoutPerScreen (UserDefaults: "activeLayoutPerScreen"):**
```json
{
  "Screen_12345": "UUID-OF-ACTIVE-LAYOUT",
  "Screen_67890": "UUID-OF-ANOTHER-LAYOUT"
}
```

---

## 통합 가이드

### AppDelegate에 추가

```swift
// AppDelegate.swift
import SwiftUI

func applicationDidFinishLaunching(_ aNotification: Notification) {
    // ... 기존 코드 ...

    // Custom Layout Manager 초기화
    _ = CustomLayoutManager.shared

    // Notification 리스너
    Notification.Name.customLayoutsToggled.onPost { _ in
        self.snappingManager.reloadFromDefaults()
    }
}

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

### 메뉴 아이템 추가

```swift
// Main.storyboard에 메뉴 아이템 추가
"Custom Layouts..." → openCustomLayouts:
```

---

## 프리셋 레이아웃

### 1. Two Columns
```
┌─────────┬─────────┐
│         │         │
│  Left   │  Right  │
│  50%    │  50%    │
│         │         │
└─────────┴─────────┘
```

### 2. Three Columns
```
┌────┬────┬────┐
│    │    │    │
│ L  │ C  │ R  │
│33% │34% │33% │
│    │    │    │
└────┴────┴────┘
```

### 3. Grid 2x2
```
┌─────┬─────┐
│  1  │  2  │
├─────┼─────┤
│  3  │  4  │
└─────┴─────┘
```

### 4. Coding Setup
```
┌──────────┬────┐
│          │  2 │
│    1     ├────┤
│  Editor  │  3 │
│   60%    │40% │
└──────────┴────┘
```

---

## 성능 최적화

### 1. 정규화된 좌표
- 해상도 독립적 (0.0 ~ 1.0)
- 화면 변경 시 자동 스케일링
- 메모리 효율적 (CGFloat 4개)

### 2. 커서 감지 최적화
- Shift 키 누를 때만 커스텀 존 체크
- Zone 수가 많아도 O(n) 선형 탐색
- 화면별로 분리된 레이아웃 (불필요한 체크 방지)

### 3. UI 렌더링
- SwiftUI의 선언적 UI로 효율적 업데이트
- Zone 미리보기는 최대 4개만 표시
- Canvas에서만 전체 Zone 렌더링

---

## 테스트 시나리오

### 기본 기능 테스트

1. **레이아웃 생성**
   - [ ] "Create New Layout" 버튼 클릭
   - [ ] 에디터 열림 확인
   - [ ] "Add Zone" 버튼으로 Zone 추가
   - [ ] Zone 드래그로 이동
   - [ ] 8개 핸들로 리사이즈
   - [ ] "Save" 버튼으로 저장
   - [ ] 레이아웃 목록에 표시 확인

2. **Grid Template**
   - [ ] "Grid Template" 버튼 클릭
   - [ ] Columns/Rows 설정 (예: 3x2)
   - [ ] "Create" 버튼 클릭
   - [ ] 6개 Zone 자동 생성 확인

3. **모니터별 레이아웃**
   - [ ] 2개 이상 모니터 연결
   - [ ] Screen Selector에서 "Screen 1" 선택
   - [ ] 레이아웃 A 생성 및 활성화
   - [ ] Screen Selector에서 "Screen 2" 선택
   - [ ] 레이아웃 B 생성 및 활성화
   - [ ] 각 모니터에서 다른 레이아웃 적용 확인

4. **Shift 키 스냅**
   - [ ] 레이아웃 활성화
   - [ ] 윈도우 드래그 시작
   - [ ] Shift 키 누름
   - [ ] 커스텀 Zone들이 하이라이트됨
   - [ ] Zone 위에서 마우스 릴리즈
   - [ ] 윈도우가 해당 Zone으로 스냅됨

5. **기존 스냅과의 호환성**
   - [ ] Shift 키 없이 드래그
   - [ ] 화면 가장자리로 이동
   - [ ] 기존 Rectangle 스냅 동작 확인
   - [ ] Shift 키 누른 상태에서는 커스텀 존만 감지

### 엣지 케이스

- [ ] Zone이 0개인 레이아웃 활성화
- [ ] 동일 모니터에 여러 레이아웃 생성
- [ ] 레이아웃 삭제 시 활성 레이아웃도 삭제되는 경우
- [ ] 모니터 연결 해제 후 재연결
- [ ] 해상도 변경
- [ ] Zone 크기 최소값 (5%) 미만으로 리사이즈 시도

---

## 향후 개선 사항

### Phase 3 (추가 기능)
- [ ] Zone 자동 정렬 (좌측 정렬, 균등 분할 등)
- [ ] Zone 색상 커스터마이징
- [ ] 키보드 단축키로 Zone 간 이동
- [ ] Import/Export (JSON 파일)
- [ ] iCloud 동기화
- [ ] 레이아웃 공유 (URL 또는 Code)
- [ ] 애니메이션 효과 개선
- [ ] 멀티 선택 (Cmd+클릭)
- [ ] Undo/Redo

### 성능 개선
- [ ] Zone 감지 QuadTree 최적화
- [ ] Canvas 렌더링 메탈 가속
- [ ] 대용량 레이아웃 (100+ Zones) 지원

---

## 문제 해결

### 커스텀 존이 감지되지 않음
1. Defaults에서 `customLayoutsEnabled` 확인
2. 레이아웃이 활성화되어 있는지 확인
3. Shift 키를 정확히 누르고 있는지 확인
4. 모니터 ID가 올바른지 확인

### FootprintWindow가 표시되지 않음
1. `showCustomLayoutOverlay` 설정 확인
2. Zone rect가 유효한지 확인 (0.0 ~ 1.0 범위)
3. Window Level 충돌 확인

### 레이아웃이 저장되지 않음
1. UserDefaults 권한 확인
2. JSON 인코딩 에러 로그 확인
3. Sandbox 설정 확인

---

## 라이선스

MIT License - Rectangle 프로젝트와 동일

---

**작성일**: 2026-01-02
**작성자**: Claude Code
**버전**: 1.0.0
