# Dokumentasi API Endpoints - Bukadita User v2

Dokumentasi ini berisi semua endpoint API yang dikonsumsi oleh aplikasi Bukadita User v2. Base URL backend adalah `http://localhost:4000/api/v1` atau sesuai environment variable `NEXT_PUBLIC_BACKEND_URL`.

---

## 📋 Daftar Isi

1. [Authentication & Profile](#authentication--profile)
2. [Modules & Materials](#modules--materials)
3. [Progress Tracking](#progress-tracking)
4. [Quiz System](#quiz-system)
5. [User Notes](#user-notes)
6. [Response Format](#response-format)

---

## Authentication & Profile

### 1. Register User

Endpoint ini digunakan untuk mendaftarkan pengguna baru ke dalam sistem dengan menggunakan email, password, dan nama lengkap.

- **URL**: `POST /api/v1/auth/register`
- **Authentication**: Tidak diperlukan
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123",
    "full_name": "John Doe",
    "phone": "081234567890"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "REGISTER_SUCCESS",
    "message": "User registered successfully",
    "data": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires_at": 1704123456789,
      "user": {
        "id": "uuid-string",
        "email": "user@example.com",
        "email_confirmed_at": null,
        "profile": {
          "id": "profile-uuid",
          "full_name": "John Doe",
          "phone": "081234567890",
          "address": null,
          "date_of_birth": null,
          "profil_url": null,
          "role": null,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z"
        }
      }
    }
  }
  ```

### 2. Login User

Endpoint ini digunakan untuk login pengguna menggunakan email atau nomor telepon sebagai identifier dan password.

- **URL**: `POST /api/v1/auth/login`
- **Authentication**: Tidak diperlukan
- **Request Body**:
  ```json
  {
    "identifier": "user@example.com",
    "password": "password123"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "LOGIN_SUCCESS",
    "message": "Login successful",
    "data": {
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expires_at": 1704123456789,
      "user": {
        "id": "uuid-string",
        "email": "user@example.com",
        "email_confirmed_at": "2024-01-01T00:00:00.000Z",
        "profile": {
          "id": "profile-uuid",
          "full_name": "John Doe",
          "phone": "081234567890",
          "address": "Jakarta",
          "date_of_birth": "1990-01-01",
          "profil_url": "https://example.com/photo.jpg",
          "role": "user",
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z"
        }
      }
    }
  }
  ```

### 3. Logout User

Endpoint ini digunakan untuk logout pengguna dan menghapus session token dari server.

- **URL**: `POST /api/v1/auth/logout`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {}
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "LOGOUT_SUCCESS",
    "message": "Logout successful",
    "data": null
  }
  ```

### 4. Upsert User Profile

Endpoint ini digunakan untuk membuat atau memperbarui profil pengguna yang sedang login.

- **URL**: `POST /api/v1/auth/profile`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "full_name": "John Doe Updated",
    "phone": "081234567890",
    "address": "Jakarta Selatan",
    "date_of_birth": "1990-01-01",
    "role": "user"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PROFILE_UPDATED",
    "message": "Profile updated successfully",
    "data": {
      "profile": {
        "id": "profile-uuid",
        "full_name": "John Doe Updated",
        "phone": "081234567890",
        "address": "Jakarta Selatan",
        "date_of_birth": "1990-01-01",
        "profil_url": null,
        "role": "user",
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-02T00:00:00.000Z"
      }
    }
  }
  ```

### 5. Create Missing Profile

Endpoint ini digunakan untuk membuat profil yang hilang atau belum ada untuk pengguna yang sudah terdaftar.

- **URL**: `POST /api/v1/auth/create-missing-profile`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "full_name": "John Doe",
    "phone": "081234567890",
    "address": "Jakarta",
    "date_of_birth": "1990-01-01"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PROFILE_CREATED",
    "message": "Profile created successfully",
    "data": {
      "profile": {
        "id": "profile-uuid",
        "full_name": "John Doe",
        "phone": "081234567890",
        "address": "Jakarta",
        "date_of_birth": "1990-01-01",
        "profil_url": null,
        "role": null,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    }
  }
  ```

### 6. Get Current User Profile

Endpoint ini digunakan untuk mendapatkan informasi profil pengguna yang sedang login.

- **URL**: `GET /api/v1/users/me`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PROFILE_FETCH_SUCCESS",
    "message": "Profile fetched successfully",
    "data": {
      "id": "uuid-string",
      "full_name": "John Doe",
      "phone": "081234567890",
      "email": "user@example.com",
      "address": "Jakarta Selatan",
      "profil_url": "https://example.com/photo.jpg",
      "date_of_birth": "1990-01-01",
      "role": "user",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-02T00:00:00.000Z"
    }
  }
  ```

### 7. Update User Profile

Endpoint ini digunakan untuk memperbarui informasi profil pengguna yang sedang login.

- **URL**: `PUT /api/v1/users/me`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "full_name": "John Doe Updated",
    "phone": "081234567890",
    "email": "newemail@example.com",
    "address": "Jakarta Pusat",
    "date_of_birth": "1990-01-01"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PROFILE_UPDATE_SUCCESS",
    "message": "Profile updated successfully",
    "data": {
      "id": "uuid-string",
      "full_name": "John Doe Updated",
      "phone": "081234567890",
      "email": "newemail@example.com",
      "address": "Jakarta Pusat",
      "profil_url": "https://example.com/photo.jpg",
      "date_of_birth": "1990-01-01",
      "role": "user",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-03T00:00:00.000Z"
    }
  }
  ```

### 8. Upload Profile Photo

Endpoint ini digunakan untuk mengupload foto profil pengguna dalam format multipart/form-data dengan maksimal ukuran file 5MB.

- **URL**: `POST /api/v1/users/me/profile-photo`
- **Authentication**: Bearer token diperlukan
- **Request Body**: FormData dengan field `photo` berisi file gambar
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PHOTO_UPLOAD_SUCCESS",
    "message": "Profile photo uploaded successfully",
    "data": {
      "profile": {
        "id": "uuid-string",
        "full_name": "John Doe",
        "phone": "081234567890",
        "email": "user@example.com",
        "address": "Jakarta",
        "profil_url": "https://example.com/uploads/photo.jpg",
        "date_of_birth": "1990-01-01",
        "role": "user",
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-04T00:00:00.000Z"
      },
      "photo_url": "https://example.com/uploads/photo.jpg",
      "filename": "photo_uuid.jpg"
    }
  }
  ```

### 9. Delete Profile Photo

Endpoint ini digunakan untuk menghapus foto profil pengguna dan mengembalikan ke foto default.

- **URL**: `DELETE /api/v1/users/me/profile-photo`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PHOTO_DELETE_SUCCESS",
    "message": "Profile photo deleted successfully",
    "data": {
      "profile": {
        "id": "uuid-string",
        "full_name": "John Doe",
        "phone": "081234567890",
        "email": "user@example.com",
        "address": "Jakarta",
        "profil_url": null,
        "date_of_birth": "1990-01-01",
        "role": "user",
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-05T00:00:00.000Z"
      }
    }
  }
  ```

### 10. Change Password

Endpoint ini digunakan untuk mengubah password pengguna dengan memvalidasi password lama terlebih dahulu.

- **URL**: `POST /api/v1/users/me/change-password`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "currentPassword": "oldpassword123",
    "newPassword": "newpassword456"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PASSWORD_CHANGE_SUCCESS",
    "message": "Password changed successfully",
    "data": null
  }
  ```

---

## Modules & Materials

### 11. Get All Modules

Endpoint ini digunakan untuk mendapatkan semua modul pembelajaran yang telah dipublikasikan dalam sistem dengan pagination.

- **URL**: `GET /api/v1/modules?limit=100&page=1`
- **Authentication**: Tidak diperlukan (public access)
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "MODULES_FETCH_SUCCESS",
    "message": "Modules fetched successfully",
    "data": {
      "items": [
        {
          "id": "uuid-string",
          "title": "Bayi dan Balita",
          "slug": "bayi-balita",
          "description": "Modul pembelajaran tentang kesehatan bayi dan balita",
          "category": "Kesehatan Anak",
          "published": true,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
          "duration_label": "2 jam",
          "duration_minutes": 120,
          "lessons": 5,
          "sub_materis": []
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 100,
        "total": 10,
        "totalPages": 1
      }
    }
  }
  ```

