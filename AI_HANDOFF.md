# Bàn giao cho AI tiếp tục dự án Gunny 9.2

Cập nhật: 2026-10-23, sau sửa nhận thư và đồng bộ toàn bộ danh mục vật phẩm Zing.

## Đọc trước khi thao tác

- Đọc `README.md`, file này và `Gunny92/gameSrc/tools/COMPATIBILITY.md`.
- Đây là nhiều Git repository độc lập. Kiểm tra `git status` trong từng repo trước khi sửa, pull hoặc commit. Không ghi đè cấu hình và thay đổi có sẵn của người dùng.
- Người dùng muốn sửa backend cho Flash/asset mới, kiểm tra bằng **FlashBrowser thực sự**, chạy lại server và đẩy bản sửa lên Git. Trình duyệt không có Flash không chứng minh được game chạy.
- Người dùng đã yêu cầu bỏ mã xác thực **trong game**; đã thực hiện. Không tự bật lại. Đăng nhập tài khoản và RSA vẫn giữ nguyên.
- Không cần hỏi lại những bước triển khai thông thường đã được cho phép. Tuy nhiên phải kiểm tra trạng thái hiện tại trước khi làm; máy có thể đã sleep hoặc được khởi động lại.

## Mới nhất: đồng bộ toàn bộ danh mục Zing vào GM và Flash

