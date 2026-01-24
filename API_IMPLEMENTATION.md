# API Implementation Summary - Bukadita Mobile

## ✅ Implemented Services

### 1. **quiz_service.dart** (NEW)

Service untuk mengelola kuis dengan API endpoints:

- `getMaterialQuizzes(materialId)` - Get quizzes by material ID
- `getQuizDetail(quizId)` - Get quiz detail dengan questions
- `startQuizAttempt(quizId)` - Start quiz attempt
- `submitQuiz(quizId, answers)` - Submit quiz answers dan dapatkan score
- `getQuizResults(quizId)` - Get quiz history/results
- `getMyQuizAttempts()` - Get all quiz attempts user

### 2. **progress_service.dart** (UPDATED)

Added new methods:

- `getModulesProgress()` - Get progress semua modul user
- `getModuleProgress(moduleId)` - Get progress detail modul
- `markMaterialCompleted(materialId)` - Mark material as completed
- Existing: `getMaterialProgress()`, `markPoinCompleted()`, `getLastAccessedPoin()`

### 3. **module_service.dart** (EXISTING - No Changes)

Sudah lengkap dengan:

- `getAllModules()` - Get all published modules
- `getModuleDetail(moduleId)` - Get module detail with subMateris
- `getMaterialsByModule(moduleId)` - Get materials by module
- `getMaterialDetail(materialId)` - Get material with poin_details
- `getMaterialPoints(materialId)` - Get points from material

---

## 📱 Updated Screens

### 1. **module_screen.dart**

**Changes:**

- Import `ProgressService`
- Load progress from API: `getModulesProgress()`
- Map progress percentage ke setiap modul
- Calculate status berdasarkan progress (not-started, in-progress, completed)
- Stats (completedCount, inProgressCount, notStartedCount) dari data real

**Data Flow:**

```
getAllModules() + getModulesProgress()
  ↓
Map progress by module_id
  ↓
Display dengan status & percentage real
```

### 2. **module_materials_list_screen.dart**

**Status:** Already using real API ✅

- `getMaterialsByModule()` untuk list materials
- `getMaterialDetail()` untuk poin count
- Display poin_details.length dari database

### 3. **material_poin_detail_screen.dart**

**Changes:**

- Import `QuizService`
- Add `_moduleId` variable
- Update `_showQuiz()` method:
  - Call `getMaterialQuizzes()` untuk load quiz
  - Navigate dengan `quizId` (bukan hardcoded questions)
  - Handle no quiz case dengan skip ke next poin
- Remove dummy quiz questions data

**Data Flow:**

```
getMaterialDetail()
  ↓
Display poin_details from DB
  ↓
User scroll & click "Mulai Kuis"
  ↓
getMaterialQuizzes()
  ↓
Navigate to quiz_screen dengan quizId
```

### 4. **quiz_screen.dart**

**Changes:**

- Import `QuizService`
- Add `_isLoading` and `_quizId` states
- Load quiz from API in `_loadQuizData()`:
  - `getQuizDetail()` untuk quiz + questions
  - `getQuizResults()` untuk history
- Format dates dan time dari ISO string
- Real quiz history dengan pass/fail status
- Navigate dengan quizId + questions

**Data Flow:**

```
Receive quizId from material_poin_detail
  ↓
getQuizDetail(quizId)
  ↓
Display quiz info + questions count + time limit
  ↓
getQuizResults(quizId)
  ↓
Display quiz history (attempts, scores, status)
  ↓
"Mulai Kuis" → quiz_question_screen
```

### 5. **quiz_question_screen.dart**

**Changes:**

- Import `QuizService`
- Add `_quizId` variable
- Update `_finishQuiz()` method:
  - Prepare answers: `{question_id, selected_answer}`
  - Call `submitQuiz(quizId, answers)`
  - Get score & correctCount from API response
  - Navigate to result screen dengan data dari API

**Data Flow:**

```
Receive quizId + questions
  ↓
User answer questions
  ↓
submitQuiz(quizId, answers)
  ↓
API returns score, correct_count, passed
  ↓
Navigate to quiz_result_screen
```

### 6. **quiz_result_screen.dart**

**Status:** No changes needed ✅

- Already displays score, correct count, review
- Receives data from quiz_question_screen

---

## 🔄 Complete Flow

### Module to Quiz Flow:

```
1. ModulScreen
   └─ Load: getAllModules() + getModulesProgress()
   └─ Display: Real progress per module

2. User tap module card
   └─ getModuleDetail(moduleId)
   └─ Navigate to first material

3. MaterialPoinDetailScreen
   └─ Load: getMaterialDetail(materialId)
   └─ Display: poin_details from DB
   └─ User scroll & click "Mulai Kuis"

4. Load Quiz
   └─ getMaterialQuizzes(materialId)
   └─ Navigate to quiz_screen dengan quizId

5. QuizScreen (Overview)
   └─ Load: getQuizDetail(quizId)
   └─ Load: getQuizResults(quizId) - history
   └─ Display: quiz info + history
   └─ "Mulai Kuis" button

6. QuizQuestionScreen
   └─ User answer questions
   └─ Submit: submitQuiz(quizId, answers)
   └─ Receive: score, correct_count

7. QuizResultScreen
   └─ Display: score, pass/fail, review
   └─ "Lanjutkan" or "Ulangi"
```

---

## 📊 API Endpoints Used

### Modules & Materials:

- `GET /modules?limit=100` - All modules
- `GET /modules/:moduleId` - Module detail
- `GET /materials/public?module_id=X` - Materials by module
- `GET /materials/:materialId/public` - Material detail with poin_details
- `GET /materials/:materialId/quizzes` - Quizzes for material

### Progress:

- `GET /progress/modules` - All modules progress
- `GET /progress/modules/:moduleId` - Module progress detail
- `GET /progress/materials/:materialId` - Material progress
- `POST /progress/poins/:poinId/complete` - Mark poin completed
- `POST /progress/materials/:materialId/complete` - Mark material completed

### Quiz:

- `GET /quizzes/:quizId` - Quiz detail dengan questions
- `POST /quizzes/start` - Start quiz attempt
- `POST /quizzes/submit` - Submit quiz answers (returns score)
- `GET /quizzes/:quizId/results` - Quiz history/results
- `GET /quizzes/attempts/my` - User's all quiz attempts

---

## 🎯 What's Real Now:

✅ **Module progress** - dari database user
✅ **Poin/materi list** - dari database modul
✅ **Quiz questions** - dari database quiz
✅ **Quiz submission** - submit ke API, score dihitung server
✅ **Quiz history** - riwayat attempts dari database
✅ **Material progress** - tracking last accessed poin

---

## 📝 Notes:

1. **Authentication**: Semua API endpoints yang butuh auth sudah include Bearer token dari StorageService
2. **Error Handling**: Semua service calls wrapped dalam try-catch dengan user-friendly messages
3. **Loading States**: Added loading indicators di quiz_screen saat fetch data
4. **No More Dummy Data**: Semua hardcoded questions/progress telah dihapus
5. **API Response Format**: Mengikuti format envelope API: `{error, code, message, data}`

---

**Last Updated**: January 21, 2026
**Status**: ✅ All API Implementation Complete
