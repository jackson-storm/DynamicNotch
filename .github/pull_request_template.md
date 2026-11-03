### 📝 Description / Описание изменений
<!-- 
EN: Briefly describe what changes were made, why, and link relevant issues (e.g. Closes #123).
RU: Кратко опишите, что было сделано, зачем, и прикрепите связанные задачи (например, Closes #123).
-->

---

### 📌 Type of Change / Тип изменений
- [ ] 🚀 New feature / Новая фича
- [ ] 🐛 Bug fix / Исправление ошибки
- [ ] 🎨 Refactoring & Optimization / Рефакторинг и оптимизация
- [ ] 📖 Documentation & Localizations / Документация и переводы

---

### ✅ Pull Request Checklist & Requirements

#### 1. Features & UI (Новые фичи и интерфейс)
- [ ] **Dynamic Island First:** New features and UI strictly match or closely follow native Apple iOS Dynamic Island behaviors, layouts, and physics-based spring animations.
- [ ] **No alien UI:** Design aligns with macOS and Dynamic Island design guidelines (proper corner radii, padding, San Francisco typography, dark aesthetic).

#### 2. Bug Fixes (Исправление ошибок)
- [ ] **Targeted fix:** The bug is fixed without altering unrelated business logic, existing interfaces, or user expectations.
- [ ] **No regressions:** Neighboring features and existing flows continue to work properly.

#### 3. Code Integrity & Performance (Целостность кода и производительность)
- [ ] **Battery & CPU conscious:** DynamicNotch is a background menu/notch app. Changes introduce NO tight loops, busy-waiting, redundant timers, or excessive background polling.
- [ ] **Memory & Concurrency:** No retain cycles or memory leaks (proper `[weak self]` in closures and Combine/Notification pipelines). UI updates are guaranteed on `@MainActor`.
- [ ] **Zero unnecessary dependencies:** New external packages/frameworks are avoided unless strictly justified and discussed beforehand.

#### 4. Code Quality & Standards (Стиль кода и стандарты)
- [ ] Follows project architecture (`DynamicNotch/Features/...` and MVVM).
- [ ] Follows Swift API Design Guidelines (no force unwraps `!`, clean naming, 4 spaces indent).
- [ ] Cleaned up all debug `print()` statements, test flags, and commented-out code.

#### 5. Verification & Testing (Проверка и тестирование)
- [ ] Project builds cleanly without new warnings or errors.
- [ ] Existing and new unit tests pass (`Cmd + U`).
- [ ] Tested on a physical Mac (Tested macOS version: `macOS ________`).
- [ ] Screenshots or screen recordings attached below (especially for UI/animation changes).

---

### 📸 Media / Screenshots & Recordings
<!-- Attach screenshots, GIFs, or videos showing the changes in action -->
