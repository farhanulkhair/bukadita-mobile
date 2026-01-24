# 📖 Standar Penamaan Project BukaDita Mobile

Dokumentasi ini menjelaskan standar penamaan yang konsisten untuk seluruh project agar mudah di-maintain.

---

## 🗂️ Struktur Folder

```
lib/
├── pages/                    # Semua halaman aplikasi
│   ├── auth/                # Halaman autentikasi
│   │   ├── login_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── home/                # Halaman beranda
│   │   └── home_screen.dart
│   ├── modul/               # Halaman modul
│   │   └── modul_screen.dart
│   └── profile/             # Halaman profil & sub-halaman
│       ├── profile_screen.dart
│       ├── full_data_screen.dart
│       ├── change_password_screen.dart
│       └── settings_screen.dart
├── layouts/                 # Layout wrappers
│   └── app_layout.dart      # Layout untuk halaman utama dengan bottom nav
├── components/              # Komponen reusable
│   └── navigation/
│       └── navigation.dart
├── widgets/                 # Widget custom
├── models/                  # Data models
├── services/                # Services (API, Storage, dll)
├── theme/                   # Theme & styling
└── config/                  # Konfigurasi app
```

---

## 📝 Standar Penamaan File

### 1. **Screen Files**

- Format: `nama_screen.dart` (snake_case dengan suffix `_screen`)
- Contoh:
  - ✅ `login_screen.dart`
  - ✅ `profile_screen.dart`
  - ✅ `change_password_screen.dart`
  - ❌ `login.dart`
  - ❌ `profileScreen.dart`

### 2. **Component Files**

- Format: `nama_component.dart` (snake_case)
- Contoh:
  - ✅ `navigation.dart`
  - ✅ `gradient_button.dart`

### 3. **Model Files**

- Format: `nama_model.dart` (snake_case dengan suffix `_model`)
- Contoh:
  - ✅ `user_model.dart`
  - ✅ `login_request.dart`

### 4. **Service Files**

- Format: `nama_service.dart` (snake_case dengan suffix `_service`)
- Contoh:
  - ✅ `auth_service.dart`
  - ✅ `storage_service.dart`

---

## 🛣️ Standar Routes

### Format Routes

- Halaman utama: `/nama-halaman` (kebab-case)
- Sub-halaman: `/parent/child` (kebab-case)

### Daftar Routes Aktif

```dart
routes: {
  '/': SplashScreen,

  // Auth
  '/login': LoginScreen,
  '/forgot-password': ForgotPasswordScreen,

  // Main Pages
  '/home': HomeScreen,
  '/modul': ModulScreen,
  '/profile': ProfileScreen,

  // Profile Sub-Pages
  '/profile/full-data': FullDataScreen,
  '/profile/change-password': ChangePasswordScreen,
  '/profile/settings': SettingsScreen,
}
```

### ❌ Routes yang Deprecated (Jangan Digunakan)

```dart
'/user/beranda'      -> Gunakan '/home'
'/user/profil'       -> Gunakan '/profile'
'/user/modul'        -> Gunakan '/modul'
'/user/pengaturan'   -> Gunakan '/profile/settings'
'/reset-password'    -> Gunakan '/forgot-password'
```

---

## 🎨 Standar Class Names

### 1. **Screen Classes**

- Format: `NamaScreen` (PascalCase dengan suffix `Screen`)
- Contoh:
  - ✅ `LoginScreen`
  - ✅ `ProfileScreen`
  - ✅ `ChangePasswordScreen`
  - ❌ `Login`
  - ❌ `profile_screen`

### 2. **Widget Classes**

- Format: `NamaWidget` (PascalCase)
- Contoh:
  - ✅ `GradientButton`
  - ✅ `CustomTextField`

### 3. **Model Classes**

- Format: `NamaModel` (PascalCase dengan suffix `Model` jika data model)
- Contoh:
  - ✅ `UserModel`
  - ✅ `LoginRequest`
  - ✅ `LoginResponse`