- **Phát hiện bổ sung sau khi người dùng thử gửi 85784:** tìm kiếm GM đọc **Db_Tank.Shop_Goods**, nhưng **Db_Tank41.SP_Admin_SendUserItem** kiểm tra `Shop_Goods` riêng trong **Db_Tank41**. Bỏ sót bản này trong lần nhập đầu khiến SP tự đổi template không có thành 0, tạo thư rỗng mà API vẫn báo thành công. Người dùng có thư rỗng **85094/85097/85098**; không có item85784 được tạo ở lần kiểm tra ban đầu. Không gán vật phẩm vào các thư cũ vì chúng không lưu yêu cầu gốc; đã nhờ người dùng gửi lại một lần sau sửa.
- **Đã sửa đầy đủ bản player catalog:** `tools/Sync-PlayerItemCatalog.ps1 -Apply` mirror **23.362** template chính sang Db_Tank41, thêm **10.445** từ nền **12.919**, giữ riêng **2** ID **72083/72084**, tổng bảng player **23.364**. Giữ cột `Remark/Valid/Count/Price` trên dòng cũ. Cột `Hole` của Db_Tank41 ngắn hơn bản chính; đã mở rộng **nvarchar(50)→nvarchar(100)** trong transaction. Backup thành công **`scratch/player-item-catalog-backup-20261023-171105`**; có SQL XML/schema, độ dài Hole cũ (100 byte) và báo cáo. Lần trước lỗi truncation đã rollback.
- `Sync-ZingCatalog.ps1 -Apply` nay tự gọi bước mirror sau bước SQL/Request chính; đây là **hai transaction liên tiếp**, không hứa atomic xuyên cả hai bước. Nếu mirror lỗi thì không tiếp tục gửi đồ, sửa/chạy lại tool mirror. `Test-ItemCatalog.ps1 -PlayerBackupDirectory ...` đã PASS **1.027.928 trường** giữa bản chính/player, giữ 2 ID riêng và các cột riêng.
- Báo cáo tool mới tách **CanonicalApplied / PlayerCatalogApplied / Applied**; chỉ đánh dấu Applied=true sau khi cả hai bước xong. Nếu mirror lỗi sau commit bước chính, lưu trạng thái chưa hoàn tất và lệnh khôi phục đồng bộ vào report.json. Reviewer đã kiểm tra mirror/schema/verifier; ý kiến quan trọng về trạng thái nhập dở đã được xử lý. Review không thử giả lập mất kết nối lúc commit.
- **Đã gửi thực tế 85784 qua API GM vào tài khoản kiểm tra AIProbe 228:** thư **85100**, Annex1 **455488**, row item **455488**, TemplateID **85784**, Count **1**, UserID **0**, Place **-1** đúng mô hình item chờ nhận thư. Khác lỗi cũ là thư này có item và liên kết đính kèm thật. Chưa khẳng định người dùng đã nhận/đeo thành công món này; đang chờ họ gửi lại.
- `WebPortal/api.ashx` đã thêm kiểm tra **Count>0** và template/MaxCount trong **Db_Tank41.Shop_Goods** trước khi gọi SP, tránh báo thành công/tạo thư rỗng nếu chưa đồng bộ. Gọi API với ID không tồn tại và Count=0 đã trả success=false. Không thay SP hay chèn vật phẩm vào tài khoản thật để thử.
- WebPortal commit **`0747b2c`** đã push, chỉ 18 dòng kiểm tra trong `api.ashx`; không sửa/đưa cấu hình hay credential mới vào commit. WebPortal là **repo Git riêng** dù bị ignore ở root; không force-add WebPortal vào repo root.
- Người dùng đã đăng nhập được trang **https://idgunny.zing.vn/login-game?download=direct** bằng probe và yêu cầu **đồng bộ tất cả danh mục, lấy dữ liệu Zing làm chuẩn**, thay vì chỉ Vòng Tay/Nhẫn 17 Tuổi. Đã thêm ID thiếu, cập nhật thuộc tính của ID chung; giữ ID chỉ có local và các cột SQL riêng.
- Endpoint thực tế: **https://quest371.gn.zing.vn/templatealllist.xml**, bảng có **18.120 template**. File CDP ban đầu bị Chromium giải mã zlib như text vì MIME `text/xml`, xuất hiện ký tự thay thế và mất byte. **Không dùng file `.bin` CDP đó để import.** Đã tải HTTP nhị phân trực tiếp từ endpoint công khai, không cần cookie/token; giải nén và parse XML thành công. Nguồn chuẩn được lưu có thể tái dựng tại `tools/item-data/zing-catalog-20261023.xml.zlib` cùng manifest SHA256. Hash zlib **B66BE8CF6FE04393D2B5A7C08CFDE246D04B3FCE7E32226A2B0D6A802EA272C2**; hash XML **2E11B2029D6B0AD6934970F53EA78ED3CA0F276BAE55DF04EA05994C05BEEDD6**.
- Đã cập nhật `Db_Tank.dbo.Shop_Goods` và **Request/TemplateAlllist.xml**: từ **19.122** thành **23.362** món, thêm **4.240**, thay đổi thuộc tính **4.925** món cũ; **5.242** ID chỉ có local được giữ nguyên. So sánh ban đầu báo 1.638 khác biệt là chỉ xét trường chính; so đầy đủ mới ra 4.925. Không xóa item của nhân vật, không sửa tài khoản, không nhập giá shop hay dữ liệu nhiệm vụ/sự kiện.
- Backup của lần áp dụng thành công: **`scratch/item-catalog-backup-20261023-170228`**. Gồm SQL `Shop_Goods.xml` kèm schema, Request cũ, bảng sau nhập, `report.json` và `verification.txt`. Các lần trước tại 16:59/17:00 thất bại do mặc định SQL rồi atomic replace; giao dịch đã rollback, không coi là lần triển khai thành công. Script đã sửa mặc định `Valid/Count/...` và dùng đường dẫn backup hợp lệ cho `File.Replace`.
- Tool tái dựng: `tools/Sync-ZingCatalog.ps1 -SourceXml <XML>` mặc định dry run; `-Apply` mới ghi DB/file. Dữ liệu dùng SqlBulkCopy và transaction, chỉ UPDATE các thuộc tính từ source, giữ cột local. Reviewer phát hiện rollback có thể ném lỗi trước khi khôi phục file: đã sửa try/finally để khôi phục độc lập bằng atomic replace. Chi tiết trong `tools/item-data/README.md`.
- **Xác minh trực tiếp PASS** bằng `tools/Test-ItemCatalog.ps1`: đọc Request qua IIS, so toàn bộ **18.120 item / 797.280 trường SQL** và mọi thuộc tính client với nguồn; so toàn bộ ID local và cột DB riêng với backup. Tổng SQL/client đều **23.362**. Không chỉ kiểm tra số lượng.
- API GM `gm_search_items&q=17 Tuổi` trả đủ 11 Vòng Tay và 11 Nhẫn. Vòng tay thường **8078**, +1..+5 **8178,8278,8378,8478,8578**, +6..+10 **85780..85784**. Nhẫn thường **9078**, +1..+5 **9178,9278,9378,9478,9578**, +6..+10 **95780..95784**. **8220 vẫn là Vòng Tay 12 Tuổi +2**; không đổi ID món cũ.
- Đã tải **141 icon còn thiếu** từ `https://gunny.vcdn.vn/` theo `PathManager.solveGoodsPath` và `EquipType.TYPES` thực tế, có đủ 4 cấp ảnh `17fiveyearsz1..4` cho cả armlet/ring. Kiểm tra PNG/JPEG trước khi lưu, không ghi đè ảnh có sẵn. **233 đường dẫn trả HTTP 404**, còn **305 item** có tên ảnh hoặc loại cần tham số riêng chưa lập được đường dẫn icon. Báo cáo local **`scratch/zing-item-metadata-probe/icon-sync-report.json`**. Không khẳng định đã có toàn bộ skin, ảnh động hay hiệu ứng. Tool `tools/Sync-ItemIcons.cjs` có dry run mặc định.
- Road đã nhận **`item&reload`**, console xác nhận **`item info is Reload!`**. Khi gửi bằng WriteConsoleInput phải dùng virtual key **0x37 + SHIFT** cho `&`; dùng ASCII 0x26 sẽ thành phím mũi tên lên. Helper riêng ở `scratch/ReloadItemCatalog.cs/.exe`, chỉ kiểm soát Road/Fight đúng dự án. Không gửi chat hoặc nhắn người khác.
- Fight có cache ItemMgr riêng và không có console item reload, nên đã dừng bình thường rồi khởi động riêng Fight để nhận vũ khí mới. PID cuối **Fight 28584**, **Road 28492**, **Center 21136**; kiểm tra lại trạng thái trước thao tác. Không sửa DLL trong đợt catalog này, không đóng client gốc hay probe Zing của người dùng. Người chơi local cần mở lại game để nạp Request mới.
- Request tests `test-startup-contracts.cjs` và `prepare-compressed-xml.cjs --check` **PASS (254 zlib XML)**; metadata probe tests PASS, bổ sung regression từ chối body nén đã bị giải mã text hỏng. Danh mục/GM đã đồng bộ, **chưa kiểm thử sử dụng/gửi thư/đeo/chiến đấu cho mọi món mới**; rương, kỹ năng và hệ thống mới cần logic/dữ liệu backend tương ứng. Không tuyên bố đồng bộ toàn bộ trò chơi hay mọi chức năng từ bảng item.
- Commit Request **`9bad884`**, Resource **`c7fdd22c0`**: bảng item và 141 icon; giữ cấu hình local `Request/Web.config`, `Resource/crossdomain.xml` ngoài commit. Fight khởi động xong, console **`GameServer is now open for connections!`** lúc 17:06:01, có Road kết nối vào. Console vẫn có cảnh báo thiếu một số bomb; không suy diễn mọi vũ khí mới dùng được từ việc catalog nạp thành công.
- **Flash thật sau nhập:** probe riêng `scratch/catalog-local-probe`, tài khoản **ai_room_probe / AIProbe 228**, đã tải `/request/templatealllist.xml` HTTP200, `STATE_ENTER_OK main` lúc **17:08:36**. Có screenshot `latest.png`; không cần restart lại client gốc của người dùng. Không thấy lỗi parser item trong log bước vào sảnh này.

