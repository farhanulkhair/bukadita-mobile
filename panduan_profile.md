# Profile Screen Documentation

## Overview

Halaman profile untuk aplikasi BukaDita Mobile yang menampilkan informasi user dan menu-menu pengaturan.

## File Structure

```
lib/pages/profile/
├── profile_screen.dart          # Halaman utama profile
├── full_data_screen.dart        # Halaman data lengkap user
├── change_password_screen.dart  # Halaman ubah password
└── settings_screen.dart         # Halaman pengaturan aplikasi
```

## Fitur Profile Screen

### 1. Profile Header

- **Foto Profil**: Ditampilkan berbentuk bulat di tengah atas

  - Ukuran: 100x100 pixels
  - Border putih dengan shadow
  - Icon camera untuk ganti foto (fitur belum diimplementasi)
  - Default avatar jika tidak ada foto

- **Username**:

  - Ditampilkan di bawah foto profil
  - Warna putih dengan font bold
  - Tombol edit di samping untuk mengubah username
  - Icon edit dengan background semi-transparan

- **Email/Phone**:
  - Ditampilkan di bawah username
  - Warna putih dengan opacity 90%

### 2. Menu Items

Terdapat 3 menu utama dalam card putih:

#### a. Data Lengkap (`/profile/full-data`)

- Icon: `Icons.person_outline`
- Menampilkan informasi lengkap user:
  - ID
  - Nama
  - Email
  - Nomor Telepon
  - Role
  - Status Profil (Lengkap/Belum Lengkap)
- Tombol "Edit Profil" dengan gradient (belum diimplementasi)

#### b. Ubah Password (`/profile/change-password`)

- Icon: `Icons.lock_outline`
- Form untuk mengubah password:
  - Password Lama (required)
  - Password Baru (min. 6 karakter)
  - Konfirmasi Password Baru
- Validasi:
  - Semua field harus diisi
  - Password baru minimal 6 karakter
  - Konfirmasi password harus sama dengan password baru
- Toggle visibility password
- Tombol submit dengan loading indicator

#### c. Pengaturan (`/profile/settings`)

- Icon: `Icons.settings_outlined`
- Fitur pengaturan:
  - **Notifikasi**:
    - Toggle aktifkan/nonaktifkan notifikasi
    - Notifikasi Email (jika notifikasi aktif)
    - Push Notification (jika notifikasi aktif)
  - **Bahasa**:
    - Bahasa Indonesia (default)
    - English
  - **Tentang**:
    - Tentang Aplikasi (dialog info)
    - Kebijakan Privasi
    - Syarat & Ketentuan
- Tombol "Simpan Pengaturan" di bawah

### 3. Logout Button

- Warna merah dengan border
- Icon logout
- Konfirmasi dialog sebelum logout
- Membersihkan semua data lokal
- Redirect ke halaman login setelah logout

### 4. Bottom Navigation

- Tetap ada di halaman profile
- Index 2 (Profile)
- Navigasi ke:
  - Index 0: Beranda (`/home`)
  - Index 1: Modul (`/modules`)
  - Index 2: Profil (current)

## Routing

Routes yang ditambahkan di `main.dart`:

```dart
'/profile': ProfileScreen()
'/profile/full-data': FullDataScreen()
'/profile/change-password': ChangePasswordScreen()
'/profile/settings': SettingsScreen()
```

## Dependencies Used

- `flutter/material.dart` - UI components
- `../../theme/theme.dart` - Custom theme & colors
- `../../components/navigation/navigation.dart` - Bottom navigation bar
- `../../services/storage_service.dart` - Local storage
- `../../models/user_model.dart` - User data model

## Design Reference

Tampilan mengikuti gambar referensi yang diberikan dengan:

- Header gradient (primary to secondary)
- Foto profil bulat di tengah
- Username dengan icon edit
- Menu items dengan icon di card putih
- Tombol logout merah di bawah
- Bottom navigation tetap ada

## TODO / Fitur yang Belum Diimplementasi

1. ✅ Tampilan halaman profile
2. ✅ Bottom navigation
3. ✅ Logout functionality
4. ✅ Halaman full data
5. ✅ Halaman change password (UI only)
6. ✅ Halaman settings (UI only)
7. ⏳ Ganti foto profil (TODO)
8. ⏳ Update username API integration (TODO)
9. ⏳ Change password API integration (TODO)
10. ⏳ Update settings API integration (TODO)
11. ⏳ Edit profile API integration (TODO)

## Color Scheme

- Primary: `#578FCA`
- Secondary: `#27548A`
- Background: `#F5F7FA`
- White: `#FFFFFF`
- Red (logout): `#DC2626`
- Gray variations: 50-700

## Notes

- Semua halaman menggunakan custom theme dari `AppColors` dan `AppTextStyles`
- Error handling sudah diimplementasi untuk loading user data
- Konfirmasi dialog untuk logout mencegah aksi tidak disengaja
- Responsive design dengan padding dan spacing yang konsisten
