# 🎨 Layout System - BukaDita Mobile

## Overview

Layout system untuk memisahkan logic navigasi dari screen content, membuat code lebih clean dan mudah di-maintain.

---

## 📦 AppLayout

File: `lib/layouts/app_layout.dart`

### Purpose

Wrapper untuk halaman-halaman utama yang memiliki **Bottom Navigation Bar**. Dengan menggunakan `AppLayout`, Anda tidak perlu menulis ulang `BottomNavBar` dan navigation logic di setiap halaman.

### Features

- ✅ Otomatis include Bottom Navigation Bar
- ✅ Handle navigation logic secara terpusat
- ✅ Prevent navigation ke halaman yang sama (optimization)
- ✅ Konsisten di semua halaman utama

---

## 🎯 Kapan Menggunakan AppLayout?

### ✅ GUNAKAN AppLayout untuk:

**3 Halaman Utama dengan Bottom Nav:**

1. **Home Screen** (`home_screen.dart`) - `currentIndex: 0`
2. **Modul Screen** (`modul_screen.dart`) - `currentIndex: 1`
3. **Profile Screen** (`profile_screen.dart`) - `currentIndex: 2`

```dart
// Contoh: home_screen.dart
return AppLayout(
  currentIndex: 0, // Home
  child: Scaffold(
    appBar: AppBar(title: Text('Home')),
    body: YourContent(),
  ),
);
```

### ❌ JANGAN Gunakan AppLayout untuk:

**Halaman-halaman Detail/Sub-Halaman:**

- Login Screen
- Forgot Password Screen
- Full Data Screen
- Change Password Screen
- Settings Screen
- Notification Screen
- Dan semua halaman yang punya **back button**

```dart
// Contoh: settings_screen.dart
return Scaffold(
  appBar: AppBar(
    title: Text('Settings'),
    // Back button otomatis muncul
  ),
  body: YourContent(),
);
```

---

## 🔧 Cara Menggunakan

### 1. Import AppLayout

```dart
import '../../layouts/app_layout.dart';
```

### 2. Wrap Scaffold dengan AppLayout

```dart
@override
Widget build(BuildContext context) {
  return AppLayout(
    currentIndex: 0, // 0=Home, 1=Modul, 2=Profile
    child: Scaffold(
      // Your screen content
    ),
  );
}
```

### 3. Selesai!

Navigation sudah otomatis handle oleh `AppLayout`. Tidak perlu tambah `bottomNavigationBar` lagi.

---

## 📋 Contoh Implementasi

### Home Screen

```dart
import 'package:flutter/material.dart';
import '../../layouts/app_layout.dart';
import '../../theme/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0, // Home active
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Beranda'),
        ),
        body: Center(
          child: Text('Home Content'),
        ),
      ),
    );
  }
}
```

### Modul Screen

```dart
import 'package:flutter/material.dart';
import '../../layouts/app_layout.dart';
import '../../theme/theme.dart';

class ModulScreen extends StatelessWidget {
  const ModulScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 1, // Modul active
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Modul'),
        ),
        body: Center(
          child: Text('Modul Content'),
        ),
      ),
    );
  }
}
```

### Profile Screen

```dart
import 'package:flutter/material.dart';
import '../../layouts/app_layout.dart';
import '../../theme/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 2, // Profile active
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Profile Content'),
        ),
      ),
    );
  }
}
```

### Settings Screen (Tanpa AppLayout)

```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TIDAK menggunakan AppLayout
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
        // Back button otomatis muncul
      ),
      body: Center(
        child: Text('Settings Content'),
      ),
    );
  }
}
```

---

## 🔀 Navigation Flow

### Bottom Navigation (via AppLayout)

```
Home ←→ Modul ←→ Profile
 (0)     (1)      (2)
```

Saat user tap bottom nav:

- AppLayout otomatis navigate ke route yang sesuai
- Menggunakan `pushReplacementNamed` (replace current page)
- Jika sudah di halaman tersebut, tidak navigate (optimization)

### Sub-Page Navigation

```
Profile → Settings → Back to Profile
Profile → Change Password → Back to Profile
Profile → Full Data → Back to Profile
```