---

## 🧭 Navigasi Antar Halaman

### Bottom Navigation (3 Tab Utama)

```dart
BottomNavBar(
  currentIndex: 0, // 0=Home, 1=Modul, 2=Profile
  onTap: (index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
    if (index == 1) Navigator.pushReplacementNamed(context, '/modul');
    if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
  },
)
```

### Navigasi ke Sub-Halaman

```dart
// Dari Profile -> Settings
Navigator.pushNamed(context, '/profile/settings');

// Dari Profile -> Change Password
Navigator.pushNamed(context, '/profile/change-password');

// Dari Profile -> Full Data
Navigator.pushNamed(context, '/profile/full-data');
```

### Navigasi dengan Replace (Untuk Main Pages)

```dart
// Gunakan pushReplacementNamed untuk halaman utama
Navigator.pushReplacementNamed(context, '/home');
Navigator.pushReplacementNamed(context, '/profile');
```

### Navigasi Logout

```dart
// Clear semua dan kembali ke login
Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
```

---

## 📦 Import Statements

### Standar Import Order

```dart
// 1. Dart/Flutter packages
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 2. Third-party packages
import 'package:google_fonts/google_fonts.dart';

// 3. Internal - Config
import 'config/api_config.dart';

// 4. Internal - Theme
import 'theme/theme.dart';

// 5. Internal - Pages (alfabetis)
import 'pages/auth/login_screen.dart';
import 'pages/home/home_screen.dart';
import 'pages/profile/profile_screen.dart';

// 6. Internal - Services
import 'services/storage_service.dart';
```

---

## ✅ Checklist Saat Membuat Halaman Baru

### Halaman Utama (dengan Bottom Nav)

1. [ ] Buat file di folder yang sesuai dengan nama `nama_screen.dart`
2. [ ] Class name menggunakan PascalCase dengan suffix `Screen`
3. [ ] Import `AppLayout`: `import '../../layouts/app_layout.dart';`
4. [ ] Wrap dengan `AppLayout(currentIndex: X, child: Scaffold(...))`
5. [ ] Tambahkan route di `main.dart` dengan format `/nama-halaman`
6. [ ] Import di `main.dart` dengan path lengkap

### Halaman Detail/Sub-Halaman (tanpa Bottom Nav)

1. [ ] Buat file di folder parent dengan nama `nama_screen.dart`
2. [ ] Class name menggunakan PascalCase dengan suffix `Screen`
3. [ ] Gunakan `Scaffold` biasa (TIDAK pakai AppLayout)
4. [ ] Tambahkan `AppBar` dengan back button
5. [ ] Tambahkan route di `main.dart` dengan format `/parent/child`
6. [ ] Import di `main.dart` dengan path lengkap

---

## 🔄 Migration dari Route Lama

Jika menemukan route lama, update dengan mapping berikut:

| Route Lama         | Route Baru          | Status     |
| ------------------ | ------------------- | ---------- |
| `/user/beranda`    | `/home`             | ✅ Updated |
| `/user/profil`     | `/profile`          | ✅ Updated |
| `/user/modul`      | `/modul`            | ✅ Updated |
| `/user/pengaturan` | `/profile/settings` | ✅ Updated |
| `/reset-password`  | `/forgot-password`  | ✅ Updated |

---

## 📚 Referensi Cepat

### Membuat Halaman Baru

```dart
// 1. Buat file: lib/pages/kategori/nama_screen.dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class NamaScreen extends StatelessWidget {
  const NamaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Judul'),
      ),
      body: Container(),
    );
  }
}

// 2. Tambahkan di main.dart
import 'pages/kategori/nama_screen.dart';

routes: {
  '/nama': (context) => const NamaScreen(),
}
```

---

## 📞 Kontak & Bantuan

Jika ada pertanyaan tentang standar penamaan ini, silakan diskusikan dengan tim.

**Last Updated**: January 19, 2026
