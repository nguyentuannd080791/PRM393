# Mini Social — PRM393

Mini Social là ứng dụng mạng xã hội cho đồ án nhóm: người dùng đăng nhập, chia sẻ bài viết và kết bạn. Flutter gọi REST API Node.js; backend lưu dữ liệu trong MongoDB Community Server trên laptop của nhóm.

README này giúp thành viên mới chạy dự án, tìm đúng phần code của mình và tích hợp với các thành viên khác.

## 1. Phân công và tình trạng hiện tại

| Phụ trách | Màn hình | Thư mục Flutter | Tình trạng |
| --- | --- | --- | --- |
| Chung | Login, Register, phiên đăng nhập | `features/auth/` | Có code authentication và API |
| Member 1 | Home Feed, Post Detail, Notifications | `features/feed/` | Có giao diện/điểm tích hợp; tính năng đầy đủ đang chờ thành viên phụ trách |
| Member 2 | Post Editor, My Posts, Post Insights | `features/posts/` | Có giao diện/khung tích hợp; chưa hoàn thành nghiệp vụ quản lý bài viết |
| Member 3 | Comments, Liked Posts, Saved Posts | `features/interactions/` | Khung tích hợp |
| Member 4 | Search, Friend Requests, Friend List | `features/friends/` | Đã nối Riverpod → API → MongoDB, có kiểm thử |
| Member 5 | Profile, Edit Profile, Account Settings | `features/profile/` | Có giao diện/điểm tích hợp; các chức năng hồ sơ đầy đủ đang chờ tích hợp |

**Có file màn hình không đồng nghĩa tính năng đã hoàn thành.** Những file ghi “awaiting integration”, các repository chỉ có interface và provider trả về `null` là khung để thành viên phụ trách phát triển.

Thanh điều hướng chính có bốn tab: **Home · Search · Friends · Profile**. Giao diện hiện được cố định nền trắng, chế độ sáng.

## 2. Chuẩn bị môi trường

- Git.
- Node.js và npm. Môi trường đã chạy dự án dùng Node.js 24.
- Flutter SDK có Dart đáp ứng `^3.13.2` theo `frontend/pubspec.yaml`.
- MongoDB Community Server đang chạy trên laptop. Cài riêng MongoDB Compass chưa đủ để có database server.
- Chrome để chạy web; Android SDK và thiết bị/emulator nếu chạy Android.

Các lệnh bên dưới dùng **Windows PowerShell**. Dùng `npm.cmd` để tránh lỗi PowerShell chặn `npm.ps1`.

Clone dự án nếu chưa có:

```powershell
git clone https://github.com/nguyentuannd080791/PRM393.git
cd PRM393
```

Làm việc trên nhánh nhóm đã thống nhất. Nếu phần Member 4 chưa được merge vào `main`, chuyển sang nhánh triển khai:

```powershell
git switch feat/member4-search-friends
```

## 3. Chạy lần đầu trên máy cá nhân

### Terminal 1 — Backend

Từ thư mục gốc `PRM393`:

```powershell
cd backend
npm.cmd install

if (!(Test-Path .env)) {
    Copy-Item .env.example .env
}

notepad .env
```

Các cấu hình chính trong `backend/.env`:

```dotenv
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb://127.0.0.1:27017/fb_clone
MONGODB_DB_NAME=fb_clone
JWT_SECRET=replace_with_your_local_development_secret
JWT_EXPIRES_IN=7d
```

Dùng giá trị JWT secret phù hợp môi trường phát triển. Không đưa file `.env` lên Git. Sau đó chạy:

```powershell
npm.cmd start
```