### 12. Get Module Detail

Endpoint ini digunakan untuk mendapatkan detail modul tertentu beserta sub-materi yang terkait dengan modul tersebut.

- **URL**: `GET /api/v1/modules/:moduleId`
- **Authentication**: Tidak diperlukan (public access)
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "MODULE_DETAIL_SUCCESS",
    "message": "Module detail fetched successfully",
    "data": {
      "id": "uuid-string",
      "title": "Bayi dan Balita",
      "slug": "bayi-balita",
      "description": "Modul pembelajaran tentang kesehatan bayi dan balita",
      "category": "Kesehatan Anak",
      "published": true,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z",
      "duration_label": "2 jam",
      "duration_minutes": 120,
      "lessons": 5,
      "sub_materis": [
        {
          "id": "sub-materi-uuid",
          "module_id": "uuid-string",
          "title": "Pengenalan Bayi",
          "order_index": 1,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z",
          "content": "Konten pembelajaran...",
          "published": true
        }
      ]
    }
  }
  ```

### 13. Get Materials by Module ID

Endpoint ini digunakan untuk mendapatkan semua sub-materi yang terkait dengan modul tertentu dengan pagination support.

- **URL**: `GET /api/v1/materials/public?module_id={moduleId}&page=1&limit=100`
- **Authentication**: Tidak diperlukan (public access)
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "MATERIALS_FETCH_SUCCESS",
    "message": "Materials fetched successfully",
    "data": [
      {
        "id": "material-uuid",
        "module_id": "module-uuid",
        "title": "Pengenalan Bayi",
        "order_index": 1,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z",
        "content": "Konten pembelajaran...",
        "published": true,
        "description": "Deskripsi materi"
      }
    ]
  }
  ```

