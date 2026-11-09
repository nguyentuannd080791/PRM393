# Mini Social — PRM393

Flutter + Riverpod, Node.js REST API và MongoDB Community Server trên laptop. Nhánh hiện tại: `feat/member4-search-friends`.

## Cấu trúc

```text
frontend/
  android/
  assets/icons/
  assets/images/
  lib/
    main.dart
    app/                    # app.dart, app_router.dart, app_theme.dart và route helpers
    core/
      config/api_config.dart
      network/api_client.dart
      storage/session_storage.dart
      widgets/              # app_bottom_nav.dart, user_avatar.dart, loading_view.dart
      models/               # Các model dùng chung đã có
      theme/                # Màu, typography và các thành phần theme dùng chung
    features/
      auth/                 # Chung: login, register, session, repository
      feed/                 # Member 1: Home Feed, Post Detail, Notifications
      posts/                # Member 2: Post Editor, My Posts, Post Insights
      interactions/         # Member 3: Comments, Liked Posts, Saved Posts
      friends/              # Member 4
        screens/            # search_screen, friend_requests_screen, friend_list_screen
        models/             # user_result, friend_request
        providers/          # search_provider, friends_provider
        repositories/       # search_repository, friends_repository
        widgets/            # user_result_card, friend_request_card, friends_ui
      profile/              # Member 5: Profile, Edit Profile, Account Settings
  test/member4/
  pubspec.yaml
backend/
  src/
    server.js
    app.js
    config/database.js
    middleware/             # auth.js, error.js, async_handler.js
    routes/                 # auth, posts, interactions, search, friends, profile
    controllers/
    services/
    repositories/           # Điểm tích hợp lớp truy cập dữ liệu cho nhóm
    utils/
  scripts/                  # Khởi tạo database và seed demo
  tests/
  package.json
  .env.example
docs/
  report/                   # Báo cáo FPT gốc, không chỉnh sửa nội dung
  uml/                      # Điểm đặt UML và schema PostgreSQL lịch sử
  stitch-ui/                # HTML/PNG tham chiếu từ Stitch
  member4.md
```

Các thư mục hỗ trợ như `core/models`, `core/theme`, `core/utils` được giữ lại để tái sử dụng code hiện có. Splash và Forgot Password cũng được giữ trong `features/auth`. Thư mục checkout trên máy vẫn là `PRM393`; cấu trúc bên trong theo Mini Social.

## Trạng thái triển khai

- Authentication và Member 4 đang có code thực: API tìm kiếm người/bài viết, gửi/nhận/accept/decline/cancel, danh sách bạn bè hai chiều, Riverpod và ba màn hình.
- Các màn hình hiện có của thành viên khác được giữ nguyên chức năng khi chuyển vị trí.
- Những file Member 1/2/3/5 chưa tồn tại trước đây là scaffold tích hợp có ghi rõ trạng thái, chưa phải tính năng hoàn chỉnh. Các repository tương ứng là interface; provider để `null` chờ thành viên phụ trách cung cấp implementation. Các route backend scaffold không công bố API giả.
- Database giữ nguyên các collection hiện có: `User`, `Post`, `Friendship`, `Notification` và những collection khác của nhóm. Sắp xếp thư mục không đổi hoặc xóa dữ liệu.
- Toàn ứng dụng dùng giao diện sáng cố định, nền trắng.

## Chạy backend

```powershell
cd backend
npm.cmd install
# Chỉ sao chép nếu chưa có .env:
Copy-Item .env.example .env
npm.cmd start
```

MongoDB Community Server phải đang chạy. Cấu hình trong `.env`: `MONGODB_URI`, `MONGODB_DB_NAME`, `PORT`, `JWT_SECRET`. Kiểm tra `http://localhost:5000/api/health`. Nếu cổng 5000 có server cũ, dừng server đó bằng `Ctrl+C` trước khi chạy lại sau thay đổi code.

Không chạy `db:init` lên dữ liệu nhóm đã có vì script cũ xóa dữ liệu. Có thể thêm dữ liệu demo mà không xóa dữ liệu hiện tại bằng:

```powershell
npm.cmd run seed:member4
```

Tài khoản A: `member4.a@example.com`; tài khoản B: `member4.b@example.com`. Mật khẩu demo: `Demo1234!`. Dùng nút Log In thông thường.

## Chạy Flutter

Terminal khác, từ thư mục gốc:

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

Địa chỉ API được cấu hình tại `core/config/api_config.dart`. Android emulator mặc định dùng `10.0.2.2`. Điện thoại thật dùng IP Wi-Fi của laptop:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://192.168.1.20:5000/api
```

Thay IP theo máy thực tế. Điện thoại và laptop cùng mạng, Node.js được phép nhận kết nối cổng 5000. Manifest Android đã có INTERNET và hỗ trợ HTTP phát triển. Flutter chỉ gọi REST API, không kết nối trực tiếp MongoDB.

## Kiểm tra

```powershell
cd backend
npm.cmd test
# Terminal khác, từ thư mục gốc:
cd frontend
flutter analyze
flutter test test/member4
```

Xem [hướng dẫn Member 4](docs/member4.md) cho API và các luồng kiểm thử. Các test backend sử dụng database riêng `prm393_member4_test_*`, không reset database demo.