## Đợt trước: thư GM, dữ liệu trang bị và đăng nhập GNDdt

- **Đã sửa nhận đính kèm thư; người dùng xác nhận “đã nhận thư được rồi”.** Món tái hiện là TemplateID **8220**. Trong DB hiện tại đây là **Vòng Tay 12 Tuổi +2**, không phải Vòng Tay 17 Tuổi.
- Nguyên nhân gói **113**: client gửi `byte selectionType, int mailCount, int mailIDs[]`; handler cũ đọc `int mailID, byte selectionType`, nên đọc sai ID. Client cũng cần `int resultCount` trước từng kết quả `mailID, slotCount, slotIDs[]` nhưng phản hồi cũ thiếu trường này.
- gameSrc commit **`0f22221`** đã push: `MailAttachmentV92` kiểm tra toàn bộ framing, số lượng/ID/ID trùng trước khi dispatch; gắn ID người chơi đã xác thực; chuyển từng thư qua handler cũ. Các kiểm tra chủ sở hữu, mật khẩu túi, sức chứa và thưởng vẫn dùng logic cũ. `PatchMatchmaking` giữ nguyên thân IL của handler cũ và thêm adapter phản hồi. Đã bổ sung Compile Include vào csproj.
- Pipeline `Build-Compatibility.ps1` đã PASS toàn bộ sau sửa. `MailAttachmentTests` kiểm tra wire format, dữ liệu sai và framing phản hồi; `MailAttachmentHookTests` gọi DLL đã patch với túi khóa, xác nhận routing vào logic cũ mà không cấp vật phẩm hoặc truy cập SQL. Hai test này đã chạy lại PASS sau triển khai. Code review đã hoàn tất; thiếu Compile Include được sửa.
- Server commit **`a29787a`** đã push. Đã triển khai qua `tools/Apply-MatchmakingFix.ps1` local. Backup **`scratch/matchmaking-deploy-backup-20261023-161642`**. Bốn DLL runtime so SHA256 khớp `Gunny92/bin/compatibility`. Road helper hash **14FBAE36FDEAA1B4573987CAF0FB6695860E851565F5BEA34F35BDBDD4FC7357**, Road main **CA6AD5DAED78E38A282CCC338304997DC5FFED673D94F156426A90B55CE7D808**. PID kiểm tra cuối: Center **21136**, Fight **4984**, Road **28492**; luôn đọc lại trước thao tác.
- Chưa có template gốc của **Vòng Tay 17 Tuổi** trong DB hay các bảng Request local. Không tự bịa ID/chỉ số từ ảnh. Cache client gốc đã được kiểm tra: 4175 ByteArray, chủ yếu SWF/ảnh/ZIP UI; không tìm thấy bảng TemplateAllList trong cache. Báo cáo local `scratch/native-item-cache/REPORT.md`; không commit cache hay dữ liệu tài khoản. Các config tĩnh của client có đường dẫn cũ, không coi là bằng chứng endpoint runtime.
- Theo yêu cầu người dùng, đã mở riêng FlashBrowser thu dữ liệu cho **https://www.gnddt.com/** bằng `-CaptureMetadata -OutputName item-metadata-probe -ShowWindow`. Chỉ lưu phản hồi bảng TemplateAllList/ShopItemList và config; che mọi giá trị query, không ghi ảnh/console/nội dung đăng nhập. Hồ sơ nằm trong scratch, không commit. Xem `tools/flash-probe/README.md` và test `test-metadata-capture.cjs` (PASS).
- Lỗi màn hình trắng ban đầu của probe đã xử lý bằng khởi tạo renderer `about:blank` trước khi chờ CDP Network.enable; runtime Electron **9.4.4**, plugin Flash có mặt. Sau đó người dùng gặp **“OOPS! Đăng nhập vào server thất bại!!! Hãy thử đăng nhập lại.”**, trong khi client gốc chơi được. **Chưa có bằng chứng admin chặn trình duyệt.** Phát hiện probe tự chặn `new-window` rồi gọi `loadURL` cùng cửa sổ, làm thay đổi referrer/opener/luồng mở trang. Đã bỏ chuyển hướng này, để Electron mở cửa sổ mặc định và gắn bộ thu dữ liệu vào cửa sổ con. Test regression PASS; chưa xác nhận đăng nhập máy chủ thành công sau thay đổi.
- Probe mới đã mở lúc **16:45 ngày 23/10**, `metadata-ready` và trang chủ tải xong **16:45:11 (+07)**. Đang chờ người dùng thử đăng nhập/chọn server lại qua câu hỏi bất đồng bộ. Log `scratch/item-metadata-probe/latest.jsonl`; bảng nếu thu được ở `metadata/captures.jsonl` và `.bin`. Chưa thu được bảng vật phẩm tại thời điểm cập nhật. Nếu còn OOPS, tiếp tục xác định bước chuyển trang thất bại, không khẳng định remote chặn chỉ dựa thông báo này.
- Code review công cụ yêu cầu tránh ghi đè body cùng endpoint: tên file nay chứa SHA256 của endpoint và nội dung. Giới hạn thời gian probe được đăng ký trước các thao tác chờ tải trang. Kiểm thử byte nén, không lưu phản hồi login, che URL, popup mặc định và hai body khác nhau cùng endpoint đều PASS.
- **Không đóng hay sửa client gốc đang chơi** (`GunnyClient.exe` / `GunnyBrowser.exe`). Chỉ dừng probe có ExecutablePath đúng `scratch/item-metadata-probe/FlashBrowser.exe` khi cần; không stop toàn bộ FlashBrowser. Không restart Road/Fight thêm chỉ để sửa công cụ thu dữ liệu.
- **Chỉ đạo mới nhất của người dùng: dừng thử GNDdt, chuyển sang `https://idgunny.zing.vn/login-game?download=direct`.** Đã đóng riêng probe GNDdt và mở probe Zing ở `scratch/zing-item-metadata-probe` với `-CaptureMetadata -ShowWindow -DurationSeconds 3600`. Từ đây đọc log/bảng ở thư mục Zing; GNDdt không còn là nhánh cần tiếp tục. Giữ popup mặc định, bộ thu dữ liệu không giới hạn tên miền GNDdt. Cần người dùng tự đăng nhập/chọn máy chủ trên cửa sổ Zing rồi kiểm tra bảng thực tế; chưa có ID hoặc chỉ số Vòng Tay 17 Tuổi để đồng bộ GM.

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