### 14. Get Material Detail (Public)

Endpoint ini digunakan untuk mendapatkan detail sub-materi termasuk poin-poin pembelajaran dan kuis yang terkait.

- **URL**: `GET /api/v1/materials/:materialId/public`
- **Authentication**: Tidak diperlukan (public access)
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "MATERIAL_DETAIL_SUCCESS",
    "message": "Material detail fetched successfully",
    "data": {
      "id": "material-uuid",
      "module_id": "module-uuid",
      "title": "Pengenalan Bayi",
      "order_index": 1,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z",
      "content": "Konten pembelajaran...",
      "published": true,
      "description": "Deskripsi materi",
      "poin_details": [
        {
          "id": "poin-uuid",
          "sub_materi_id": "material-uuid",
          "title": "Poin 1: Karakteristik Bayi",
          "content_html": "<p>Konten HTML...</p>",
          "duration_label": "15 menit",
          "duration_minutes": 15,
          "order_index": 1,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z"
        }
      ],
      "quizzes": [
        {
          "id": "quiz-uuid",
          "module_id": "module-uuid",
          "sub_materi_id": "material-uuid",
          "quiz_type": "sub",
          "title": "Kuis Pengenalan Bayi",
          "description": "Kuis untuk menguji pemahaman",
          "time_limit_seconds": 600,
          "passing_score": 70,
          "published": true,
          "created_at": "2024-01-01T00:00:00.000Z",
          "updated_at": "2024-01-01T00:00:00.000Z"
        }
      ]
    }
  }
  ```

### 15. Get Material Points

Endpoint ini digunakan untuk mendapatkan semua poin pembelajaran dari suatu sub-materi tertentu.

- **URL**: `GET /api/v1/materials/:materialId/points`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "POIN_FETCH_SUCCESS",
    "message": "Successfully fetched 5 poin details",
    "data": [
      {
        "id": "poin-uuid",
        "sub_materi_id": "material-uuid",
        "title": "Poin 1: Karakteristik Bayi",
        "content_html": "<p>Konten HTML...</p>",
        "duration_label": "15 menit",
        "duration_minutes": 15,
        "order_index": 1,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    ]
  }
  ```

### 16. Get Material Quizzes

Endpoint ini digunakan untuk mendapatkan semua kuis yang terkait dengan sub-materi tertentu.

- **URL**: `GET /api/v1/materials/:materialId/quizzes`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_FETCH_SUCCESS",
    "message": "Successfully fetched 2 quizzes",
    "data": [
      {
        "id": "quiz-uuid",
        "module_id": "module-uuid",
        "sub_materi_id": "material-uuid",
        "quiz_type": "sub",
        "title": "Kuis Pengenalan Bayi",
        "description": "Kuis untuk menguji pemahaman",
        "time_limit_seconds": 600,
        "passing_score": 70,
        "published": true,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    ]
  }
  ```

### 17. Get Quiz for Sub-Materi

Endpoint ini digunakan untuk mendapatkan kuis yang terkait dengan sub-materi tertentu (akses public).

- **URL**: `GET /api/v1/materials/:subMateriId/quiz`
- **Authentication**: Tidak diperlukan (public access)
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_FETCH_SUCCESS",
    "message": "Quiz fetched successfully",
    "data": {
      "quiz": {
        "id": "quiz-uuid",
        "module_id": "module-uuid",
        "sub_materi_id": "material-uuid",
        "quiz_type": "sub",
        "title": "Kuis Pengenalan Bayi",
        "description": "Kuis untuk menguji pemahaman",
        "time_limit_seconds": 600,
        "passing_score": 70,
        "published": true,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    }
  }
  ```

---

## Progress Tracking

### 18. Get User Modules Progress

Endpoint ini digunakan untuk mendapatkan progress pengguna pada semua modul pembelajaran yang tersedia.

