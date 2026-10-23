# Bàn giao cho AI tiếp tục dự án Gunny 9.2

Cập nhật: 2026-10-23, sau khi sửa lỗi không thấy đạn và không mở được Túi.

## Đọc trước khi thao tác

- Đọc `README.md`, file này và `Gunny92/gameSrc/tools/COMPATIBILITY.md`.
- Đây là nhiều Git repository độc lập. Kiểm tra `git status` trong từng repo trước khi sửa, pull hoặc commit. Không ghi đè cấu hình và thay đổi có sẵn của người dùng.
- Người dùng muốn sửa backend cho Flash/asset mới, kiểm tra bằng **FlashBrowser thực sự**, chạy lại server và đẩy bản sửa lên Git. Trình duyệt không có Flash không chứng minh được game chạy.
- Người dùng đã yêu cầu bỏ mã xác thực **trong game**; đã thực hiện. Không tự bật lại. Đăng nhập tài khoản và RSA vẫn giữ nguyên.
- Không cần hỏi lại những bước triển khai thông thường đã được cho phép. Tuy nhiên phải kiểm tra trạng thái hiện tại trước khi làm; máy có thể đã sleep hoặc được khởi động lại.

## Thư mục và các repo

- Workspace: `C:\Users\ngocl\OneDrive\Máy tính\gunny92-root`.
- Junction `C:\Gunny92` trỏ tới thư mục `Gunny92` trong workspace.
- Root: repo `ngoclieu1996vn/gunny92-root`.
- `C:\Gunny92\gameSrc`: repo `gunny92-gamesrc`, mã nguồn và công cụ build.
- `C:\Gunny92\Server`: repo `gunny92-server`, DLL đang chạy.
- `C:\Gunny92\Request`: repo `gunny92-request`, dữ liệu HTTP/XML.
- `C:\Gunny92\Flash`: repo `gunny92-flash`, client Flash và cấu hình.
- Asset gốc mới trên máy: `C:\Program Files (x86)\GunnyClient`. Có thể đối chiếu và lấy bổ sung nếu xác minh thiếu asset.
- Các repo trên đang dùng nhánh `master` ở thời điểm bàn giao; kiểm tra lại trước khi push.

## Kết quả đã kiểm tra trực tiếp

- Đăng nhập, vào sảnh có nhân vật và vào phòng đấu bot được.
- Bot và nhân vật tải xong, vào được map, di chuyển được.
- Sau bản sửa cuối, **đã thấy đạn bay**, trận tiếp tục chuyển lượt; log không ghi lỗi đọc gói bắn.
- **Đã mở được Túi**, thấy nhân vật và các ô trang bị.
- Road và Fight đã chạy lại với bản sửa. Cổng 8888, 9200, 9308 đều kết nối được khi bàn giao.
- Không suy diễn rằng mọi chức năng của game đã hoàn thiện. Những luồng chưa có bằng chứng kiểm tra cần tái hiện riêng khi người dùng báo lỗi.

## Commit đã đẩy lên Git

### gameSrc

- `b7ade37`: chọn bot, hủy tìm trận an toàn, tương thích kho đồ/gói tạo và bắt đầu trận, bỏ CAPTCHA trong game.
- `4e6ea55`: sửa gói đổi lượt PvP, tránh client đọc nhầm gió thành số lượng hiệu ứng khổng lồ rồi treo.
- **`74bdacb`**: sửa gói bắn và truy vấn hình thái thú cưng đang chặn mở Túi.

### Server

- `15912ea`: triển khai sửa gói đổi lượt.
- **`215321f`**: triển khai DLL tương thích gói đạn và mở Túi.

### Request và root trước đó

- Request `8043d27`: dữ liệu tips, preload đạn 11517, BuffTemplateInfo và kiểm thử dữ liệu.
- Root `62a2b6a`: công cụ Flash probe để thao tác, chụp màn hình và ghi log.

## Nguyên nhân và nơi sửa

Client mới đọc nhiều trường hơn backend cũ. Phải đối chiếu writer backend và reader ActionScript thực tế; không thêm số 0 theo phỏng đoán.

