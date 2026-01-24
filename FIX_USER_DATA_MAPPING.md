# Fix User Data Mapping - API Integration

## Problem Found

### Issue

User data tampil kosong di halaman Full Data karena **mismatch field names** antara:

- **Mobile App** menggunakan `camelCase`: `name`, `avatar`, `dateOfBirth`
- **API/Database** menggunakan `snake_case`: `full_name`, `profil_url`, `date_of_birth`

### Debug Output

```
User Data: {
  id: ec6211cf-3f52-46d7-a7fb-1ac6c836fcdc,
  email: farhan@gmail.com,
  phone: null,
  name: ,  ← EMPTY!
  avatar: null,
  address: null
}
```

---

## Root Cause Analysis

### 1. API Response Structure

**Login Response** (`POST /api/v1/auth/login`):

```json
{
  "error": false,
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "user": {
      "id": "...",
      "email": "...",
      "profile": {  ← NESTED OBJECT!
        "full_name": "Farhan",  ← Not "name"
        "phone": "08123456789",
        "profil_url": "https://...",  ← Not "avatar"
        "address": "...",
        "date_of_birth": "...",
        "role": "user"
      }
    }
  }
}
```

**Get User Profile** (`GET /api/v1/users/me`):

```json
{
  "error": false,
  "data": {  ← Direct, not nested
    "id": "...",
    "full_name": "Farhan",
    "phone": "08123456789",
    "email": "...",
    "profil_url": "https://...",
    "address": "...",
    "date_of_birth": "...",
    "role": "user"
  }
}
```

### 2. Field Name Mapping

| Database/API    | Old Mobile App  | Issue       |
| --------------- | --------------- | ----------- |
| `full_name`     | `name`          | ❌ Mismatch |
| `profil_url`    | `avatar`        | ❌ Mismatch |
| `date_of_birth` | `date_of_birth` | ✅ Match    |
| `phone`         | `phone`         | ✅ Match    |
| `address`       | `address`       | ✅ Match    |

---

## Solutions Implemented

### ✅ Fix 1: UserModel.fromJson() - Handle Both Formats

**File**: `lib/models/user_model.dart`

```dart
factory UserModel.fromJson(Map<String, dynamic> json) {
  // Handle both direct response and nested profile structure
  final profileData = json['profile'] ?? json;

  return UserModel(
    id: json['id'] ?? '',
    email: json['email'],
    phone: profileData['phone'],
    // API uses 'full_name', fallback to 'name' for backward compatibility
    name: profileData['full_name'] ?? json['name'] ?? '',
    // API uses 'profil_url', fallback to 'avatar' for backward compatibility
    avatar: profileData['profil_url'] ?? json['avatar'],
    address: profileData['address'],
    date_of_birth: profileData['date_of_birth'],
    role: profileData['role'] ?? json['role'] ?? 'user',
    // Dynamic profile completeness check
    isProfileComplete: (profileData['full_name'] ?? json['name'] ?? '').isNotEmpty &&
                      (profileData['phone'] ?? '') != '',
  );
}
```

**Key Changes**:

- ✅ Handle nested `profile` object from login response
- ✅ Map `full_name` → `name`
- ✅ Map `profil_url` → `avatar`
- ✅ Fallback untuk backward compatibility
- ✅ Dynamic `isProfileComplete` logic

---

### ✅ Fix 2: Auto-Refresh Profile After Login

**File**: `lib/services/auth_service.dart`

```dart
// After successful login, auto-refresh profile
if (loginResponse.success && loginResponse.data != null) {
  // Save tokens and basic user data
  await _storageService.saveAccessToken(...);
  await _storageService.saveRefreshToken(...);
  await _storageService.saveUserData(loginResponse.data!.user);

  // NEW: Refresh user profile dari API untuk data lengkap
  try {
    await _refreshUserProfile();
  } catch (e) {
    print('Warning: Gagal refresh user profile: $e');
  }
}

// NEW: Private method to fetch complete profile
Future<void> _refreshUserProfile() async {
  final token = await _storageService.getAccessToken();
  if (token == null) return;

  final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me');
  final response = await http.get(uri, headers: ApiConfig.authHeaders(token));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['data'] != null) {
      final userData = UserModel.fromJson(data['data']);
      await _storageService.saveUserData(userData);
    }
  }
}
```

**Benefits**:

- ✅ Automatic fetch dari `/api/v1/users/me` setelah login
- ✅ Mendapatkan data profil lengkap langsung
- ✅ Tidak perlu refresh manual
- ✅ Silent failure (tidak block login jika gagal)

---

### ✅ Fix 3: Update ProfileService Mapping

**File**: `lib/services/profile_service.dart`

#### Upload Photo:

```dart
// Update user data di storage
final avatarUrl = data['data']['profil_url'] ?? data['data']['avatar'];
final updatedUser = userData.copyWith(avatar: avatarUrl);
```

#### Update Profile:

```dart
// Send to API with snake_case
body: json.encode({
  if (name != null) 'full_name': name,  // Not 'name'
  if (phone != null) 'phone': phone,
  if (address != null) 'address': address,
}),

// Parse response with correct field
name: data['data']['full_name'] ?? userData.name,  // Not 'name'
```

---

## Testing Checklist

### Before Fix:

```
DEBUG USER DATA:
Name:              ← EMPTY
Email: farhan@gmail.com
Phone: null
Address: null
```

### After Fix (Expected):

```
DEBUG USER DATA:
Name: Farhan       ← FILLED!
Email: farhan@gmail.com
Phone: 08123456789  ← FILLED!
Address: Jl. ...    ← FILLED!
```

---

## Test Steps

1. **Logout** dari aplikasi
2. **Login ulang** dengan akun yang sudah ada
3. **Lihat console** output:
   ```
   ===== REFRESH USER PROFILE =====
   Status: 200
   Response: {...}
   ==============================
   ```
4. **Buka halaman Full Data** → Data lengkap harus muncul
5. **Test fitur**:
   - ✅ Upload foto profil
   - ✅ Edit nama
   - ✅ Lihat data lengkap

---

## API Endpoints Used

| Endpoint                         | Method | Purpose          | Response Format         |
| -------------------------------- | ------ | ---------------- | ----------------------- |
| `/api/v1/auth/login`             | POST   | Login user       | Nested `profile` object |
| `/api/v1/users/me`               | GET    | Get full profile | Direct `data` object    |
| `/api/v1/users/me`               | PUT    | Update profile   | Direct `data` object    |
| `/api/v1/users/me/profile-photo` | POST   | Upload photo     | Returns `profil_url`    |

---

## Field Name Reference

### Storage (Internal)

- `name` (String) - Nama lengkap user
- `avatar` (String?) - URL foto profil
- `phone` (String?) - Nomor telepon
- `address` (String?) - Alamat
- `date_of_birth` (String?) - Tanggal lahir

### API (External)

- `full_name` - Nama lengkap
- `profil_url` - URL foto profil
- `phone` - Nomor telepon
- `address` - Alamat
- `date_of_birth` - Tanggal lahir

### Mapping Layer

UserModel handles conversion automatically:

- `full_name` ↔ `name`
- `profil_url` ↔ `avatar`
- Direct fields remain the same

---

## Important Notes

1. **Backward Compatibility**: Code masih support old format (camelCase) untuk fallback
2. **Auto-Refresh**: Setiap login otomatis fetch data lengkap dari API
3. **Debug Logging**: Tetap aktif untuk troubleshooting (bisa di-remove nanti)
4. **Profile Completeness**: Dihitung dynamic dari field yang terisi

---

**Last Updated**: January 19, 2026
**Status**: ✅ Ready for Testing