## Đợt tiếp tục ngày 2026-10-23: kết quả trận và hướng dẫn

### Thay đổi và commit

- gameSrc **`7457fad`**: `BattleResponseV92.UpgradeOver` đổi gói PvP **91/100** theo `GameOverAction.readInfo`; giữ thắng/thua, cấp/GP, thưởng kinh nghiệm/cống hiến, số thẻ, guild riches và số kill. Thêm các trường client mới bắt buộc với mặc định không hoạt động. Gói cũ làm reader đi quá cuối payload và không hoàn tất màn kết quả.
- Cùng commit thêm `UpgradeHealth` cho **91/11**: backend ghi `byte type, int blood, int value`; client đọc `byte type, long blood, int value, int context`. Sign-extend máu, giữ lượng thay đổi và thêm context 0. Đã tái hiện `STATE_ERROR fighting Error #2030` tại `GameView.playerBlood` khi death packet đến trong lúc tải; không sửa client để che lỗi gói backend.
- Cả hai adapter chỉ chạy trên relay Road cho phòng **Match/EliteGameScore/EliteGameChampion**. PvE, phòng không xác định và kết nối AI giữ định dạng cũ.
- Server **`31f73b5`**: triển khai helper Road mới cùng helper Fight từ pipeline. `Game.Server.dll` và `Fighting.Server.dll` không đổi nội dung so với bản cũ; helper Fight chỉ được build lại từ source không đổi.
- Flash **`e90a98a`**: sửa `gameCommon.view.control.LiveState` trong **4.png**, tăng asset version **261**. Trước đây đăng ký callback đã đánh dấu hoàn thành nhưng callback vẫn hiện mũi tên mỗi lượt. Giờ kiểm tra cờ trước khi hiện và chỉ `syncWeakStep` khi thực sự hiện lần đầu; dùng các bước có sẵn **6, 23/25, 26**, không tắt toàn bộ hướng dẫn. Dander phải đạt 200 mới ghi hoàn thành bước 26. Cleanup chỉ xóa các mũi tên thuộc callback **18, 19/20, 21**. Map 114 giữ tiến độ tutorial riêng như cũ.
- Source Flash có thể tái dựng tại `Flash/scripts/client-patches/gameCommon/view/control/LiveState.as`; hướng dẫn trong `Flash/scripts/client-patches/README.md`. Không sửa `2.diagnostic.png` hoặc `2.png` trong đợt này.