Backend sẵn sàng khi terminal in ra địa chỉ cổng 5000. Mở [health check](http://localhost:5000/api/health); kết quả phải có `"status":"ok"`.

Giữ terminal này mở. Khi sửa backend, có thể dùng `npm.cmd run dev` thay cho `npm.cmd start` để tự khởi động lại.

**Không chạy `npm.cmd run db:init` trên database đang có dữ liệu.** Script cũ xóa dữ liệu trong các collection. Khởi động server bình thường đã tạo các index cần cho Member 4 mà không reset database.

### Terminal 2 — Flutter

Mở terminal khác tại thư mục gốc `PRM393`:

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

Lần đầu có thể mất một lúc để biên dịch. Hai terminal backend và Flutter cần tiếp tục chạy trong lúc dùng app.

Nếu vừa đổi cấu trúc/import hoặc chuyển nhánh, nên dừng Flutter bằng `q` hoặc `Ctrl+C`, rồi chạy lại. Chỉnh UI thông thường có thể dùng `r` để hot reload hoặc `R` để hot restart.

## 4. Thêm dữ liệu demo và thử Member 4

Trong thư mục `backend`:

```powershell
npm.cmd run seed:member4
```

Script thêm dữ liệu vào MongoDB của máy đang chạy: **9 tài khoản, 8 bài viết và 6 quan hệ bạn bè**. Trong 8 bài viết có 6 bài công khai, 1 bài riêng tư và 1 bài đã xóa để kiểm tra kết quả tìm kiếm.

Script giữ nguyên dữ liệu hiện có; chạy lại không reset thao tác Accept/Decline/Cancel đã thử. Nếu tài khoản demo bị đổi mật khẩu hoặc trùng tài khoản bên ngoài bộ demo, script sẽ báo lỗi thay vì ghi đè.

| Tài khoản | Email | Số điện thoại |
| --- | --- | --- |
| A — Minh Nguyen | `member4.a@example.com` | `0904400001` |
| B — Minh Pham | `member4.b@example.com` | `0904400002` |

Mật khẩu chung: **`Demo1234!`**. Đăng nhập bằng nút **Log In** thông thường; nút Demo Login/Autofill cũ dùng tài khoản khác.

Tài khoản A ban đầu có:

- Hai bạn bè: Minh Le, Tien Nguyen.
- Hai lời mời nhận: Ha Pham, Nhi Tran.
- Hai lời mời gửi: Hoang Le, Quang Le.
- Chưa kết bạn với tài khoản B, để thử Add Friend.

Cách thử nhanh:

1. Đăng nhập A trong Chrome thường, B trong cửa sổ ẩn danh để tách phiên đăng nhập.
2. A mở **Search → People**, tìm `Minh Pham`, chọn **Add Friend**.
3. B mở **Friends → Requests → Received**, chọn **Accept** hoặc **Decline**.
4. Nếu Accept, cả A và B đều thấy nhau trong Friends. Kéo xuống để làm mới hoặc chờ tối đa khoảng 15 giây.
5. A mở **Requests → Sent** để thử **Cancel Request** với Hoang Le hoặc Quang Le.
6. Tìm `Flutter` ở **Search → Posts**. Bài riêng tư của người khác và bài đã xóa không xuất hiện.

Dữ liệu nằm trên MongoDB của laptop đang dùng; nó không tự xuất hiện trên máy thành viên khác khi clone Git.

## 5. Chạy Android và dùng chung backend qua Wi-Fi

Địa chỉ API được chọn tại [api_config.dart](frontend/lib/core/config/api_config.dart):

| Môi trường | Địa chỉ |
| --- | --- |
| Chrome/desktop trên laptop backend | `http://localhost:5000/api` |
| Android emulator tiêu chuẩn | `http://10.0.2.2:5000/api` |
| Điện thoại thật | IP Wi-Fi của laptop, truyền qua `API_BASE_URL` |

Với điện thoại thật:

1. Laptop và điện thoại kết nối cùng mạng Wi-Fi.
2. Chạy `ipconfig` trên laptop để lấy IPv4 của Wi-Fi.
3. Mở `http://<IP-laptop>:5000/api/health` trên trình duyệt điện thoại.
4. Nếu không truy cập được, kiểm tra firewall của laptop và tính năng cô lập thiết bị/guest Wi-Fi.
5. Chạy Flutter với IP thực tế. Ví dụ:

```powershell
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://192.168.1.20:5000/api
```

Thay `192.168.1.20` bằng IP laptop. Tham số phải có đuôi `/api`; chạy lại Flutter sau khi đổi `--dart-define`.

Backend đã lắng nghe trên `0.0.0.0`. Android manifest đã có quyền INTERNET và cho phép HTTP trong môi trường phát triển. Điện thoại chỉ truy cập API cổng 5000; **không mở MongoDB cổng 27017 cho điện thoại**.

Khi demo nhiều điện thoại, tất cả phải trỏ tới cùng một backend để nhìn thấy chung tài khoản, bài viết và quan hệ bạn bè.

## 6. Tìm code ở đâu?

```text
frontend/
├── assets/                         # icons/, images/
├── lib/
│   ├── main.dart                   # Khởi tạo Flutter, SharedPreferences, ProviderScope
│   ├── app/                        # App, router, theme, tên các route
│   ├── core/
│   │   ├── config/api_config.dart  # Chọn địa chỉ backend
│   │   ├── network/api_client.dart # HTTP, Bearer token, xử lý lỗi
│   │   ├── storage/                # Lưu phiên đăng nhập
│   │   ├── widgets/                # Bottom nav, avatar, loading
│   │   ├── models/                 # Model dùng chung
│   │   └── theme/                  # Màu, font, style dùng chung
│   └── features/
│       ├── auth/                   # Chung
│       ├── feed/                   # Member 1
│       ├── posts/                  # Member 2
│       ├── interactions/           # Member 3
│       ├── friends/                # Member 4
│       │   ├── screens/
│       │   ├── models/
│       │   ├── providers/
│       │   ├── repositories/
│       │   └── widgets/
│       └── profile/                # Member 5
└── test/member4/

backend/
├── src/
│   ├── server.js                   # Kết nối MongoDB, tạo index, chạy HTTP server
│   ├── app.js                      # Express, CORS, JSON, health check
│   ├── config/database.js          # Kết nối MongoDB dùng chung
│   ├── middleware/                 # JWT auth, lỗi, async handler
│   ├── routes/                     # Khai báo endpoint và mount route
│   ├── controllers/                # Nhận request, trả response
│   ├── services/                   # Xử lý nghiệp vụ
│   ├── repositories/               # Thư mục dành cho lớp truy cập dữ liệu khi nhóm tách tiếp
│   └── utils/
├── scripts/                        # Seed demo, script khởi tạo cũ
└── tests/

docs/
├── report/                         # Báo cáo FPT và hướng dẫn cũ để tham chiếu
├── uml/                            # UML; có schema PostgreSQL lịch sử
├── stitch-ui/                      # HTML/PNG thiết kế, không phải app thực thi
└── member4.md                      # Chi tiết API và phần Member 4
```

Code backend hiện dùng **MongoDB**, dù `package.json` còn dependency PostgreSQL từ phiên bản trước và `docs/uml/` có schema SQL lịch sử. Không cần cài PostgreSQL để chạy phiên bản này.

## 7. Quy ước tích hợp giữa các thành viên

- Viết code trong feature mình phụ trách; dùng lại model, avatar, API client và session chung khi phù hợp.
- Gọi API qua `ApiClient` để dùng chung Bearer token và xử lý lỗi. Không kết nối Flutter trực tiếp tới MongoDB.
- Backend dùng middleware `src/middleware/auth.js` cho API cần đăng nhập. Lấy người đang thao tác từ `req.user.id`, không tin ID người gửi do client tự khai báo.
- Dùng kết nối từ `config/database.js`. Hiện các service có thể gọi `getCollection` trực tiếp; thư mục `repositories/` dành cho việc tách lớp truy cập dữ liệu khi nhóm triển khai tiếp.
- Giữ thống nhất schema đang có: `User`, `Post`, `Friendship`, `Notification` cùng các field snake_case. Các tên collection viết thường trong báo cáo là mô hình dự kiến; không tự tạo bộ collection thứ hai.
- Thống nhất trước khi sửa authentication, router, theme, model chung hoặc schema. Không chép đè cả thư mục để tích hợp feature.
- Khi thêm màn hình, cập nhật `lib/app/app_router.dart` và `route_names.dart`. Khi thêm API, kiểm tra mount trong `backend/src/routes/index.js`.
- Auth hiện còn Splash/Forgot Password và các trường theo code gốc. Đối chiếu báo cáo cuối cùng trước khi thay đổi form dùng chung.
- Member 1 có thể nối Post Detail vào kết quả tìm bài viết bằng `postDetailPathBuilderProvider` trong `friends/repositories/search_repository.dart` sau khi có route hoạt động. Hiện màn hình Post Detail mới là khung tích hợp.

Member 4 có ba màn hình thật: Search chứa People/Posts, Friend Requests chứa Received/Sent, và Friend List. Không tạo thêm trang kết quả tìm kiếm hoặc tách hai tab lời mời thành hai màn hình.

## 8. Kiểm tra trước khi tạo Pull Request

Backend, từ thư mục gốc:

```powershell
cd backend
npm.cmd test
```

Flutter, trong terminal khác tại thư mục gốc:

```powershell
cd frontend
flutter analyze
flutter test test/member4
```

Lần kiểm tra phần Member 4 sau khi đổi cấu trúc: **12 test backend, 9 test Flutter đều pass; analyzer không có lỗi**. Test MongoDB dùng database riêng `prm393_member4_test_*` và không reset database demo. Chưa xác nhận bản build release hoặc kiểm thử nhiều điện thoại thật.

Luồng Git cho mỗi thành viên, bắt đầu từ working tree đã lưu/commit công việc trước đó:

```powershell
git switch main
git pull --ff-only origin main
git switch -c feat/memberN-feature-name
# Sửa code, chạy các kiểm tra liên quan.
# git add <các-file-của-bạn>
git commit -m "feat: describe your feature"
git push -u origin feat/memberN-feature-name
```

Sau đó tạo Pull Request vào `main`, ghi phần đã làm và kết quả kiểm thử để nhóm review. PR Member 4 hiện dùng nhánh `feat/member4-search-friends`. Không commit `.env`, `node_modules`, `build` hoặc cache SDK.

## 9. Lỗi thường gặp

| Hiện tượng | Cách xử lý |
| --- | --- |
| `EADDRINUSE ... 5000` | Cổng đang có server chạy. Kiểm tra health check; để nạp code mới, dừng backend cũ ở terminal của nó rồi chạy lại. |
| App báo không kết nối server | Kiểm tra backend, health check, API_BASE_URL; với điện thoại thật kiểm tra IP/Wi-Fi/firewall. |
| Lỗi import Flutter/package trong IDE | Chạy `flutter pub get` ở `frontend`; nếu IDE còn báo cũ, chạy **Dart: Restart Analysis Server**. |
| Flutter yêu cầu symlink support trên Windows | Bật Developer Mode của Windows rồi chạy lại `flutter pub get`. |
| Báo có package mới sau `flutter pub get` | Đây là thông tin phiên bản; dòng `Got dependencies!` nghĩa là tải dependency thành công. |
| Tìm kiếm không có dữ liệu | Kiểm tra đã đăng nhập và đang trỏ đúng backend; thêm demo bằng `seed:member4` nếu cần. |
| Thấy màn hình “awaiting integration” | Đây là phần chưa được thành viên phụ trách nối nghiệp vụ, không phải lỗi tải dữ liệu. |

Chi tiết endpoint, quy tắc quan hệ bạn bè và giới hạn triển khai: [docs/member4.md](docs/member4.md).
