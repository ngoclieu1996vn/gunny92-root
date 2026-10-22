# Kiểm tra game bằng Flash thật

Chạy từ PowerShell sau khi đã cài FlashBrowser:

```powershell
powershell -ExecutionPolicy Bypass -File tools/flash-probe/Start-FlashProbe.ps1
```

Công cụ dùng bản sao Electron của FlashBrowser cùng plugin Flash đã cài,
chạy ẩn trong 120 giây và dùng hồ sơ mới cho mỗi lần kiểm tra. Không chạy hai
lần cùng lúc với một tài khoản vì server sẽ ngắt phiên đăng nhập trước.

Xem `scratch/flash-probe/latest.png` để xác nhận sảnh đã xuất hiện;
`latest.jsonl` chứa các yêu cầu mạng, lỗi và thông tin plugin. Mức tải 100%
hoặc HTTP 200 không tự chứng minh đăng nhập thành công. Công cụ không tự kết
luận thành công từ phần trăm tải. Dữ liệu kiểm tra nằm trong scratch, ngoài Git.

Để tương tác, ghi mảng sự kiện Electron `sendInputEvent` vào
`scratch/flash-probe/commands.json`; công cụ đọc và xóa tệp sau khi gửi sự kiện.