- Ba commit gameSrc/Server/Flash ở trên đã push lên `origin/master`; kiểm tra local/upstream đều `0 0` sau push.

### Kiểm thử đã chạy

- Pipeline `Build-Compatibility.ps1` toàn bộ PASS, gồm test mới **BattleOverTests**, **BattleHealthTests** và gate phòng trong **MatchmakingTests**.
- Test kết quả đọc đúng đến cuối gói, giữ phần thưởng/header, kiểm tra 0/1/2/8 người, hòa và payload lỗi. Test máu kiểm tra sống/chết, giá trị signed/max, hồi máu/sát thương và framing.
- `node Flash/scripts/test-combat-guide.cjs` PASS: callback AS thực tế chỉ hiện một lần qua nhiều lượt, không đánh dấu khi chưa hiện, giữ cờ qua view/login, độc lập nhân vật, không xóa mũi tên khác và giữ map 114.
- Đã import class vào SWF bằng FFDec, export lại từ binary đã build và chạy test trên class export: PASS. `node Flash/scripts/test-sevenday-contract.cjs` PASS.
- Request: `node scripts/test-startup-contracts.cjs` PASS; `node scripts/prepare-compressed-xml.cjs --check` PASS với **254 zlib XML**.
- Probe Flash đăng nhập được vào sảnh sau triển khai, tải `4.png?lv=261` HTTP 200; vào chiến đấu có `STATE_ENTER_OK fighting`. Gói kết quả trận hai người là **91/100 len=309**; đã hiện màn kết quả/lật bài thực tế. Vì probe không gây sát thương trong trận kiểm tra, client báo không đủ điều kiện lật bài; không cấp thưởng để vượt điều kiện này.
- Sau màn kết quả, probe đã trở về **phòng 624**, có **`STATE_ENTER_OK matchRoom` lúc 15:31:27 (+07:00)**. Đã xác minh luồng vào trận → kết thúc → màn lật bài → trở lại phòng thực tế, không còn đứng ở map của trận này.
- Bằng chứng local: `scratch/result-live-check/result.png`, `room.png`, `probe.jsonl` (lọc đợt cuối sau 15:27:43). Log trước khi sửa máu nằm riêng tại `scratch/result-check-before-health.jsonl`; không nhầm lỗi cũ với đợt kiểm tra cuối.
- Trận có đối thủ rời/timed out ngay trong màn tải đã giúp phát hiện lỗi máu; sau bản sửa máu cuối mới kiểm tra lại trận bot thông thường, chưa tái hiện riêng lần nữa nhánh kết thúc ngay trong lúc tải.
- Kiểm thử tự động chứng minh lần hướng dẫn đầu và cờ lưu; chưa tạo nhân vật mới để kiểm tra thủ công toàn bộ tutorial từ đầu. Không khẳng định toàn bộ PvE/phần thưởng đã tương thích.