- **URL**: `GET /api/v1/progress/modules`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PROGRESS_FETCH_SUCCESS",
    "message": "Progress fetched successfully",
    "data": {
      "modules": [
        {
          "id": 1,
          "module_id": 1,
          "progress_percentage": 75.5,
          "completed": false,
          "last_accessed_at": "2024-01-10T10:30:00.000Z",
          "started_at": "2024-01-05T08:00:00.000Z",
          "completed_at": null
        }
      ]
    }
  }
  ```

### 19. Get Module Progress with Detail

Endpoint ini digunakan untuk mendapatkan progress detail pengguna pada modul tertentu beserta informasi sub-materi.

- **URL**: `GET /api/v1/progress/modules/:moduleId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "MODULE_PROGRESS_SUCCESS",
    "message": "Module progress fetched successfully",
    "data": {
      "id": "uuid-string",
      "user_id": "user-uuid",
      "module_id": "module-uuid",
      "status": "in-progress",
      "progress_percent": 75.5,
      "last_accessed_at": "2024-01-10T10:30:00.000Z",
      "created_at": "2024-01-05T08:00:00.000Z",
      "updated_at": "2024-01-10T10:30:00.000Z",
      "completed": false,
      "completed_at": null,
      "progress_percentage": 75.5
    }
  }
  ```

### 20. Get Sub-Materi Progress

Endpoint ini digunakan untuk mendapatkan progress pengguna pada sub-materi tertentu termasuk status unlock dan completion.

- **URL**: `GET /api/v1/progress/sub-materis/:subMateriId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PROGRESS_FETCH_SUCCESS",
    "message": "Sub-materi progress fetched successfully",
    "data": {
      "id": "progress-uuid",
      "user_id": "user-uuid",
      "sub_materi_id": "sub-materi-uuid",
      "is_unlocked": true,
      "is_completed": false,
      "current_poin_index": 3,
      "progress_percent": 60.0,
      "last_accessed_at": "2024-01-10T10:30:00.000Z",
      "created_at": "2024-01-05T08:00:00.000Z",
      "updated_at": "2024-01-10T10:30:00.000Z",
      "completed_at": null
    }
  }
  ```

### 21. Complete Sub-Materi

Endpoint ini digunakan untuk menandai sub-materi sebagai selesai dan memperbarui progress modul terkait.

- **URL**: `POST /api/v1/progress/sub-materis/:subMateriId/complete`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "module_id": 1
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "SUB_MATERI_COMPLETED",
    "message": "Sub-materi completed successfully",
    "data": {
      "id": "progress-uuid",
      "user_id": "user-uuid",
      "sub_materi_id": "sub-materi-uuid",
      "is_unlocked": true,
      "is_completed": true,
      "current_poin_index": 5,
      "progress_percent": 100.0,
      "last_accessed_at": "2024-01-10T11:00:00.000Z",
      "created_at": "2024-01-05T08:00:00.000Z",
      "updated_at": "2024-01-10T11:00:00.000Z",
      "completed_at": "2024-01-10T11:00:00.000Z"
    }
  }
  ```

### 22. Check Sub-Materi Access

Endpoint ini digunakan untuk memeriksa apakah pengguna memiliki akses untuk membuka sub-materi tertentu.

- **URL**: `GET /api/v1/progress/materials/:subMateriId/access`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "ACCESS_CHECK_SUCCESS",
    "message": "Access check completed",
    "data": {
      "can_access": true,
      "reason": "Previous sub-materi completed",
      "sub_materi_id": "sub-materi-uuid"
    }
  }
  ```

### 23. Get Material Progress

Endpoint ini digunakan untuk mendapatkan progress pengguna pada material tertentu termasuk poin yang telah diselesaikan.

- **URL**: `GET /api/v1/progress/materials/:materialId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "MATERIAL_PROGRESS_SUCCESS",
    "message": "Material progress fetched successfully",
    "data": {
      "id": "progress-uuid",
      "user_id": "user-uuid",
      "material_id": "material-uuid",
      "completed_points": ["point-1-uuid", "point-2-uuid", "point-3-uuid"],
      "total_points": 5,
      "progress_percentage": 60.0,
      "is_completed": false,
      "started_at": "2024-01-05T08:00:00.000Z",
      "completed_at": null,
      "last_accessed": "2024-01-10T10:30:00.000Z"
    }
  }
  ```

### 24. Get Overall Progress

Endpoint ini digunakan untuk mendapatkan progress keseluruhan pengguna di semua modul pembelajaran.

- **URL**: `GET /api/v1/progress/overall`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "OVERALL_PROGRESS_SUCCESS",
    "message": "Overall progress fetched successfully",
    "data": {
      "user_id": "user-uuid",
      "module_progress": [
        {
          "id": "progress-1-uuid",
          "user_id": "user-uuid",
          "module_id": "module-1-uuid",
          "status": "completed",
          "progress_percent": 100.0,
          "last_accessed_at": "2024-01-08T10:00:00.000Z",
          "created_at": "2024-01-01T08:00:00.000Z",
          "updated_at": "2024-01-08T10:00:00.000Z",
          "completed": true,
          "completed_at": "2024-01-08T10:00:00.000Z"
        }
      ],
      "total_modules": 10,
      "completed_modules": 3,
      "overall_percentage": 30.0,
      "last_activity": "2024-01-10T10:30:00.000Z"
    }
  }
  ```

### 25. Mark Material Complete

Endpoint ini digunakan untuk menandai material sebagai selesai dipelajari oleh pengguna.

