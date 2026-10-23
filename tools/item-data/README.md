# Đồng bộ danh mục vật phẩm Zing

`zing-catalog-20261023.xml.zlib` là phản hồi HTTP nhị phân công khai của
`https://quest371.gn.zing.vn/templatealllist.xml`, lấy ngày 23/10/2026 sau khi
người dùng tự vào game để xác định endpoint. Có 18.120 template. Hash nguồn
ở `zing-catalog-20261023.json`; không có cookie, tài khoản hoặc dữ liệu nhân vật.

Chạy từ workspace root, PowerShell 5 + Node.js:

```powershell
node tools/item-catalog-zlib.cjs unpack tools/item-data/zing-catalog-20261023.xml.zlib scratch/zing-catalog.xml
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Sync-ZingCatalog.ps1 -SourceXml scratch/zing-catalog.xml
```

Mặc định chỉ lập bản nhập và backup trong scratch. Thêm `-Apply` để cập nhật
`Db_Tank.dbo.Shop_Goods` và `Request/TemplateAlllist.xml`. ID chung nhận các thuộc
tính từ Zing; giữ ID riêng của local và cột SQL không có trong bảng nguồn.
Sau đó công cụ gọi `Sync-PlayerItemCatalog.ps1 -Apply` để đồng bộ bản danh mục
riêng trong **Db_Tank41.Shop_Goods**, nơi `SP_Admin_SendUserItem` thực sự kiểm
tra vật phẩm. Chỉ cập nhật bảng GM tìm kiếm sẽ làm món mới thành thư rỗng.
Bản mirror có backup/transaction riêng; nếu bước này lỗi, sửa rồi chạy lại
`Sync-PlayerItemCatalog.ps1 -Apply` trước khi gửi vật phẩm. Cột `Hole` trong
Db_Tank41 được mở rộng từ nvarchar(50) lên nvarchar(100) để khớp danh mục chính.
Không đồng bộ bảng giá shop, tài khoản, vật phẩm nhân vật hay logic mở rương,
kỹ năng, nhiệm vụ, sự kiện. Danh mục này không chứng minh mọi món dùng được.

Công cụ lưu SQL XML kèm schema, file Request cũ, file Request mới và báo cáo.
Nhập SQL theo transaction; thay file Request bằng atomic replace, khôi phục
file nếu SQL thất bại. Cần giữ backup ở máy; file này chứa toàn bộ dữ liệu
Shop_Goods để khôi phục thủ công khi bảo trì. Không chạy đồng thời nhiều bản
đồng bộ hoặc sửa Shop_Goods trong lúc nhập.

Kiểm tra sau nhập bằng đường dẫn backup trong báo cáo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-ItemCatalog.ps1 -SourceXml scratch/zing-catalog.xml -BackupDirectory scratch/item-catalog-backup-YYYYMMDD-HHMMSS
```

Thêm `-PlayerBackupDirectory scratch/player-item-catalog-backup-YYYYMMDD-HHMMSS`
để kiểm tra toàn bộ bản mirror và việc giữ ID/cột riêng của Db_Tank41.

Verifier đọc bảng Flash qua IIS, đối chiếu mọi thuộc tính nguồn với SQL và
client, đồng thời kiểm tra ID local và cột SQL riêng được giữ nguyên.
Road cần `item&reload` trên console; Fight cần khởi động lại bình thường
để cache vũ khí mới có hiệu lực. Mở lại game local để tải bảng mới.

`Sync-ItemIcons.cjs` nhận JSON gồm `id, category, pic, sex`. Không có `--apply`
thì chỉ báo ảnh thiếu; có `--apply` sẽ tải ảnh chưa có từ CDN Zing, kiểm tra
chữ ký PNG/JPEG và không ghi đè file cũ. Quy tắc đường dẫn lấy từ
`PathManager.solveGoodsPath`/`EquipType.TYPES` của client. Ảnh động, skin khi
mặc và hiệu ứng không được suy ra từ icon; báo cáo giữ riêng các lỗi 404 và
loại cần tham số động.