### Trạng thái triển khai và lưu ý vận hành

- Dịch vụ cuối: Center PID **21136**, Fight PID **30268**, Road PID **7040** tại thời điểm kiểm tra; luôn lấy PID mới khi thao tác.
- Backup trước triển khai cuối: `scratch/matchmaking-deploy-backup-20261023-152647`. Backup client gốc trước đợt này: `scratch/combat-guide-backup-20261023/4.png`.
- Bốn DLL runtime đã được so hash khớp `Gunny92/bin/compatibility` sau build cuối. `Game.Matchmaking.V92.dll` SHA256: **C9D0CEEAEE4745DD54F7ED43BA0C4B2D910E8A0AC795EC3C416D5BE9D747539B**.
- Flash `4.png` SHA256: **F489CD498FB8AA82391AC403B13AA38C0E35B84A43DF323CE872EF20AF7C7E09**.
- Đã gặp treo đăng nhập sau một lần restart; khôi phục bộ cũ và người dùng xác nhận vào lại được. Sau triển khai cuối, probe cũng đã vào sảnh/chiến đấu được. Chưa chứng minh nguyên nhân của lần treo đó; không ghi rằng do DLL login vì hash `Game.Server.dll` cũ/mới giống nhau.
- Chờ console **`Server started!`**, không chỉ cổng mở, trước khi kiểm tra login. Sau restart cần mở lại/reload cửa sổ game. Không restart lặp vô cớ.
- Script `tools/Apply-MatchmakingFix.ps1` local đã cập nhật hash build cuối; vẫn phải kiểm tra hash trước lần chạy tiếp theo. Không stage script local này cùng các thay đổi có sẵn của người dùng.
- Bản sửa Flash đã commit riêng hunk version 260→261 trong `config.xml`; các cấu hình IP local khác, `crossdomain.xml`, cấu hình Server, log và thay đổi root cũ vẫn được giữ ngoài commit.
- `ReadRoadConsole.exe` nhận PID hiện tại. `scratch/Restart-OwnProbe.ps1` đôi khi đóng probe chưa xong đã mở lại và báo đang có probe; chỉ thao tác process có ExecutablePath đúng `scratch/flash-probe/FlashBrowser.exe`, không đóng FlashBrowser của người dùng.
- PowerShell 5 không hỗ trợ `ConvertTo-Json -AsArray`; gửi lệnh probe bằng `ConvertTo-Json -InputObject $actions` để giữ JSON array.
- `Server/road/Bussiness.dll.config` chứa cấu hình DB cũ không dùng được trực tiếp trên máy này. Các lần thử SQL chỉ đọc đã thất bại; **không có thay đổi DB hoặc reset cờ hướng dẫn tài khoản thật/probe** trong đợt này.
