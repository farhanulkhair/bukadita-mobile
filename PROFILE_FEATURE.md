# Profile Feature Implementation

## Overview

Dokumentasi implementasi fitur profil lengkap dengan upload foto dan update data user.

## Changes Made

### 1. UserModel Update

**File**: `lib/models/user_model.dart`

**Changes**:

- ✅ Added `address` field (nullable String)
- ✅ Updated `fromJson()`, `toJson()`, and `copyWith()` methods

**Fields**:

```dart
- id (String)
- email (String?)
- phone (String?)
- name (String) // Nama lengkap
- avatar (String?)
- address (String?) // NEW
- role (String)
- isProfileComplete (bool)
```

---

### 2. Full Data Screen Update

**File**: `lib/pages/profile/full_data_screen.dart`

**Changes**:

- ✅ Changed "Nama" → "Nama Lengkap"
- ✅ Changed "Nomor Telepon" → "Nomor HP"
- ✅ Added "Alamat" field
- ❌ Removed "ID" field
- ❌ Removed "Role" field
- ❌ Removed "Status Profil" field

**Display Fields**:

1. Nama Lengkap
2. Email
3. Nomor HP
4. Alamat

---

### 3. ProfileService (NEW)

**File**: `lib/services/profile_service.dart`

**Features**:

- ✅ `uploadProfilePhoto(File)` - Upload foto profil via multipart/form-data
- ✅ `deleteProfilePhoto()` - Hapus foto profil
- ✅ `updateProfile()` - Update nama, phone, atau alamat
- ✅ Auto-update local storage setelah berhasil

**API Endpoints Used**:

- `POST /api/v1/users/me/profile-photo` - Upload foto
- `DELETE /api/v1/users/me/profile-photo` - Delete foto
- `PUT /api/v1/users/me` - Update profil

---

### 4. Profile Screen Enhancement

**File**: `lib/pages/profile/profile_screen.dart`

**New Features**:

#### A. Upload Foto Profil

- ✅ Dialog pilihan sumber foto (Kamera / Galeri)
- ✅ Image compression (max 1024x1024, quality 85%)
- ✅ Loading indicator saat upload
- ✅ Auto refresh setelah upload
- ✅ Error handling

**Flow**:

1. Tap ikon kamera pada foto profil
2. Pilih sumber (Kamera/Galeri)
3. Pilih foto
4. Upload otomatis
5. Foto profil update

#### B. Update Nama Lengkap

- ✅ Dialog edit nama
- ✅ API integration
- ✅ Auto refresh setelah update
- ✅ Error handling

**Flow**:

1. Tap ikon edit di samping nama
2. Input nama baru
3. Tap Simpan
4. Nama update otomatis

---

### 5. Dependencies Added

**File**: `pubspec.yaml`

```yaml
# Image Picker
image_picker: ^1.0.7 # For picking images from gallery/camera
http_parser: ^4.0.2 # For MIME type parsing
```

**Installation**:

```bash
flutter pub get
```

---

## Usage Guide

### Upload Profile Photo

```dart
// In profile_screen.dart
Future<void> _handleChangePhoto() async {
  // 1. Show dialog to choose source
  final source = await showDialog<ImageSource>(...);

  // 2. Pick image
  final XFile? pickedFile = await _imagePicker.pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  // 3. Upload to server
  final result = await _profileService.uploadProfilePhoto(
    File(pickedFile.path),
  );

  // 4. Reload user data
  await _loadUserData();
}
```

### Update Profile Name

```dart
Future<void> _handleUpdateName(String newName) async {
  final result = await _profileService.updateProfile(name: newName);
  await _loadUserData();
}
```

### Update Other Fields

```dart
// Update phone
await _profileService.updateProfile(phone: '081234567890');

// Update address
await _profileService.updateProfile(address: 'Jl. Contoh No. 123');

// Update multiple fields
await _profileService.updateProfile(
  name: 'John Doe',
  phone: '081234567890',
  address: 'Jl. Contoh No. 123',
);
```

---

## API Response Format

### Upload Profile Photo

**Success Response**:

```json
{
  "error": false,
  "message": "Profile photo uploaded successfully",
  "data": {
    "id": "uuid",
    "avatar": "https://example.com/avatar.jpg",
    ...
  }
}
```

### Update Profile

**Success Response**:

```json
{
  "error": false,
  "message": "Profile updated successfully",
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "phone": "081234567890",
    "address": "Jl. Contoh No. 123",
    ...
  }
}
```

---

## Error Handling

### Common Errors

1. **Token tidak ditemukan**

   - User belum login atau token expired
   - Redirect ke halaman login

2. **Upload gagal**

   - File terlalu besar (max 5MB)
   - Format tidak didukung
   - Network error

3. **Update gagal**
   - Validation error (nama kosong, dll)
   - Server error
   - Network error

### Error Display

- ✅ SnackBar dengan pesan error
- ✅ Background merah untuk error
- ✅ Background hijau untuk success

---

## Testing Checklist

### Upload Photo

- [ ] Upload dari Galeri
- [ ] Upload dari Kamera
- [ ] Cancel dialog
- [ ] Loading indicator muncul
- [ ] Foto update setelah upload
- [ ] Error handling (file besar, network error)

### Update Name

- [ ] Open edit dialog
- [ ] Input nama baru
- [ ] Cancel dialog
- [ ] Save nama baru
- [ ] Nama update di UI
- [ ] Error handling (nama kosong, network error)

### Full Data Screen

- [ ] Display Nama Lengkap
- [ ] Display Email
- [ ] Display Nomor HP
- [ ] Display Alamat
- [ ] Tidak ada ID
- [ ] Tidak ada Role

---

## Notes

1. **Image Compression**: Foto otomatis di-compress ke 1024x1024px dengan quality 85%
2. **MIME Type**: Support jpeg, png, gif, webp
3. **Max File Size**: 5MB (diatur di backend)
4. **Auto Refresh**: Local storage otomatis update setelah operasi berhasil
5. **Loading State**: `_isUploadingPhoto` untuk disable button saat upload

---

## Future Improvements

- [ ] Crop image before upload
- [ ] Preview image before upload
- [ ] Multiple photo upload for gallery
- [ ] Edit address with autocomplete
- [ ] Verify phone number
- [ ] Email verification
- [ ] Delete account feature
- [ ] Export user data

---

**Last Updated**: January 19, 2026