- **URL**: `POST /api/v1/progress/materials/:materialId/complete`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "material_id": "material-uuid",
    "completed_at": "2024-01-10T11:00:00.000Z"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "MATERIAL_COMPLETED",
    "message": "Material completed successfully",
    "data": {
      "success": true,
      "message": "Material marked as complete",
      "updated_progress": {
        "id": "progress-uuid",
        "user_id": "user-uuid",
        "module_id": "module-uuid",
        "status": "in-progress",
        "progress_percent": 85.0,
        "last_accessed_at": "2024-01-10T11:00:00.000Z",
        "updated_at": "2024-01-10T11:00:00.000Z"
      }
    }
  }
  ```

### 26. Mark Quiz Complete

Endpoint ini digunakan untuk menandai kuis sebagai selesai dengan menyimpan skor dan status kelulusan.

- **URL**: `POST /api/v1/progress/quiz/:quizId/complete`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "quiz_id": "quiz-uuid",
    "score": 85,
    "passed": true,
    "time_taken_seconds": 450
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_COMPLETED",
    "message": "Quiz completed successfully",
    "data": {
      "success": true,
      "message": "Quiz marked as complete",
      "updated_progress": {
        "id": "progress-uuid",
        "user_id": "user-uuid",
        "module_id": "module-uuid",
        "status": "in-progress",
        "progress_percent": 90.0,
        "last_accessed_at": "2024-01-10T11:30:00.000Z",
        "updated_at": "2024-01-10T11:30:00.000Z"
      }
    }
  }
  ```

### 27. Mark Point Complete

Endpoint ini digunakan untuk menandai poin pembelajaran tertentu sebagai selesai dipelajari.

- **URL**: `POST /api/v1/progress/points/:pointId/complete`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "point_id": "point-uuid",
    "completed_at": "2024-01-10T10:45:00.000Z"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "POINT_COMPLETED",
    "message": "Point completed successfully",
    "data": {
      "success": true,
      "message": "Point marked as complete",
      "updated_progress": {
        "id": "progress-uuid",
        "user_id": "user-uuid",
        "module_id": "module-uuid",
        "status": "in-progress",
        "progress_percent": 82.0,
        "last_accessed_at": "2024-01-10T10:45:00.000Z",
        "updated_at": "2024-01-10T10:45:00.000Z"
      }
    }
  }
  ```

### 28. Reset Module Progress

Endpoint ini digunakan untuk mereset progress pengguna pada modul tertentu ke kondisi awal.

- **URL**: `DELETE /api/v1/progress/modules/:moduleId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "PROGRESS_RESET_SUCCESS",
    "message": "Module progress reset successfully",
    "data": {
      "success": true,
      "message": "Progress has been reset"
    }
  }
  ```

### 29. Get Quiz Progress

Endpoint ini digunakan untuk mendapatkan progress kuis pengguna termasuk best score dan jumlah attempts.

- **URL**: `GET /api/v1/progress/quiz/:quizId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_PROGRESS_SUCCESS",
    "message": "Quiz progress fetched successfully",
    "data": {
      "id": "quiz-progress-uuid",
      "user_id": "user-uuid",
      "quiz_id": "quiz-uuid",
      "best_score": 85,
      "attempts_count": 3,
      "is_passed": true,
      "last_attempt_at": "2024-01-10T11:30:00.000Z",
      "first_attempt_at": "2024-01-08T09:00:00.000Z"
    }
  }
  ```

### 30. Update Last Accessed

Endpoint ini digunakan untuk memperbarui timestamp terakhir kali pengguna mengakses modul tertentu.

- **URL**: `PATCH /api/v1/progress/modules/:moduleId/accessed`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "last_accessed": "2024-01-10T12:00:00.000Z"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "LAST_ACCESSED_UPDATED",
    "message": "Last accessed time updated",
    "data": {
      "success": true,
      "message": "Last accessed updated"
    }
  }
  ```

### 31. Mark Poin Completed

Endpoint ini digunakan untuk menandai poin pembelajaran sebagai selesai dipelajari oleh pengguna.