- `Game.Server/Game.Base.Packets/BattleResponseV92.cs`: chuyển đổi gói 91/101 tạo trận, 91/99 bắt đầu, 91/6 đổi lượt, 91/2 bắn.
- `MatchmakingV92.UpgradeRoomResponse`: gói bắt đầu/đổi lượt/bắn chỉ đổi cho phòng PvP Match/Elite được xác định trên Road. Kết nối AI vẫn nhận định dạng cũ.
- Gói bắn bổ sung wind extension/rate, projectile parent ID **-1**, action context; action 27 chỉ gửi hai tham số theo reader hiện tại. Giữ nguyên quỹ đạo, mẫu đạn, sát thương và pet actions.
- `InventoryResponseV92.cs`: tương thích gói kho đồ 64, giữ trang bị thật và dữ liệu slot.
- `PetFormsV92.cs`: client chờ trả lời **68/24** trước khi mở Túi. Backend cũ không xử lý. Trả số hình thái vĩnh viễn và có hạn đều bằng 0 vì backend chưa có hệ thống này; không cấp vật phẩm/pet và không sửa tiền.
- Hook pet chạy trước `PetLogicProcessor.OnGameData` đọc command. Có kiểm thử gọi trực tiếp dispatcher trong DLL đã patch.
- `CaptchaV92.cs`: đóng hộp CAPTCHA cũ an toàn, không thưởng tiền hoặc kick khi nhận câu trả lời cũ.
- `tools/PatchMatchmaking.cs` và `tools/PatchLoginProtocol.cs`: patch DLL gốc bằng Mono.Cecil. Khi sửa logic phải cập nhật cả source mirror, helper và patcher nếu liên quan.

Các lỗi dữ liệu Request đã sửa: TS_LoadTips rỗng, thiếu preload 11517 và 404 BuffTemplateInfo. XML client dùng **zlib**, không chỉ XML thuần. Dữ liệu chuẩn nằm trong `Request/scripts/client-data`; không tạo đạn vật lý mới chỉ để thỏa preload đồ họa.

## Build và kiểm thử

Project decompile đầy đủ không rebuild sạch. Dùng pipeline compatibility hiện có, compiler .NET Framework 4.8/C#5, DLL gốc và Mono.Cecil:

```powershell
# Chạy từ workspace root; kiểm tra các đường dẫn này còn tồn tại.
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Gunny92\gameSrc\tools\Build-Compatibility.ps1 -GameRoot C:\Gunny92 -CecilDll .\scratch\mono-cecil\lib\net40\Mono.Cecil.dll -ServerAssembly .\scratch\backend-compat-backup\Game.Server.dll
```

- Output: `C:\Gunny92\bin\compatibility`.
- Không dùng DLL Road đã patch làm input gốc. Pipeline từ chối input patch lặp.
- Fight gốc được trích từ Costura trong `Fighting.Service.exe`.
- Build chạy kiểm thử login, sảnh/phòng, kho đồ, tạo/bắt đầu/đổi lượt/bắn, matchmaking/hủy, pet forms, hook pet trong DLL đã patch và bỏ CAPTCHA. Tất cả đã PASS ở bản cuối.
- Dữ liệu Request: chạy `node scripts/test-startup-contracts.cjs` và `node scripts/prepare-compressed-xml.cjs --check` từ repo Request khi thay dữ liệu liên quan.

## Triển khai an toàn

- Road: `Server/road/Game.Server.dll` và `Game.Matchmaking.V92.dll`.
- Fight: `Server/fight/Fighting.Server.dll` và `Fight.Matchmaking.V92.dll`.
- Dừng bằng lệnh console `exit`, chờ thoát, sao lưu, thay DLL cùng build; bật Fight và chờ 9308 trước khi bật Road, rồi chờ 9200.
- Máy này có `bin/RequestServiceExit.exe` để gửi exit cho đúng service của dự án và `bin/ReadRoadConsole.exe PID output.txt` để đọc console. Luôn lấy PID hiện tại.
- Script local `tools/Apply-MatchmakingFix.ps1` có hash của bốn artifact: phải cập nhật hash từ build mới trước khi dùng, không tái chạy mù quáng.
- Backup triển khai cuối: `scratch/matchmaking-deploy-backup-20261023-141254`.
- Kiểm tra hash bốn DLL đang chạy khớp output sau triển khai. Chỉ stage file của bản sửa; không commit cấu hình, log, bí mật hay toàn bộ thư mục bằng `git add .`.

