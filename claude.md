# Rectangle - macOS 윈도우 관리 앱

## 프로젝트 개요

**Rectangle**은 Spectacle 기반으로 작성된 macOS용 오픈소스 윈도우 관리 애플리케이션입니다. Swift로 작성되었으며, 키보드 단축키와 드래그 앤 드롭을 통해 윈도우를 빠르게 배치하고 리사이징할 수 있습니다.

- **언어**: Swift 5.x+
- **플랫폼**: macOS 10.15 이상
- **라이선스**: MIT
- **번들 ID**: com.knollsoft.Rectangle
- **주요 프레임워크**: AppKit (Cocoa), Accessibility API, Sparkle, MASShortcut

## 핵심 기능

### 1. 키보드 단축키 기반 윈도우 관리
- 100개 이상의 윈도우 액션 지원 (좌/우 반, 상/하 반, 1/3, 1/4, 1/6, 1/8, 1/9 분할 등)
- 커스터마이징 가능한 단축키 (Spectacle 스타일 또는 대체 기본값)
- 멀티 모니터 지원 (다음/이전 디스플레이로 윈도우 이동)
- 윈도우 크기 조절 (크게/작게, 너비/높이 개별 조절)
- 윈도우 이동 (상하좌우, 중앙 정렬)

### 2. 드래그 앤 스냅 (Drag to Snap)
- Windows 11 Snap Layouts 스타일의 화면 가장자리 드래그 스냅
- 실시간 미리보기 (FootprintWindow)
- 모서리, 상단, 하단, 좌우 가장자리 감지
- 화면 방향(가로/세로) 인식 및 자동 조정
- Compound Snap Areas (2분할, 3분할, 4분할, 6분할 등)
- 햅틱 피드백 지원 (옵션)

### 3. Todo Mode
- 특정 앱을 Todo 앱으로 지정
- 윈도우를 자동으로 사이드바 영역에 배치 (좌/우 선택 가능)
- 단축키로 Todo 모드 토글 및 Reflow 가능
- 작업 중인 윈도우와 Todo 윈도우를 분리하여 생산성 향상

### 4. 멀티 윈도우 관리
- **Tile All**: 모든 윈도우를 그리드 형태로 타일링
- **Tile Active App**: 활성 앱의 윈도우만 타일링
- **Cascade All**: 모든 윈도우를 계단식 배치
- **Cascade Active App**: 활성 앱의 윈도우만 계단식 배치
- **Reverse All**: 모든 윈도우의 위치를 반전

### 5. 추가 기능
- 앱별 무시 (Ignore App): 특정 앱에서 Rectangle 단축키 비활성화
- Unsnap Restore: Rectangle로 배치한 윈도우를 드래그하면 원래 크기로 복원
- Gap 설정: 윈도우 간 간격 조절 (픽셀 단위)
- 설정 Import/Export (JSON)
- URL Scheme 지원 (`rectangle://execute-action?name=left-half`)
- Launch on Login (macOS 13+ ServiceManagement 사용)
- Sparkle 자동 업데이트

## 프로젝트 구조

```
Rectangle/
├── Rectangle/              # 메인 앱
│   ├── AppDelegate.swift                  # 앱 진입점, 메뉴 관리, Todo 모드
│   ├── WindowAction.swift                 # 100+ 윈도우 액션 정의
│   ├── ShortcutManager.swift              # 단축키 등록/관리
│   ├── AccessibilityElement.swift         # AXUIElement 래퍼
│   ├── Defaults.swift                     # UserDefaults 래퍼
│   │
│   ├── WindowCalculation/                 # 각 액션별 좌표 계산 로직
│   │   ├── WindowCalculationFactory.swift # 액션 → Calculation 매핑
│   │   ├── LeftHalfCalculation.swift
│   │   ├── MaximizeCalculation.swift
│   │   ├── ... (60+ 파일)
│   │
│   ├── Snapping/                          # 드래그 앤 스냅
│   │   ├── SnappingManager.swift          # 마우스 이벤트 감지, 스냅 영역 판별
│   │   ├── FootprintWindow.swift          # 반투명 미리보기 윈도우
│   │   ├── SnapAreaModel.swift            # 스냅 영역 설정
│   │   └── CompoundSnapArea/              # 복합 스냅 영역 (Halves, Thirds, Fourths, Sixths)
│   │
│   ├── PrefsWindow/                       # 환경설정 UI
│   │   ├── PrefsViewController.swift
│   │   ├── SettingsViewController.swift
│   │   └── SnapAreaViewController.swift
│   │
│   ├── TodoMode/                          # Todo 모드
│   │   └── TodoManager.swift
│   │
│   ├── MultiWindow/                       # 멀티 윈도우 관리
│   │   ├── MultiWindowManager.swift
│   │   └── ReverseAllManager.swift
│   │
│   ├── Utilities/                         # 유틸리티
│   │   ├── WindowUtil.swift
│   │   ├── AlertUtil.swift
│   │   ├── EventMonitor.swift
│   │   └── ... (10+ 파일)
│   │
│   ├── AccessibilityAuthorization/        # 접근성 권한 관리
│   └── WelcomeWindow/                     # 최초 실행 시 웰컴 화면
│
├── RectangleLauncher/      # Launch on Login 헬퍼 (macOS 12 이하)
├── RectangleTests/         # 테스트
└── Rectangle.xcodeproj     # Xcode 프로젝트
```

