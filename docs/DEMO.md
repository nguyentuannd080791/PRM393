# Hướng dẫn demo trên Chrome

## 1. Chuẩn bị (làm trước buổi demo, ~5 phút)

1. **MongoDB** đang chạy trên máy (Services → MongoDB Server → Running).
2. **Backend** — thư mục `backend`:
   ```powershell
   npm.cmd install            # lần đầu
   npm.cmd start
   ```
   Phải thấy `Connected to database ...` và `listening on http://0.0.0.0:5000`.
   Nếu báo lỗi `JWT_SECRET is missing`, mở `backend/.env` và đặt `JWT_SECRET` dài ≥ 32 ký tự
   (tạo nhanh: `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"`).
3. **App** — thư mục `frontend`:
   ```powershell
   flutter run -d chrome
   ```
   Cửa sổ Chrome hiện màn hình đăng nhập. App tự căn giữa thành khung điện thoại 480px.
4. **Hai tài khoản** để demo tương tác. Mỗi tài khoản cần **một cửa sổ riêng**
   (cùng trình duyệt thì dùng chung phiên đăng nhập):
   - Cửa sổ thường: tài khoản **An**.
   - Cửa sổ **ẩn danh** (Ctrl+Shift+N) mở cùng địa chỉ app: tài khoản **Bình**.
   Đăng ký cả hai trước bằng số điện thoại (ví dụ `0911111111`, `0922222222`) và mật khẩu có chữ + số, ≥ 8 ký tự.
5. Cho **Bình** đăng 1 bài trước để Home Feed của An không trống.

> Không có dữ liệu mẫu hay nút "Demo login": mọi thứ trên màn hình là dữ liệu thật trong MongoDB.

## 2. Kịch bản demo gợi ý (≈ 8 phút)

| Bước | Màn hình | Thao tác | Điểm nhấn |
| --- | --- | --- | --- |
| 1 | SCR17 Register | Để trống SĐT → bấm Sign Up | Báo lỗi bắt buộc; SĐT là duy nhất |
| 2 | SCR16 Login | Đăng nhập An bằng SĐT | Reload trang (F5) vẫn giữ đăng nhập |
| 3 | SCR01 Home | Xem bài của Bình, Like, Save | Số Like cập nhật ngay |
| 4 | SCR02 Post Detail | Mở bài, bấm "N Likes" | Danh sách người đã Like |
| 5 | SCR07 Comments | Gửi bình luận rỗng → báo lỗi; gửi bình luận thật; xóa bình luận của mình | Chỉ xóa được bình luận của chính mình |
| 6 | SCR04 Post Editor | Tạo bài mới (chọn Public/Friends/Only me) | Bài hiện ngay ở Home |
| 7 | SCR05 My Posts | Sửa bài (cùng màn hình editor), xem Insights (SCR06), xóa bài | Xóa có hộp xác nhận |
| 8 | SCR10 Search | Tìm tên "Bình" → Add Friend | Nút đổi thành Request Sent |
| 9 | Cửa sổ ẩn danh (Bình) | SCR03 Notifications thấy lời mời; SCR11 Friend Requests → Accept | Thông báo giữa hai người dùng |
| 10 | SCR12 Friend List | An mở Friends | Thấy Bình; thấy thông báo "đã chấp nhận" |
| 11 | SCR08 / SCR09 | Profile → Liked Posts / Saved Posts, bỏ Save | Bài biến khỏi danh sách |
| 12 | SCR13 / SCR14 | Profile → Edit Profile, đổi tên + bio | Tên cập nhật trên Profile |
| 13 | SCR15 Settings | Đổi mật khẩu (sai mật khẩu cũ → lỗi), Log Out, đăng nhập lại bằng mật khẩu mới | Mật khẩu cũ bị từ chối |

## 3. Nếu có sự cố

| Triệu chứng | Cách xử lý |
| --- | --- |
| "Could not connect to the server" | Backend chưa chạy hoặc sai cổng — chạy lại `npm.cmd start`, kiểm tra http://localhost:5000/api/health |
| Báo `Too many attempts` khi đăng nhập | Khóa 5 phút sau 5 lần sai; restart backend để xóa khóa |
| Cả hai cửa sổ bị đăng nhập cùng tài khoản | Dùng cửa sổ ẩn danh cho tài khoản thứ hai |
| Giao diện cũ sau khi sửa code | Dừng `flutter run` (`q`) rồi chạy lại |

Lỗi `Null check operator` trong Console của Chrome khi đóng màn hình soạn bài chỉ xuất hiện khi bật
chế độ Accessibility (trình đọc màn hình/automation); là lỗi nội bộ Flutter Web, không ảnh hưởng người dùng thường.

## 4. Kiểm thử tự động

```powershell
cd backend ; npm.cmd test                  # 19 test API (MongoDB thật, database riêng)
cd frontend; flutter analyze; flutter test # 18 test widget
```

Test chạy toàn bộ app thật trên thiết bị/giả lập Android (cần backend có sẵn 2 tài khoản `0900000002`, `0900000003`, mỗi người 1 bài):
`flutter test integration_test/app_flow_test.dart -d <id thiết bị>`. iOS cần macOS + Xcode nên chưa chạy được trên Windows.