- **URL**: `POST /api/v1/progress/poins/:poinId/complete`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {}
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "POIN_COMPLETED",
    "message": "Poin completed successfully",
    "data": {
      "success": true
    }
  }
  ```

---

## Quiz System

### 32. Get Quizzes by Module ID

Endpoint ini digunakan untuk mendapatkan semua kuis yang terkait dengan modul tertentu.

- **URL**: `GET /api/v1/kuis/module/:moduleId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_FETCH_SUCCESS",
    "message": "Successfully fetched 3 quizzes for module",
    "data": [
      {
        "id": "quiz-1-uuid",
        "module_id": "module-uuid",
        "sub_materi_id": "sub-materi-1-uuid",
        "quiz_type": "sub",
        "title": "Kuis Pengenalan Bayi",
        "description": "Kuis untuk menguji pemahaman",
        "time_limit_seconds": 600,
        "passing_score": 70,
        "published": true,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    ]
  }
  ```

### 33. Get Quiz by ID

Endpoint ini digunakan untuk mendapatkan detail kuis tertentu termasuk pertanyaan-pertanyaan yang ada.

- **URL**: `GET /api/v1/quizzes/:quizId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_FETCH_SUCCESS",
    "message": "Quiz fetched successfully",
    "data": {
      "id": "quiz-uuid",
      "module_id": "module-uuid",
      "sub_materi_id": "sub-materi-uuid",
      "quiz_type": "sub",
      "title": "Kuis Pengenalan Bayi",
      "description": "Kuis untuk menguji pemahaman",
      "time_limit_seconds": 600,
      "passing_score": 70,
      "published": true,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z",
      "questions": [
        {
          "id": "question-1-uuid",
          "quiz_id": "quiz-uuid",
          "question_text": "Apa yang dimaksud dengan bayi?",
          "options": [
            { "text": "Anak usia 0-12 bulan", "index": 0 },
            { "text": "Anak usia 1-5 tahun", "index": 1 },
            { "text": "Anak usia 5-10 tahun", "index": 2 },
            { "text": "Anak usia 10-15 tahun", "index": 3 }
          ],
          "correct_answer_index": 0,
          "explanation": "Bayi adalah anak dengan usia 0-12 bulan",
          "order_index": 1,
          "created_at": "2024-01-01T00:00:00.000Z"
        }
      ]
    }
  }
  ```

### 34. Get Quiz Questions

Endpoint ini digunakan untuk mendapatkan pertanyaan-pertanyaan dari kuis tertentu tanpa informasi jawaban yang benar.

- **URL**: `GET /api/v1/quizzes/:quizId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_QUESTIONS_SUCCESS",
    "message": "Quiz questions fetched successfully",
    "data": [
      {
        "id": "question-1-uuid",
        "quiz_id": "quiz-uuid",
        "question_text": "Apa yang dimaksud dengan bayi?",
        "options": [
          { "text": "Anak usia 0-12 bulan", "index": 0 },
          { "text": "Anak usia 1-5 tahun", "index": 1 },
          { "text": "Anak usia 5-10 tahun", "index": 2 },
          { "text": "Anak usia 10-15 tahun", "index": 3 }
        ],
        "order_index": 1,
        "created_at": "2024-01-01T00:00:00.000Z"
      }
    ]
  }
  ```

### 35. Start Quiz Attempt

Endpoint ini digunakan untuk memulai attempt baru pada kuis tertentu dan mendapatkan ID attempt.

- **URL**: `POST /api/v1/quizzes/start`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "quiz_id": "quiz-uuid"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_ATTEMPT_STARTED",
    "message": "Quiz attempt started successfully",
    "data": {
      "id": "attempt-uuid",
      "quiz_id": "quiz-uuid",
      "user_id": "user-uuid",
      "questions": [],
      "started_at": "2024-01-10T10:00:00.000Z",
      "completed_at": null,
      "score": null,
      "total_questions": 10,
      "correct_answers": null,
      "passed": null,
      "answers": null,
      "created_at": "2024-01-10T10:00:00.000Z"
    }
  }
  ```

### 36. Submit Quiz Answers

Endpoint ini digunakan untuk submit jawaban kuis dan mendapatkan hasil penilaian secara otomatis.

- **URL**: `POST /api/v1/quizzes/submit`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "quiz_id": "quiz-uuid",
    "answers": [
      {
        "question_id": "question-1-uuid",
        "selected_option_index": 0
      },
      {
        "question_id": "question-2-uuid",
        "selected_option_index": 2
      }
    ],
    "submitted_at": "2024-01-10T10:15:00.000Z"
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_SUBMITTED",
    "message": "Quiz submitted successfully",
    "data": {
      "id": "result-uuid",
      "quiz_id": "quiz-uuid",
      "user_id": "user-uuid",
      "score": 85,
      "total_questions": 10,
      "correct_answers": 8,
      "passed": true,
      "answers": {
        "question-1-uuid": { "selected": 0, "correct": true },
        "question-2-uuid": { "selected": 2, "correct": false }
      },
      "created_at": "2024-01-10T10:15:00.000Z",
      "started_at": "2024-01-10T10:00:00.000Z",
      "completed_at": "2024-01-10T10:15:00.000Z"
    }
  }
  ```

### 37. Get Quiz Results

Endpoint ini digunakan untuk mendapatkan hasil kuis pengguna tertentu atau semua hasil kuis pengguna.

- **URL**: `GET /api/v1/quizzes/:quizId/results` (untuk kuis tertentu)
- **URL**: `GET /api/v1/quizzes/attempts/my` (untuk semua hasil pengguna)
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZ_RESULTS_SUCCESS",
    "message": "Quiz results fetched successfully",
    "data": [
      {
        "id": "result-uuid",
        "quiz_id": "quiz-uuid",
        "user_id": "user-uuid",
        "score": 85,
        "total_questions": 10,
        "correct_answers": 8,
        "passed": true,
        "answers": {
          "question-1-uuid": { "selected": 0, "correct": true }
        },
        "created_at": "2024-01-10T10:15:00.000Z",
        "started_at": "2024-01-10T10:00:00.000Z",
        "completed_at": "2024-01-10T10:15:00.000Z"
      }
    ]
  }
  ```

