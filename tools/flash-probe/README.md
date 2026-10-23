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

Dùng `-ShowWindow` để mở cửa sổ tương tác, `-DurationSeconds 1200` để kiểm tra lâu
hơn và `-CaptureIntervalMs 1000` để chụp mỗi giây. Chọn một tài khoản kiểm tra
riêng qua `-Url`; tránh đăng nhập trùng tài khoản đang được sử dụng.

Mảng lệnh cũng hỗ trợ `{ "type": "focus" }` và
`{ "type": "navigate", "url": "http://127.0.0.1:8888/play2.aspx?user=ai_room_probe" }`.
Điều hướng chỉ chấp nhận localhost hoặc 127.0.0.1. `focus` đưa cửa sổ kiểm tra
ra trước và đặt tiêu điểm trước khi gửi thao tác chuột.

Tùy chọn `-DiagnosticClient` chuyển riêng yêu cầu `/flash/2.png` của cửa sổ
kiểm tra sang `/flash/2.diagnostic.png`. Cần tự tạo bản SWF chẩn đoán tại đó
trước khi dùng; tùy chọn này không đổi client của người chơi khác.

Để thu bảng vật phẩm từ trang mà bạn tự đăng nhập:

```powershell
powershell -ExecutionPolicy Bypass -File tools/flash-probe/Start-FlashProbe.ps1 -Url 'https://www.gnddt.com/' -OutputName item-metadata-probe -CaptureMetadata -ShowWindow -DurationSeconds 3600
```

Chế độ này lưu riêng các phản hồi thành công của `TemplateAllList*.xml/ashx`,
`ShopItemList`/`ShopItemAllList` và `config.xml` vào
`scratch/item-metadata-probe/metadata`. `captures.jsonl` ánh xạ địa chỉ đã che
giá trị query với file dữ liệu; tên file chứa hash cả địa chỉ và nội dung để
không ghi đè các phiên bản khác nhau. Dữ liệu nén được giữ nguyên byte.
Không ghi ảnh màn hình, console của trang hoặc nội dung phản hồi đăng nhập.
Các cửa sổ game mới giữ cơ chế mở mặc định của Electron và cũng được gắn bộ
thu dữ liệu. Hồ sơ đăng nhập nằm trong scratch, không đưa lên Git.

Chỉ lấy được bảng mà trang thực sự tải qua HTTP(S); không suy ra TemplateID
hay chỉ số trang bị từ tên ảnh. Thông báo đăng nhập máy chủ thất bại chưa đủ
để kết luận website chặn trình duyệt. Kiểm tra `metadata-ready`, trạng thái
trang và lỗi thực tế trước khi kết luận. Kiểm thử công cụ:
`node tools/flash-probe/test-metadata-capture.cjs`.