**총 Swift 파일**: 129개
**총 코드 라인**: ~11,542줄

## 핵심 아키텍처

### 1. Accessibility API 활용
- `AXUIElement`를 통해 타 앱 윈도우의 위치/크기 읽기 및 변경
- `AccessibilityElement` 클래스가 AX API를 래핑하여 간편한 인터페이스 제공
- 최초 실행 시 접근성 권한 요청 (`AccessibilityAuthorization`)

### 2. 이벤트 기반 아키텍처
- `NotificationCenter`를 통한 느슨한 결합
- 각 `WindowAction`은 고유한 Notification Name을 가짐
- `ShortcutManager`가 단축키 입력 시 해당 액션의 Notification 전송
- `WindowManager`가 Notification을 수신하여 `WindowCalculation` 실행

### 3. 계산 팩토리 패턴
- `WindowCalculationFactory`가 액션별 계산 로직을 관리
- 각 액션은 독립적인 `WindowCalculation` 프로토콜 구현체를 가짐
- 정규화된 좌표 (0.0 ~ 1.0) 사용으로 해상도 독립성 확보

### 4. 드래그 앤 스냅 이벤트 루프
- `EventMonitor` (Passive/Active)를 통한 글로벌 마우스 이벤트 감지
- `SnappingManager.handle(event:)` 메서드에서 leftMouseDown/Dragged/Up 처리
- 커서 위치에 따라 `Directional` (tl, t, tr, l, r, bl, b, br) 판별
- `SnapArea` 구조체로 스크린, 방향, 액션을 묶어 관리
- `FootprintWindow` (NSWindow 서브클래스)로 미리보기 표시

### 5. 설정 관리
- `Defaults` 클래스가 UserDefaults를 타입 세이프하게 래핑
- plist 저장 위치: `~/Library/Preferences/com.knollsoft.Rectangle.plist`
- JSON Import/Export 지원 (`~/Library/Application Support/Rectangle/RectangleConfig.json`)

## 주요 클래스 및 파일

### AppDelegate.swift (606줄)
- `@NSApplicationMain` 진입점
- 메뉴 관리 (`NSMenuDelegate`)
- Accessibility 권한 체크 및 환경설정 초기화
- Todo Mode 메뉴 아이템 관리 (`addTodoModeMenuItems`, `updateTodoModeMenuItems`)
- URL Scheme 핸들링 (`application(_:open:)`)
- Launch on Login 체크 (`checkLaunchOnLogin`)

### WindowAction.swift (822줄)
- 102개의 윈도우 액션 enum 정의
- 각 액션별 속성 제공:
  - `name`, `displayName`, `notificationName`
  - `spectacleDefault`, `alternateDefault` (기본 단축키)
  - `image` (메뉴 아이콘)
  - `gapSharedEdge`, `gapsApplicable` (Gap 계산용)
  - `isDragSnappable` (드래그 스냅 가능 여부)
  - `category`, `classification` (메뉴 서브메뉴 분류)
- `post()`, `postMenu()`, `postSnap()`, `postUrl()` 메서드로 액션 실행

### SnappingManager.swift (471줄)
- 드래그 앤 스냅의 핵심 로직
- `EventMonitor`를 통한 마우스 이벤트 감지 (`handle(event:)`)
- 커서 위치 → `Directional` 변환 (`directionalLocationOfCursor`)
- `Directional` + 화면 방향 → `WindowAction` 결정 (`snapAreaContainingCursor`)
- `FootprintWindow` 미리보기 표시 (`getBoxRect`, `getFootprintAnimationOrigin`)
- Unsnap Restore 처리 (`unsnapRestore`)
- Stage Manager, Mission Control 드래그 대응

### FootprintWindow.swift (95줄)
- 반투명 미리보기 윈도우 (NSWindow 서브클래스)
- `NSBox`를 contentView로 사용 (테두리 + 배경색)
- Fade In/Out 애니메이션 지원
- macOS 26.0+ 16pt 코너 반경, 11.0+ 10pt, 이하 5pt