### 38. Get All Published Quizzes

Endpoint ini digunakan untuk mendapatkan semua kuis yang sudah dipublikasikan untuk pengguna.

- **URL**: `GET /api/v1/quizzes`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "QUIZZES_FETCH_SUCCESS",
    "message": "Quizzes fetched successfully",
    "data": [
      {
        "id": "quiz-1-uuid",
        "module_id": "module-uuid",
        "sub_materi_id": "sub-materi-uuid",
        "quiz_type": "sub",
        "title": "Kuis Pengenalan Bayi",
        "description": "Kuis untuk menguji pemahaman",
        "time_limit_seconds": 600,
        "passing_score": 70,
        "published": true,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    ]
  }
  ```

### 39. Get My Quiz Attempts

Endpoint ini digunakan untuk mendapatkan riwayat attempts kuis pengguna dengan filtering dan pagination.

- **URL**: `GET /api/v1/quizzes/attempts/my?status=completed&page=1&limit=10`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "ATTEMPTS_FETCH_SUCCESS",
    "message": "Quiz attempts fetched successfully",
    "data": {
      "attempts": [
        {
          "id": "attempt-1-uuid",
          "quiz_id": "quiz-uuid",
          "user_id": "user-uuid",
          "questions": [],
          "started_at": "2024-01-10T10:00:00.000Z",
          "completed_at": "2024-01-10T10:15:00.000Z",
          "score": 85,
          "total_questions": 10,
          "correct_answers": 8,
          "passed": true,
          "answers": {},
          "created_at": "2024-01-10T10:00:00.000Z"
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 10,
        "total": 15,
        "totalPages": 2
      }
    }
  }
  ```

### 40. Get Quiz History by Module

Endpoint ini digunakan untuk mendapatkan riwayat kuis pengguna pada modul tertentu.

- **URL**: `GET /api/v1/quizzes/attempts/my?module_id={moduleId}`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "HISTORY_FETCH_SUCCESS",
    "message": "Quiz history fetched successfully",
    "data": {
      "attempts": [
        {
          "id": "attempt-1-uuid",
          "quiz_id": "quiz-uuid",
          "user_id": "user-uuid",
          "started_at": "2024-01-10T10:00:00.000Z",
          "completed_at": "2024-01-10T10:15:00.000Z",
          "score": 85,
          "total_questions": 10,
          "correct_answers": 8,
          "passed": true,
          "created_at": "2024-01-10T10:00:00.000Z"
        }
      ],
      "total": 5
    }
  }
  ```

---

## User Notes

### 41. Get User Notes

Endpoint ini digunakan untuk mendapatkan semua catatan pengguna dengan pagination, filtering berdasarkan kategori, dan pencarian.

- **URL**: `GET /api/v1/notes?page=1&limit=10&category=pembelajaran&search=bayi`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "NOTES_FETCH_SUCCESS",
    "message": "Notes fetched successfully",
    "data": {
      "items": [
        {
          "id": "note-uuid",
          "user_id": "user-uuid",
          "title": "Catatan Pembelajaran Bayi",
          "content": "Isi catatan tentang pembelajaran bayi...",
          "category": "pembelajaran",
          "is_pinned": false,
          "created_at": "2024-01-05T08:00:00.000Z",
          "updated_at": "2024-01-05T08:00:00.000Z"
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 10,
        "total": 25,
        "totalPages": 3
      }
    }
  }
  ```

### 42. Get Note by ID

Endpoint ini digunakan untuk mendapatkan detail catatan tertentu berdasarkan ID catatan.

- **URL**: `GET /api/v1/notes/:noteId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "NOTE_FETCH_SUCCESS",
    "message": "Note fetched successfully",
    "data": {
      "id": "note-uuid",
      "user_id": "user-uuid",
      "title": "Catatan Pembelajaran Bayi",
      "content": "Isi catatan tentang pembelajaran bayi...",
      "category": "pembelajaran",
      "is_pinned": false,
      "created_at": "2024-01-05T08:00:00.000Z",
      "updated_at": "2024-01-05T08:00:00.000Z"
    }
  }
  ```

### 43. Create Note

Endpoint ini digunakan untuk membuat catatan baru dengan judul, konten, kategori, dan status pin.

