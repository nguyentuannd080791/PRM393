# HƯỚNG DẪN THAO TÁC TOÀN DIỆN HỆ THỐNG FACEBOOK CLONE (`fb_clone` / `Connect`)

> **Dự án:** PRM393 - Mobile Social Networking Application  
> **Kiến trúc:** Flutter Mobile (Clean Architecture + Riverpod) & Node.js REST API (Express.js + MongoDB)  
> **Phiên bản:** Hoàn thiện kết nối Backend thực tế, 100% sạch Mock Data.

---

## MỤC LỤC

1. [Yêu cầu môi trường & Công cụ cài đặt](#1-yêu-cầu-môi-trường--công-cụ-cài-đặt)
2. [Cấu trúc thư mục dự án](#2-cấu-trúc-thư-mục-dự-án)
3. [Hướng dẫn cài đặt & Khởi chạy Backend (Node.js + PostgreSQL)](#3-hướng-dẫn-cài-đặt--khởi-chạy-backend-nodejs--postgresql)
4. [Hướng dẫn cài đặt & Khởi chạy Frontend (Flutter)](#4-hướng-dẫn-cài-đặt--khởi-chạy-frontend-flutter)
5. [Quy trình kiểm thử tự động (Automated Testing)](#5-quy-trình-kiểm-thử-tự-động-automated-testing)
6. [Kịch bản Demo & Báo cáo đồ án (Step-by-step User Journey)](#6-kịch-bản-demo--báo-cáo-đồ-án-step-by-step-user-journey)
7. [Các lỗi thường gặp và cách xử lý (Troubleshooting)](#7-các-lỗi-thường-gặp-và-cách-xử-lý-troubleshooting)

---

## 1. Yêu cầu môi trường & Công cụ cài đặt

Trước khi thao tác, đảm bảo máy tính của bạn đã cài đặt các công cụ sau:

- **Node.js**: Phiên bản `>= 18.x` (kèm `npm`).
- **MongoDB**: Phiên bản `>= 6.x / 7.x / 8.x` (đang chạy service trên cổng `27017` hoặc qua MongoDB Atlas).
- **Flutter SDK**: Phiên bản `>= 3.16.x` (kèm Dart SDK `>= 3.2.x`).
- **Google Chrome** hoặc **Android Studio** (Android Emulator) để chạy giao diện.

Kiểm tra nhanh trên terminal:

```bash
node -v
npm -v
mongosh --version
flutter --version
```

---

## 2. Cấu trúc thư mục dự án

```
clone_facebook/
├── Clone Facebook (fb_clone) - Project Specification.md # Đặc tả kỹ thuật gốc
├── README.md                                  # Giới thiệu kiến trúc tổng quan
├── INSTRUCTIONS.md                            # [Tệp này] Hướng dẫn thao tác toàn diện
│
├── backend/                                   # Node.js REST API Server
│   ├── .env.example                           # Mẫu cấu hình biến môi trường
│   ├── package.json                           # Scripts và dependencies
│   ├── init_db.js                             # Script khởi tạo cơ sở dữ liệu sạch
│   ├── src/
│   │   ├── server.js                          # Entrypoint máy chủ Express.js
│   │   ├── config/                            # Cấu hình db connection pool & schema.sql
│   │   ├── controllers/                       # Xử lý HTTP request/response
│   │   ├── middlewares/                       # JWT auth, validation, error handler
│   │   ├── routes/                            # Định tuyến API endpoints (auth, post, feed...)
│   │   ├── services/                          # Nghiệp vụ core (xử lý logic, dynamic counts)
│   │   └── utils/                             # Validation regex (BR-01..BR-22)
│   └── tests/                                 # 12 test suites tự động backend
│
└── frontend/                                  # Ứng dụng Flutter
    ├── pubspec.yaml                           # Thư viện phụ thuộc (riverpod, dio, go_router)
    ├── lib/
    │   ├── main.dart                          # Entrypoint ứng dụng Flutter
    │   ├── app/                               # Root MaterialApp & global DI
    │   ├── core/                              # Router, theme, constants, network (ApiClient)
    │   ├── data/repositories/                 # 7 Repository kết nối REST API thực tế
    │   └── features/                          # 7 module giao diện Clean Architecture
    │       ├── auth/                          # Đăng ký, Đăng nhập, Quên MK, Splash
    │       ├── feed/                          # Bảng tin, Reaction bar, Comment sheet
    │       ├── post/                          # Soạn thảo bài, Sửa, Xóa bài viết
    │       ├── profile/                       # Trang cá nhân, Sửa hồ sơ
    │       ├── friends/                       # Tìm kiếm bạn bè, Lời mời kết bạn
    │       ├── notifications/                 # Danh sách thông báo, Đánh dấu đã đọc
    │       └── menu/                          # Menu, Đổi Theme Light/Dark, Đăng xuất
    └── test/                                  # 452 bài unit/widget/e2e test tự động
```

---

## 3. Hướng dẫn cài đặt & Khởi chạy Backend (Node.js + MongoDB)

### Bước 3.1: Cấu hình biến môi trường

Vào thư mục `backend`, tạo file `.env` từ file `.env.example`:

**Windows PowerShell:**

```powershell
cd d:\Project\PRM393\clone_facebook\backend
Copy-Item .env.example .env
```

Mở file `backend/.env` và cập nhật thông số MongoDB của bạn:

```ini
PORT=5000
NODE_ENV=development

# Thông số kết nối MongoDB
MONGODB_URI=mongodb://127.0.0.1:27017/fb_clone
MONGODB_DB_NAME=fb_clone

JWT_SECRET=super_secret_jwt_key_for_fb_clone_2026
JWT_EXPIRES_IN=7d
```

### Bước 3.2: Cài đặt thư viện dependencies

```powershell
npm.cmd install
```

### Bước 3.3: Khởi tạo Cơ sở dữ liệu sạch (MongoDB Collections & Indexes sạch - 0 documents)

Chạy script tự động tạo 6 collections (`User`, `Post`, `Comment`, `Reaction`, `Friendship`, `Notification`) kèm các chỉ mục (indexes) tối ưu hóa truy vấn và tính toàn vẹn:

```powershell
npm.cmd run db:init
```

_Thông báo thành công: `[SUCCESS] Clean MongoDB database initialization complete. 6 collections verified with 0 documents.`_

### Bước 3.4: Khởi chạy máy chủ Backend

```powershell
# Chạy ở chế độ production:
npm.cmd start

# Hoặc chạy ở chế độ dev (tự reload khi sửa code):
npm.cmd run dev
```

_Server sẽ chạy tại `http://localhost:5000`._  
_Kiểm tra sức khỏe hệ thống qua trình duyệt: `http://localhost:5000/api/health` trả về `{"status":"ok"}`._

---

## 4. Hướng dẫn cài đặt & Khởi chạy Frontend (Flutter)

Mở một cửa sổ Terminal mới:

### Bước 4.1: Cài đặt gói thư viện Flutter

```powershell
cd d:\Project\PRM393\clone_facebook\frontend
flutter pub get
```

### Bước 4.2: Cơ chế tự động nhận diện địa chỉ Backend của Flutter

Tệp `frontend/lib/core/network/api_client.dart` đã tích hợp sẵn cơ chế nhận diện môi trường:

- **Chạy trên Chrome / Web / Windows App**: Tự động kết nối tới `http://localhost:5000/api`.
- **Chạy trên Android Emulator**: Tự động trỏ về `http://10.0.2.2:5000/api` (Địa chỉ IP loopback của máy chủ host từ máy ảo Android).

### Bước 4.3: Khởi chạy ứng dụng

**Cách 1: Khởi chạy trên trình duyệt Google Chrome (Nhanh và tiện nhất để demo):**

```powershell
flutter run -d chrome
```

**Cách 2: Khởi chạy trên Android Emulator (Thiết bị di động):**

1. Mở máy ảo Android từ Android Studio.
2. Chạy lệnh:

```powershell
flutter run
```

---

## 5. Quy trình kiểm thử tự động (Automated Testing)

Toàn bộ hệ thống được bảo vệ bởi bộ kiểm thử hồi quy nghiêm ngặt:

### 5.1. Kiểm thử Backend (100% PASS)

Chạy tại thư mục `backend`:

```powershell
cd d:\Project\PRM393\clone_facebook\backend

# Chạy toàn bộ 12 test suites của các domain API:
npm test

# Chạy bài kiểm thử chịu tải và liên thông E2E live:
node tests/m3_live_integration_challenge.js

# Chạy bài kiểm tra toàn vẹn ràng buộc Schema (Cascade, Foreign Keys):
node tests/challenger_schema_probe.js
```

### 5.2. Kiểm thử Frontend (100% PASS)

Chạy tại thư mục `frontend`:

```powershell
cd d:\Project\PRM393\clone_facebook\frontend

# 1. Phân tích tĩnh cú pháp & kiến trúc (Yêu cầu 0 warnings, 0 errors):
flutter analyze

# 2. Chạy toàn bộ 452 bài Unit & Widget test tự động:
flutter test
```

---

## 6. Kịch bản Demo & Báo cáo đồ án (Step-by-step User Journey)

Sau khi khởi động cả Backend và Frontend, bạn có thể thực hiện tuần tự kịch bản demo hoàn chỉnh cho giảng viên / hội đồng đánh giá:

### Bước 1: Luồng Đăng ký & Xác thực (Auth Flow)

1. Mở app $\rightarrow$ Giao diện `LoginPage` xuất hiện.
2. Bấm **"Create New Account"** để mở `RegisterPage`.
3. Điền thông tin:
   - Họ và tên: `Nguyễn Văn A`
   - Email: `vana@gmail.com`
   - Mật khẩu: `pass1234` (Đạt chuẩn BR-02: $\ge 8$ ký tự, có cả chữ và số).
   - Ngày sinh: Chọn ngày để tuổi $\ge 13$ (Chuẩn BR-03).
   - Giới tính: Nam.
4. Bấm **"Sign Up"** $\rightarrow$ Hệ thống lưu vào database PostgreSQL và tự động đăng nhập, chuyển vào màn hình Bảng tin.

### Bước 2: Luồng Đăng bài & Tương tác Bảng tin (Post & Feed Flow)

1. Tại tab Bảng tin (Home), chạm vào ô **"What's on your mind?"** để mở `CreatePostPage`.
2. Nhập nội dung bài viết (tối đa 5000 ký tự theo BR-09).
3. Đính kèm ảnh mẫu (URL) $\rightarrow$ Hệ thống có validate định dạng URL hợp lệ.
4. Chọn quyền riêng tư: **Public** hoặc **Friends**.
5. Bấm **"Post"** $\rightarrow$ Bài viết mới xuất hiện ngay đầu Bảng tin với avatar và thời gian thực.
6. Thử bấm nút Back phần cứng của Android $\rightarrow$ Ứng dụng kích hoạt `PopScope` hiển thị hộp thoại xác nhận hủy nháp nếu có nội dung chưa đăng.

### Bước 3: Luồng Cảm xúc & Bình luận (Reactions & Comments)

1. Trên thẻ bài viết (`PostCard`):
   - Chạm nhanh vào nút **Like** $\rightarrow$ Thả cảm xúc Like.
   - Nhấn giữ nút Like $\rightarrow$ Menu 6 cảm xúc (`Like`, `Love`, `Haha`, `Wow`, `Sad`, `Angry`) xuất hiện.
2. Chạm vào biểu tượng **Bình luận** $\rightarrow$ Mở `CommentsBottomSheet`.
3. Nhập bình luận (1 - 1000 ký tự theo BR-13) và bấm Gửi $\rightarrow$ Bình luận mới hiển thị tức thì, số lượng bình luận được tính toán động (BR-08) cập nhật theo thời gian thực.

### Bước 4: Luồng Tìm kiếm & Quản lý Bạn bè (Friends Flow)

1. Chuyển sang tab **Bạn bè** (Friends).
2. Chạm vào ô tìm kiếm hoặc icon Kính lúp $\rightarrow$ Mở `PeopleSearchPage`.
3. Gõ từ 2 ký tự (BR-17) $\rightarrow$ Hệ thống tự động tìm kiếm (debounce 300ms) và trả về kết quả.
4. Bấm **"Add Friend"** $\rightarrow$ Nút hiển thị loading ngắn, xuất hiện SnackBar _"Friend request sent."_ (MSG-13), và nút chuyển thành **"Cancel Request"**.

### Bước 5: Luồng Thông báo (Notifications Flow)

1. Chuyển sang tab **Thông báo** (Notifications).
2. Danh sách thông báo chia nhóm rõ ràng: **Mới (New)** và **Trước đó (Earlier)**.
3. Chạm vào nút **"Mark all as read"** $\rightarrow$ Toàn bộ thông báo được chuyển sang trạng thái đã đọc, chấm xanh biến mất.
4. Chạm vào một thông báo $\rightarrow$ Ứng dụng tự động chuyển hướng sâu (deep-link) tới bài viết hoặc trang cá nhân liên quan (BR-20).

### Bước 6: Luồng Trang cá nhân (Profile Flow)

1. Tại tab Bảng tin hoặc Menu, chạm vào ảnh đại diện cá nhân để mở `ProfilePage`.
2. Xem ảnh bìa, avatar, tiểu sử ngắn và danh sách bài viết riêng của người dùng.
3. Bấm **"Edit Profile"** $\rightarrow$ Mở `EditProfilePage`.
4. Cập nhật tiểu sử (tối đa 150 ký tự theo BR-14) và bấm Lưu $\rightarrow$ Thông tin cập nhật ngay lập tức.

### Bước 7: Cài đặt Theme & Đăng xuất (Menu & Logout)

1. Chuyển sang tab **Menu**.
2. Thử gạt công tắc **"Dark Mode"** $\rightarrow$ Toàn bộ ứng dụng chuyển sang giao diện Light Mode ngay lập tức; gạt lại để về Dark Mode (lưu cấu hình vào máy).
3. Cuộn xuống bấm **"Log Out"** $\rightarrow$ Hộp thoại xác nhận đăng xuất `MSG-01` xuất hiện.
4. Bấm xác nhận $\rightarrow$ Token JWT bị xóa sạch, ứng dụng quay trở lại màn hình `LoginPage`.

---

## 7. Các lỗi thường gặp và cách xử lý (Troubleshooting)

### Lỗi 1: `Connection refused` hoặc `SocketException` trên Flutter

- **Nguyên nhân**: Backend Server chưa được bật, hoặc port 5000 bị chặn.
- **Khắc phục**:
  1. Kiểm tra terminal Backend xem đã chạy `npm start` chưa.
  2. Mở trình duyệt gõ `http://localhost:5000/api/health` xem có trả về `{"status":"ok"}` không.
  3. Nếu chạy trên máy ảo Android, đảm bảo `api_client.dart` sử dụng IP `10.0.2.2`.

### Lỗi 2: `password authentication failed for user "postgres"`

- **Nguyên nhân**: Mật khẩu PostgreSQL trong file `backend/.env` không khớp với mật khẩu cài đặt trên máy bạn.
- **Khắc phục**: Mở file `backend/.env`, chỉnh sửa lại trường `DB_PASSWORD` và `DB_USER` cho đúng với cấu hình pgAdmin/PostgreSQL của bạn, sau đó chạy lại `npm run db:init`.

### Lỗi 3: `database "fb_clone_db" does not exist`

- **Nguyên nhân**: Chưa tạo cơ sở dữ liệu `fb_clone_db` trong PostgreSQL.
- **Khắc phục**: Mở `psql` hoặc pgAdmin và chạy câu lệnh SQL:
  ```sql
  CREATE DATABASE fb_clone_db;
  ```
  Sau đó chạy lại `npm run db:init`.

### Lỗi 4: Flutter không tải được ảnh trên Chrome (`Image codec error`)

- **Nguyên nhân**: Cơ chế bảo vệ CORS của trình duyệt đối với một số link ảnh ngoài.
- **Khắc phục**: Ứng dụng đã có cơ chế fallback hiển thị avatar chữ cái đầu của tên hoặc icon mặc định khi không tải được ảnh ngoài, không ảnh hưởng đến luồng nghiệp vụ. Khi chạy test hoặc demo trên Chrome có thể dùng cờ `--web-renderer html`.