### TodoManager.swift
- Todo 모드 상태 관리
- Todo 앱 및 Todo 윈도우 추적
- Reflow 로직 (Todo 윈도우 재배치)
- 단축키 등록 (`registerUnregisterToggleShortcut`, `registerUnregisterReflowShortcut`)

### MultiWindowManager.swift
- Tile All / Tile Active App 로직
- 윈도우 그리드 계산 (행/열 자동 조정)
- Cascade All / Cascade Active App 로직

## 기술 스택

### 의존성 (Swift Package Manager)
- **Sparkle** (자동 업데이트)
- **MASShortcut** (키보드 단축키 레코딩, https://github.com/rxhanson/MASShortcut fork 사용)

### macOS 프레임워크
- **AppKit (Cocoa)**: NSApplication, NSWindow, NSMenu, NSStatusItem
- **Accessibility API**: AXUIElement, AXObserver
- **ServiceManagement**: SMLoginItemSetEnabled (Launch on Login, macOS 12 이하)
- **os.log**: 로깅

### 빌드 요구사항
- Xcode
- macOS 26 미만 버전에서 빌드 시 "Asset Catalog Other Flags" 삭제 필요 (Liquid Glass 아이콘 때문)

## PRD와의 비교 (기존 Rectangle vs. PRD 목표)

Rectangle은 이미 PRD에서 요구하는 많은 기능을 구현하고 있습니다:

| PRD 요구사항 | Rectangle 현황 | 비고 |
|-------------|--------------|------|
| **Visual Snapping (드래그 UI)** | ✅ 완전 구현 | SnappingManager + FootprintWindow |
| **Custom Layouts (레이아웃 에디터)** | ⚠️ 부분 구현 | SnapAreaModel로 프리셋 변경 가능하지만, GUI 에디터는 없음 |
| **Edge Snap** | ✅ 완전 구현 | 상하좌우 + 모서리 + 하단 1/3 지점 |
| **멀티 모니터 개별 설정** | ❌ 미구현 | 모든 모니터에 동일한 스냅 설정 적용 |
| **FancyZones 스타일 트리거 (Shift+드래그)** | ⚠️ 부분 구현 | `snapModifiers` 설정으로 모디파이어 키 요구 가능 |
| **정규화된 좌표 (0.0~1.0)** | ✅ 사용 중 | WindowCalculation에서 사용 |
| **JSON 저장** | ✅ 구현 | Import/Export 지원 |

### PRD 목표를 위한 추가 작업이 필요한 영역
1. **GUI 레이아웃 에디터**: 현재는 코드 레벨에서만 스냅 영역 변경 가능
2. **모니터별 개별 레이아웃**: SnapAreaModel을 확장하여 모니터 ID별 설정 필요
3. **상단 드래그 시 프리셋 메뉴**: 현재는 화면 가장자리만 감지, 상단 중앙 드래그 시 오버레이 메뉴 미지원

## 개발 가이드

### 빌드 및 실행
```bash
# 저장소 클론
git clone https://github.com/rxhanson/Rectangle.git
cd Rectangle

# Xcode에서 열기
open Rectangle.xcodeproj

# 또는 brew로 설치
brew install --cask rectangle
```

### 새로운 WindowAction 추가 방법
1. `WindowAction.swift`에 새 enum case 추가
2. `name`, `displayName`, `image` 등 속성 구현
3. `WindowCalculation/` 디렉토리에 새 Calculation 클래스 생성
4. `WindowCalculationFactory.swift`에 액션 → Calculation 매핑 추가
5. 필요 시 `Main.strings` (다국어 지원)에 번역 추가

### 로그 보기
1. Rectangle 메뉴 열기
2. Option 키 누른 채로 "View Logging..." 선택
3. 실시간 로그 확인 가능

### 디버깅 팁
- `Defaults.loggingEnabled`를 true로 설정하면 상세 로그 출력
- Accessibility 권한 리셋: `tccutil reset All com.knollsoft.Rectangle`
- 설정 파일 위치: `~/Library/Preferences/com.knollsoft.Rectangle.plist`

## 참고 문서
- [README.md](README.md): 사용법, 설치, 문제 해결
- [TerminalCommands.md](TerminalCommands.md): 숨겨진 설정 (터미널 명령어)
- [CONTRIBUTING.md](CONTRIBUTING.md): 기여 가이드
- [PRD.md](PRD.md): macOS Custom Window Manager 기획서

## 라이선스
MIT License - Ryan Hanson (2019-2025)

---

**최종 업데이트**: 2026-01-02
**분석 기준 버전**: Rectangle (main 브랜치, commit 3f261d3)