- **URL**: `POST /api/v1/notes`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "title": "Catatan Pembelajaran Bayi",
    "content": "Isi catatan tentang pembelajaran bayi...",
    "category": "pembelajaran",
    "is_pinned": false
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "NOTE_CREATED",
    "message": "Note created successfully",
    "data": {
      "id": "note-uuid",
      "user_id": "user-uuid",
      "title": "Catatan Pembelajaran Bayi",
      "content": "Isi catatan tentang pembelajaran bayi...",
      "category": "pembelajaran",
      "is_pinned": false,
      "created_at": "2024-01-05T08:00:00.000Z",
      "updated_at": "2024-01-05T08:00:00.000Z"
    }
  }
  ```

### 44. Update Note

Endpoint ini digunakan untuk memperbarui catatan yang sudah ada dengan data baru.

- **URL**: `PUT /api/v1/notes/:noteId`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {
    "title": "Catatan Pembelajaran Bayi Updated",
    "content": "Isi catatan yang diperbarui...",
    "category": "pembelajaran-lanjutan",
    "is_pinned": true
  }
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "NOTE_UPDATED",
    "message": "Note updated successfully",
    "data": {
      "id": "note-uuid",
      "user_id": "user-uuid",
      "title": "Catatan Pembelajaran Bayi Updated",
      "content": "Isi catatan yang diperbarui...",
      "category": "pembelajaran-lanjutan",
      "is_pinned": true,
      "created_at": "2024-01-05T08:00:00.000Z",
      "updated_at": "2024-01-06T09:00:00.000Z"
    }
  }
  ```

### 45. Delete Note

Endpoint ini digunakan untuk menghapus catatan tertentu secara permanen dari sistem.

- **URL**: `DELETE /api/v1/notes/:noteId`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "NOTE_DELETED",
    "message": "Note deleted successfully",
    "data": null
  }
  ```

### 46. Toggle Pin Note

Endpoint ini digunakan untuk toggle status pin catatan (dari pinned ke unpinned atau sebaliknya).

- **URL**: `PATCH /api/v1/notes/:noteId/pin`
- **Authentication**: Bearer token diperlukan
- **Request Body**:
  ```json
  {}
  ```
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "NOTE_PIN_TOGGLED",
    "message": "Note pin status toggled successfully",
    "data": {
      "id": "note-uuid",
      "user_id": "user-uuid",
      "title": "Catatan Pembelajaran Bayi",
      "content": "Isi catatan tentang pembelajaran bayi...",
      "category": "pembelajaran",
      "is_pinned": true,
      "created_at": "2024-01-05T08:00:00.000Z",
      "updated_at": "2024-01-07T10:00:00.000Z"
    }
  }
  ```

### 47. Get User Note Categories

Endpoint ini digunakan untuk mendapatkan daftar semua kategori catatan yang dimiliki pengguna.

- **URL**: `GET /api/v1/notes/categories`
- **Authentication**: Bearer token diperlukan
- **Response Body**:
  ```json
  {
    "error": false,
    "code": "CATEGORIES_FETCH_SUCCESS",
    "message": "Categories fetched successfully",
    "data": [
      "pembelajaran",
      "pembelajaran-lanjutan",
      "kesehatan",
      "nutrisi",
      "perkembangan"
    ]
  }
  ```

---

## Response Format

Semua endpoint menggunakan format response yang konsisten dengan struktur envelope sebagai berikut:

```json
{
  "error": false,
  "code": "SUCCESS_CODE",
  "message": "Descriptive success message",
  "data": {
    // Response data here
  }
}
```

Untuk kasus error, format response adalah:

```json
{
  "error": true,
  "code": "ERROR_CODE",
  "message": "Descriptive error message",
  "data": null
}
```

### Common Error Codes

- `UNAUTHORIZED`: Token tidak valid atau tidak ditemukan (status 401)
- `FORBIDDEN`: User tidak memiliki akses ke resource (status 403)
- `NOT_FOUND`: Resource tidak ditemukan (status 404)
- `VALIDATION_ERROR`: Data input tidak valid (status 400)
- `SERVER_ERROR`: Error internal server (status 500)

### Authentication

Untuk endpoint yang membutuhkan authentication, sertakan Bearer token di header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Token diperoleh dari endpoint `/api/v1/auth/login` atau `/api/v1/auth/register` dan harus disertakan dalam setiap request ke endpoint yang memerlukan autentikasi.

---

## Notes

1. Semua timestamp menggunakan format ISO 8601 (contoh: `2024-01-10T10:30:00.000Z`)
2. UUID digunakan untuk semua ID resource
3. Pagination menggunakan parameter `page` dan `limit` di query string
4. Filter dan search menggunakan query parameters
5. Base URL dapat dikonfigurasi melalui environment variable `NEXT_PUBLIC_BACKEND_URL`
6. Untuk endpoint public access, authentication header tidak diperlukan
7. Untuk endpoint yang requires auth, pastikan token masih valid dan belum expired
8. Refresh token dapat digunakan untuk mendapatkan access token baru tanpa login ulang

---

**Last Updated**: January 7, 2026