## Kiểm tra Flash thực sự

- FlashBrowser cài tại `C:\Program Files (x86)\FlashBrowser`, có PPAPI Flash.
- Dùng **tài khoản kiểm tra riêng** `ai_room_probe`, nhân vật `AIProbe`, ID **228**. Nhân vật đã có vũ khí **7008**, Bag0/Place6. Không cần cấp lại vũ khí chỉ vì chưa thấy đạn.
- URL local: `http://127.0.0.1:8888/play2.aspx?user=ai_room_probe`.
- `tools/flash-probe/Start-FlashProbe.ps1` hỗ trợ `-ShowWindow`, chụp hình và log vào `scratch/flash-probe`. Khởi động hiển thị ngay; probe khởi động ẩn từng gặp màn hình đen khi hiện lại.
- `-DiagnosticClient` cần file local `Flash/2.diagnostic.png`; chỉ chuyển client của probe sang bản có log, không sửa client của mọi người.
- Screenshot `latest.png` có thể cũ trong lúc tải: luôn đối chiếu timestamp với `latest.jsonl`.
- Script local `scratch/Restart-OwnProbe.ps1` chỉ đóng probe riêng rồi mở lại. Không đóng mọi cửa sổ FlashBrowser của người dùng.
- `scratch/Click-Probe.ps1 X Y -Repeat 1 -WaitMs 1200`: đưa probe lên trước rồi click. Start/Cancel dùng một lần để tránh tự đảo trạng thái.
- Tọa độ thường dùng: Túi (858,568); trong phòng Start/Cancel (950,487). Luôn xem ảnh hiện tại vì popup/tutorial/camera có thể đổi vị trí.
- Bằng chứng đạn bay cuối được lưu local: `scratch/shot-live-check/shot-3.png`, `shot-10.png`. Screenshot debug không commit vào Git.
- Log chẩn đoán hữu ích: `STATE_ENTER`, `QUEUE_ERROR`, `UNCAUGHT_FLASH`, `GAME_SEND`, `GAME_RECEIVE`. Sau bản sửa cuối nhận 91/2 và 91/6, queue tiếp tục chạy.

## Đối chiếu ActionScript khi có lỗi tiếp

- FFDec local: `scratch/ffdec/ffdec.jar`.
- Actual client export: `scratch/fight-view-inspect/scripts/game/view/GameView.as` chứa `__shoot`; backend cũ: `Game.Logic/Game.Logic.Phy.Object/Living.cs`, `ShootImp`.
- Các export khác: `scratch/battle-client-inspect`, `scratch/turn-client-inspect`, `scratch/bag-manager-inspect`, `scratch/client-inspect`.
- Export class từ `Flash/4.png` cần Java heap **4096 MB** (`-Xmx4096m`); 768/1024 MB từng OOM hoặc treo GC rất lâu. `2.png` thường dùng 1536 MB.
- Chỉ instrument bản diagnostic riêng khi cần; không vá client production để che lỗi backend.

## Những điều cần giữ nguyên / hạn chế đã biết

- Có nhiều cấu hình/scripts/log thay đổi local từ trước trong root, Server, WebPortal, Request và Flash. Không reset hoặc stage chung.
- `Get-Content` mặc định của Windows PowerShell có thể làm hỏng Unicode khi ghi lại source. Dùng `apply_patch` hoặc `[IO.File]::ReadAllText/WriteAllText` với encoding đúng.
- Không in connection string, password hoặc token vào log bàn giao. Lấy cấu hình DB tại chỗ nếu cần; không thay đổi tài khoản thật để kiểm thử.
- Việc sửa gói bắn và Túi không xác nhận các luồng khác như PvE, kết thúc trận, phần thưởng hoặc toàn bộ profile đã tương thích. Nếu có báo lỗi mới, tái hiện và đọc reader/writer trước khi sửa.

## Yêu cầu cho AI sau này

Trước khi làm tiếp: đọc tài liệu trên, kiểm tra Git và service thực tế, xác nhận lỗi hiện tại từ người dùng. Sau mỗi đợt sửa, cập nhật file này với commit, kiểm thử thực tế và việc còn tồn đọng; giữ nội dung đúng với bằng chứng đã có.
