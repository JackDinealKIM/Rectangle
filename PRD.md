# Product Requirements Document (PRD): macOS Custom Window Manager
**Project Name:** MacSnap Pro (가칭)
**Version:** 0.1 (Draft)
**Status:** In-Planning
**Platform:** macOS (macOS 12.0 Monterey+)

---

## 1. 개요 (Overview)
### 1.1 배경
Windows 11의 'Snap Layouts'와 PowerToys의 'FancyZones'는 윈도우 관리의 표준을 높였다. macOS 사용자들(특히 윈도우에서 넘어온 사용자나 울트라 와이드 모니터 사용자)은 이와 유사한 **시각적 드래그 앤 드롭** 방식의 창 관리 도구를 원하지만, 기존 앱(Rectangle 등)은 단축키 위주이거나 커스텀 레이아웃 기능이 부족하다.

### 1.2 목표 (Goal)
* **Visual Snapping:** 윈도우 드래그 시 직관적인 오버레이 UI 제공 (Windows Snap Layouts 경험 이식).
* **Custom Layouts:** 사용자가 직접 화면을 분할하고 정의하는 레이아웃 에디터 제공 (FancyZones 경험 이식).
* **Native Performance:** Swift & AppKit 기반의 가볍고 빠른 네이티브 앱 구현.

---

## 2. 타겟 사용자 (Target Audience)
* **프로 개발자:** 여러 터미널과 에디터를 동시에 띄워두는 사용자.
* **울트라 와이드 모니터 사용자:** 광활한 화면을 효율적으로 쪼개 쓰고 싶은 사용자.
* **윈도우 스위처 (Switchers):** 윈도우의 편리한 창 관리 기능을 맥에서도 쓰고 싶은 사용자.

---

## 3. 핵심 기능 (Core Features)

### Phase 1: MVP (Minimum Viable Product)
1.  **스냅 바 (Snap Bar / Top Overlay)**
    * 사용자가 창을 드래그하여 화면 상단 중앙으로 가져가면 오버레이 메뉴가 나타남.
    * 메뉴에는 기본 프리셋(2분할, 3분할, 4분할 등)이 표시됨.
    * 특정 프리셋 영역에 드롭하면 해당 위치로 윈도우 리사이징.
2.  **기본 마그네틱 스냅 (Edge Snap)**
    * 화면 가장자리(좌, 우, 모서리)로 드래그 시 미리보기 표시 및 리사이징.
3.  **권한 관리 가이드**
    * 최초 실행 시 'Accessibility(손쉬운 사용)' 권한 요청 및 안내 UI.

### Phase 2: Pro Features (차별화 & 수익화)
1.  **커스텀 레이아웃 에디터 (Layout Editor)**
    * Canvas UI를 통해 사용자가 직접 Grid를 그리거나 합칠 수 있음.
    * 여백(Gutter) 픽셀 단위 조절.
    * 생성한 레이아웃 저장 및 이름 지정.
2.  **FancyZones 스타일 트리거**
    * Shift 키를 누른 채 드래그하면 사용자가 정의한 커스텀 존(Zone)이 오버레이로 표시됨.
    * 존 위에 드롭 시 즉시 스냅.
3.  **멀티 모니터 개별 설정**
    * 모니터 A와 모니터 B에 서로 다른 레이아웃 프리셋 지정 가능.

---

## 4. 기술 스택 및 아키텍처 (Technical Stack)

### 4.1 개발 환경
* **Language:** Swift 5.x+
* **OS:** macOS Only (Not Catalyst)
* **IDE:** Xcode

### 4.2 핵심 프레임워크
* **AppKit (Cocoa):** 윈도우 제어, 백그라운드 프로세스, 글로벌 이벤트 감지. (필수)
* **SwiftUI:** 설정 창(Preferences), 레이아웃 에디터, 웰컴 스크린 구현.
* **Accessibility API (AXUIElement):** 타 앱 윈도우의 위치/크기 읽기 및 쓰기.

### 4.3 데이터 모델 (Data Structure)
* **좌표계:** 해상도 독립성을 위해 **정규화된 좌표 (0.0 ~ 1.0)** 사용.
    * 예: 화면 왼쪽 절반 = `{x: 0.0, y: 0.0, width: 0.5, height: 1.0}`
* **저장 포맷:** JSON
    ```json
    {
      "layout_name": "Coding Setup",
      "zones": [
        {"id": 1, "rect": [0, 0, 0.5, 1]},
        {"id": 2, "rect": [0.5, 0, 0.5, 0.5]},
        {"id": 3, "rect": [0.5, 0.5, 0.5, 0.5]}
      ],
      "screen_id": "LG_Ultrawide_Serial_123"
    }
    ```

---

## 5. UI/UX 요구사항
1.  **Non-Intrusive:** 오버레이는 사용자가 명확한 의도(드래그)를 보일 때만 나타나야 함.
2.  **Performance:** 드래그 시 오버레이 하이라이트는 60fps를 유지해야 함 (렉 발생 시 사용자 경험 치명적).
3.  **Visual Feedback:**
    * Snap 예정 영역은 반투명 배경색 + 테두리로 미리보기(Preview) 제공.
    * 마우스 릴리즈 시 부드러운 애니메이션으로 윈도우 이동.

---

## 6. 개발 로드맵 (Milestones)

* **Sprint 1 (Core Engine):** AXUIElement 래퍼 구현, 현재 창 정보 가져오기/변경하기 성공.
* **Sprint 2 (Event Loop):** 글로벌 마우스 드래그 감지, 좌표 추적 로직 구현.
* **Sprint 3 (Overlay UI):** 투명 NSPanel 생성 및 마우스 좌표에 따른 히트 테스트(Hit Test) 구현.
* **Sprint 4 (Logic Binding):** 오버레이 영역 감지 시 엔진 트리거 연결 (기능 구현 완료).
* **Sprint 5 (Productizing):** 설정 UI, 권한 안내, 앱 아이콘 및 패키징.