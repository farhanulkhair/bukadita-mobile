# Debug Guide - Riwayat Kuis Kosong

## 🔍 Informasi yang Dibutuhkan

Untuk memperbaiki masalah riwayat kuis yang tidak muncul, saya perlu informasi berikut:

### 1. **API Response Structure**

Bisa jalankan query ini di aplikasi web atau Postman dan kirim hasil responsenya?

```bash
# Endpoint yang digunakan
GET /api/v1/quizzes/attempts/my

# Header
Authorization: Bearer <your_token>
```

**Pertanyaan:**

- Apakah response berupa `{ data: { attempts: [...] } }` atau format lain?
- Apakah ada perbedaan endpoint antara web app dan mobile app?

---

### 2. **Database Schema**

**Tabel quiz attempts** - Apa nama field-field berikut di database?

| Field      | Kemungkinan Nama                               | Tipe Data            |
| ---------- | ---------------------------------------------- | -------------------- |
| Quiz ID    | `quiz_id` / `quizId` / `quiz_uuid`             | INT / VARCHAR / UUID |
| User ID    | `user_id` / `userId`                           | INT / VARCHAR / UUID |
| Score      | `score`                                        | INT / DECIMAL        |
| Status     | `passed` / `is_passed` / `status`              | BOOLEAN / VARCHAR    |
| Created At | `created_at` / `submitted_at` / `completed_at` | TIMESTAMP            |

---

### 3. **Web App Implementation**

**Di aplikasi web, bagaimana menampilkan riwayat kuis?**

Contoh code yang digunakan di web (JavaScript/TypeScript):

```javascript
// Tolong share code snippet yang fetch dan filter quiz attempts
// Misal:
const fetchQuizHistory = async (quizId) => {
  const response = await fetch(`/api/v1/quizzes/attempts/my`);
  const data = await response.json();

  // Bagaimana filtering berdasarkan quizId?
  const filtered = data.attempts.filter(
    (attempt) => attempt.quiz_id === quizId, // Atau quiz_id.toString() ?
  );

  return filtered;
};
```

**Pertanyaan:**

1. Apakah web app filtering by `quiz_id` secara client-side atau server-side?
2. Apakah perlu convert tipe data (string ↔ number)?
3. Field mana yang ditampilkan di UI riwayat?

---

### 4. **Sample Data**

Tolong jalankan di console browser aplikasi web:

```javascript
// Buka halaman quiz yang sudah dikerjakan
// Buka Console (F12)
// Jalankan:
fetch("/api/v1/quizzes/attempts/my", {
  headers: {
    Authorization: "Bearer " + localStorage.getItem("access_token"),
  },
})
  .then((r) => r.json())
  .then((data) => console.log(JSON.stringify(data, null, 2)));
```

Copy paste hasilnya (cukup 1-2 attempts saja, sensor data sensitif jika perlu).

---

### 5. **Expected vs Actual**

**Di mobile app saat ini:**

Console log menunjukkan:

```
📊 [QUIZ_HISTORY] Total attempts: X
📊 [QUIZ_HISTORY] Current quiz ID: Y
📊 [QUIZ_HISTORY] Filtered attempts: 0 ❌
```

**Yang diharapkan:**

```
📊 [QUIZ_HISTORY] Total attempts: 5
📊 [QUIZ_HISTORY] Current quiz ID: abc123
📊 [QUIZ_HISTORY] Comparing: "abc123" == "abc123" = true
📊 [QUIZ_HISTORY] Filtered attempts: 3 ✅
```

**Tolong kirim screenshot atau copy paste dari console log mobile app:**

- Terutama bagian `[QUIZ_HISTORY]`
- Dan juga hasil dari console.log di quiz_screen.dart

---

## 🧪 Testing Steps

Untuk membantu debugging:

1. **Buka quiz yang sudah pernah dikerjakan**
   - Pastikan minimal 1x sudah submit quiz
2. **Check console log**

   ```
   flutter run
   ```

   - Lihat output `[QUIZ_HISTORY]`
   - Kirim screenshot atau copy text

3. **Check di web app**
   - Login dengan user yang sama
   - Buka quiz yang sama
   - Apakah riwayat muncul di web?
   - F12 → Network → Filter XHR → Cari request `attempts`
   - Screenshot response

---

## 📊 Analisis Sementara

Berdasarkan code yang ada, kemungkinan masalah:

### Kemungkinan 1: Quiz ID Mismatch

```dart
// Mobile menggunakan:
final attemptQuizId = r['quiz_id']?.toString() ?? '';
final currentQuizId = _quizId.toString();

// Possible issues:
// - Field name beda: quiz_id vs quizId vs quiz_uuid
// - Tipe data: "123" vs 123
// - Format: UUID vs Integer
```

### Kemungkinan 2: Response Structure Berbeda

```dart
// Code expect salah satu dari:
// A. {data: {attempts: [...]}}
// B. {data: {items: [...]}}
// C. {data: [...]}

// Mungkin actual response berbeda?
```

### Kemungkinan 3: Auth Token

```dart
// Token invalid atau expired?
// User berbeda antara web dan mobile?
```

---

## 🔧 Quick Test

Bisa coba jalankan ini di quiz_screen.dart untuk debugging lebih detail?

Tambahkan di method `_loadQuizData()` setelah get response:

```dart
// Setelah line: final historyResult = await _quizService.getMyQuizAttempts(limit: 100);

// ADD THIS:
debugPrint('🔍 [DEBUG] Raw response: ${historyResult.toString()}');
if (historyResult['success']) {
  debugPrint('🔍 [DEBUG] Response data type: ${historyResult['data'].runtimeType}');
  debugPrint('🔍 [DEBUG] Response data: ${historyResult['data']}');
}
```

Lalu kirim hasil log-nya.

---

## ✅ Action Items

Untuk mempercepat perbaikan, tolong kirim:

- [ ] Sample API response dari `/quizzes/attempts/my`
- [ ] Screenshot console log `[QUIZ_HISTORY]` dari mobile
- [ ] Screenshot riwayat quiz dari web app
- [ ] Nama field di database schema (quiz_id, etc.)
- [ ] Code snippet dari web app yang fetch quiz history

Setelah dapat info ini, saya bisa langsung fix dengan tepat! 🚀