Saat user tap menu item:

- Screen menggunakan `Navigator.pushNamed`
- Halaman baru push ke navigation stack
- User bisa back dengan tombol back

---

## 🎨 Internal Logic AppLayout

```dart
void _handleNavigation(BuildContext context, int index) {
  // Jangan navigate jika sudah di halaman yang sama
  if (index == currentIndex) return;

  // Navigate ke halaman yang sesuai
  switch (index) {
    case 0:
      Navigator.pushReplacementNamed(context, '/home');
      break;
    case 1:
      Navigator.pushReplacementNamed(context, '/modul');
      break;
    case 2:
      Navigator.pushReplacementNamed(context, '/profile');
      break;
  }
}
```

---

## ✅ Keuntungan Layout System

### 1. **DRY Principle** (Don't Repeat Yourself)

- Navigation logic hanya ditulis 1x di `AppLayout`
- Tidak perlu copy-paste `BottomNavBar` code

### 2. **Easy Maintenance**

- Update navigation? Hanya edit 1 file (`app_layout.dart`)
- Semua halaman otomatis terupdate

### 3. **Consistency**

- Semua halaman utama pasti punya bottom nav
- Navigation behavior konsisten

### 4. **Clean Code**

- Screen focus pada content, bukan navigation
- Separation of concerns yang jelas

### 5. **Less Code**

Sebelum:

```dart
// Di SETIAP screen (60+ lines)
bottomNavigationBar: BottomNavBar(
  currentIndex: 0,
  onTap: (index) {
    if (index == 1) Navigator.pushReplacementNamed(context, '/modul');
    if (index == 2) Navigator.pushReplacementNamed(context, '/profile');
  },
),
```

Sesudah:

```dart
// Cukup 1 line!
return AppLayout(currentIndex: 0, child: Scaffold(...));
```

---

## 🚀 Ekstensibilitas

### Menambah Tab Baru ke Bottom Nav

1. **Update BottomNavBar** di `navigation.dart`:

```dart
_buildNavItem(
  icon: Icons.new_icon,
  label: 'New Tab',
  index: 3,
  isActive: currentIndex == 3,
),
```

2. **Update AppLayout** di `app_layout.dart`:

```dart
case 3:
  Navigator.pushReplacementNamed(context, '/new-tab');
  break;
```

3. **Buat Screen Baru** dengan `AppLayout`:

```dart
return AppLayout(
  currentIndex: 3,
  child: Scaffold(...),
);
```

Selesai! Semua halaman otomatis punya tab baru.

---

## 📚 Best Practices

1. **Selalu gunakan AppLayout untuk halaman dengan bottom nav**

   ```dart
   ✅ return AppLayout(currentIndex: 0, child: Scaffold(...));
   ❌ return Scaffold(bottomNavigationBar: BottomNavBar(...));
   ```

2. **Jangan gunakan AppLayout untuk sub-halaman**

   ```dart
   ✅ return Scaffold(appBar: AppBar(...));
   ❌ return AppLayout(currentIndex: X, child: Scaffold(...));
   ```

3. **Set currentIndex sesuai halaman**

   ```dart
   ✅ HomeScreen → currentIndex: 0
   ✅ ModulScreen → currentIndex: 1
   ✅ ProfileScreen → currentIndex: 2
   ❌ HomeScreen → currentIndex: 1 (salah!)
   ```

4. **Import hanya yang diperlukan**

   ```dart
   // Halaman dengan AppLayout
   import '../../layouts/app_layout.dart';

   // Halaman tanpa AppLayout (tidak perlu import navigation)
   // import '../../components/navigation/navigation.dart'; ❌
   ```

---

## 🔍 Troubleshooting

### Bottom Nav tidak muncul?

- Pastikan menggunakan `AppLayout`
- Cek `currentIndex` sudah di-set

### Navigation tidak jalan?

- Cek route sudah terdaftar di `main.dart`
- Pastikan route name sesuai di `AppLayout`

### Back button muncul di halaman utama?

- Jangan gunakan `AppLayout` di sub-halaman
- Sub-halaman gunakan `Scaffold` biasa

---

**Last Updated**: January 19, 2026
