# 🌟 Gunny 9.2 (DDTank) - Complete Server & Client Ecosystem

Hệ thống mã nguồn đầy đủ của **Gunny 9.2 (DDTank 9.2)** bao gồm toàn bộ Server backend (.NET C#), Web Portal (ASP.NET), Flash Client (SWF & XML), Resource Assets, Launcher (Windows & macOS), Database SQL Server và bộ script tự động hóa triển khai 1-click.

---

## 📑 Mục lục
1. [Cấu trúc hệ thống & Repositories](#-cấu-trúc-hệ-thống--repositories)
2. [Yêu cầu môi trường (Prerequisites)](#-yêu-cầu-môi-trường-prerequisites)
3. [Hướng dẫn Khởi tạo mã nguồn (Clone & Assemble)](#-hướng-dẫn-khởi-tạo-mã-nguồn-clone--assemble)
4. [Hướng dẫn Cài đặt & Chạy Server từ A-Z (Dành cho AI / Kỹ thuật viên)](#-hướng-dẫn-cài-đặt--chạy-server-từ-a-z)
5. [Thông tin Ports, Tài khoản & GM Tool](#-thông-tin-ports-tài-khoản--gm-tool)
6. [Xử lý sự cố thường gặp (Troubleshooting)](#-xử-lý-sự-cố-thường-gặp-troubleshooting)

---

## 🏛 Cấu trúc hệ thống & Repositories

Dự án có dung lượng lớn (~13 GB) nên được phân tách thành các repository độc lập để đáp ứng tiêu chuẩn của GitHub (không quá 2GB/repo và không có file > 100MB):

| Repository | Thư mục đích tương ứng | Mô tả chức năng |
| :--- | :--- | :--- |
| **`gunny92-root`** | `.` *(Thư mục gốc)* | Chứa toàn bộ scripts tự động hóa, cấu hình triển khai, `init.sh`, `init.ps1`, `README.md`. |
| **`gunny92-webportal`** | `WebPortal/` | Web portal cổng 8888: Trang chủ, đăng ký, đăng nhập, API launcher (`api.ashx`), `play2.aspx`, công cụ `gm.aspx`. |
| **`gunny92-server`** | `Gunny92/Server/` | Các dịch vụ game backend: `Center.Service`, `Fighting.Service`, `Road.Service`. |
| **`gunny92-flash`** | `Gunny92/Flash/` | Flash client SWF (`Loading.swf`), giao diện UI, cấu hình `config.xml`, ngôn ngữ. |
| **`gunny92-request`** | `Gunny92/Request/` | Xử lý request HTTP từ Flash client (`ServerList.ashx`, `levellist.xml`, `LoadMapsItems.ashx`...). |
| **`gunny92-resource`** | `Gunny92/Resource.Server/` | Toàn bộ tài nguyên đồ họa (Maps, vũ khí, hiệu ứng, bomb, âm thanh, quần áo...). |
| **`gunny92-db`** | `Gunny92/` | File backup SQL Server (`admin.bak.zip`, `tank.bak`, `tank41.bak`, `member.bak`, `gm.bak`). |
| **`gunny92-gamesrc`** | `Gunny92/gameSrc/` | Mã nguồn C# Visual Studio đầy đủ của Game Server, Battle Server, Center Server, Bussiness logic. |
| **`gunny92-flashbase`**| `Gunny92/flashbaseSrc/` | Mã nguồn ActionScript của Flash Client. |
| **`gunny92-launcher`** | `Gunny92/launcher_base/` | Mã nguồn Electron Launcher Windows (tự động cập nhật, Flash embed). |
| **`gunny92-macos-client`** | `macOS_Client/` | Launcher dành cho người dùng hệ điều hành macOS. |
| **`gunny92-web`** | `Gunny92/` *(Website)* | Các web phụ trợ: `Website`, `Website1`, `website_backend`, `newweb`, `GM`. |

---

## 💻 Yêu cầu môi trường (Prerequisites)

* **Hệ điều hành:** Windows Server 2019 / 2022 (hoặc Windows 10/11 64-bit).
* **Web Server:** IIS 10.0+ kích hoạt các tính năng:
  * ASP.NET 4.8 / .NET Extensibility 4.8
  * Static Content, HTTP Redirection, Default Document
* **Cơ sở dữ liệu:** Microsoft SQL Server 2019 hoặc 2022 (Express hoặc Standard).
* **Runtimes:**
  * .NET Framework 4.8 & .NET Framework 3.5 (SP1)
  * Visual C++ Redistributable 2010 - 2022 (x86 & x64)
* **Git for Windows** (đã thêm vào PATH).

---

## 🚀 Hướng dẫn Khởi tạo mã nguồn (Clone & Assemble)

Sau khi clone repo gốc **`gunny92-root`** về máy:

### Cách 1: Chạy bằng Bash (Linux / Git Bash / macOS)
```bash
# Thay 'YOUR_USERNAME' bằng tên tài khoản hoặc tổ chức GitHub chứa các repo
./init.sh YOUR_USERNAME
```

### Cách 2: Chạy bằng PowerShell (Windows Administrator)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\init.ps1 -GitHubUser "YOUR_USERNAME"
```

> **Cơ chế tự động của `init.sh` / `init.ps1`:**
> 1. Tự động clone đầy đủ 10 sub-repositories vào đúng cấu trúc thư mục quy định.
> 2. Tự động giải nén `admin.bak.zip` (5.3 MB) thành `admin.bak` (112 MB).
> 3. Tự động tạo Directory Junction `C:\Gunny92` trỏ vào `...\Gunny92` để đảm bảo tương thích tuyệt đối đường dẫn tuyệt đối của Server & IIS.

---

## 🛠 Hướng dẫn Cài đặt & Chạy Server từ A-Z

*(Dành cho AI Assistant hoặc Kỹ thuật viên khi triển khai dự án mới hoàn toàn)*

### Bước 1: Khởi tạo cơ sở dữ liệu SQL Server
Nếu máy chưa cài đặt SQL Server, chạy:
```powershell
.\install_sql.ps1
```
Sau đó khôi phục toàn bộ các cơ sở dữ liệu (`Db_Admin`, `Db_GM`, `Db_Member`, `Db_Tank`, `Db_Tank41`):
```powershell
.\restore_dbs.ps1
```
*Lưu ý: Script đã tích hợp tự động tương thích SQL Server 2022, hạ cấp compatibility level về 150/140 và phân quyền `sa` / `abcd@12344`.*

### Bước 2: Cài đặt và cấu hình IIS Web Server
Chạy script tự động cấu hình IIS Website trên cổng `8888` cùng các Virtual Directories:
```powershell
.\setup_iis.ps1
```
Script sẽ tự động:
* Bật đầy đủ IIS Roles & Features (ASP.NET 4.8).
* Tạo Web Site `Default Web Site` trỏ vào `c:\Users\Administrator\Desktop\Gunny92\WebPortal` trên cổng `8888`.
* Tạo các Virtual Directories:
  * `/flash` -> `C:\Gunny92\Flash`
  * `/res` -> `C:\Gunny92\Resource.Server`
  * `/request` -> `C:\Gunny92\Request`
* Cấu hình MIME type cho `.swf`, `.flv`, `.ashx`, `.xml`.
* Mở Firewall cổng `8888`, `80`, `843`.

### Bước 3: Cấu hình địa chỉ IP cho Server
Khi IP máy chủ thay đổi (ví dụ IP Public hoặc IP VPS), chạy:
```powershell
.\apply_network_config.ps1 -PublicIP "221.121.4.241"
```
Script sẽ tự động cập nhật IP đồng bộ trong:
1. `Db_Tank.dbo.ServerInfo` (Cột `IP` = IP mới, `Port` = 9200, `State` = 1).
2. `C:\Gunny92\Flash\config.xml` (Các đường dẫn `FLASHSITE`, `SITE`, `REQUEST_PATH`, `POLICY_FILES`).
3. `C:\Gunny92\Server\center\Center.Service.exe.config`.
4. `C:\Gunny92\Server\fight\Fighting.Service.exe.config`.
5. `C:\Gunny92\Server\road\Road.Service.exe.config`.

### Bước 4: Khởi động toàn bộ Game Server
Khởi động cả 3 dịch vụ nền theo đúng thứ tự logic:
```powershell
.\start_all_services.ps1
```
Thứ tự khởi động tự động:
1. **`Center.Service.exe`**: Quản lý trung tâm, WCF (Port `9302`, `2109`).
2. **`Fighting.Service.exe`**: Quản lý chiến đấu, phòng chờ (Port `9308`).
3. **`Road.Service.exe`**: Game logic chính, tương tác người chơi (Port `9200`).

---

## 🔌 Thông tin Ports, Tài khoản & GM Tool

### Danh sách Ports hoạt động:
* **`8888`**: IIS Web Portal, API launcher, Flash Game, Request handlers.
* **`9200`**: Road.Service (Game Server socket TCP - người chơi kết nối trực tiếp vào port này).
* **`9302`**: Center.Service (TCP).
* **`2109`**: Center.Service WCF.
* **`9308`**: Fighting.Service (Battle Socket TCP).
* **`1433`**: Microsoft SQL Server.

### Tài khoản quản trị & kiểm thử:
* **Tài khoản test:** `admin123` / Mật khẩu: `admin123`
* **Nhân vật:** `lieu` (Cấp độ 65, Lực chiến & GP tối đa).
* **GM Tool:** Truy cập tại `http://<IP>:8888/gm.aspx`
  * Hỗ trợ tìm kiếm vật phẩm theo tên (Search Autocomplete từ 19,122 vật phẩm trong cơ sở dữ liệu `Shop_Goods`).
  * Nâng cấp độ, gửi thư, nạp Xu / Lễ Kim trực tiếp.

---

## 🔍 Xử lý sự cố thường gặp (Troubleshooting)

### 1. Dừng tại 81% và báo lỗi "Tải danh sách máy chủ thất bại!"
* **Nguyên nhân:** Flash client gọi `http://<IP>:8888/request/ServerList.ashx` nhưng trả về rỗng do `Center.Service` hoặc `Road.Service` chưa khởi động.
* **Khắc phục:** Chạy `.\start_all_services.ps1`. Đảm bảo cả 3 tiến trình `Center.Service`, `Fighting.Service`, `Road.Service` đều đang chạy và lắng nghe port `9200`.

### 2. Lỗi SCRIPT1006 / Trình duyệt không load được trang Web
* **Khắc phục:** Sử dụng trình duyệt có tích hợp Flash Player (như 360 Chrome, Cốc Cốc cũ, hoặc sử dụng trực tiếp **Gunny92 Windows/macOS Launcher**).

### 3. Cấp độ trong game không đồng bộ với GM Tool (Set 65 nhưng hiển thị cũ)
* **Nguyên nhân:** Bảng `LevelInfo` trong database và file nén `levellist.xml` thiếu mốc cấp độ 65.
* **Khắc phục:** Hệ thống đã được nạp đủ 65 level với GP 300,000,000 và file `C:\Gunny92\Request\levellist.xml` đã được cập nhật chuẩn.

### 4. Build bộ cài Launcher cho người chơi
Để đóng gói bộ cài Windows Launcher (`Gunny92_Launcher_Windows.zip`):
```powershell
.\build_launcher_packages.ps1
```
File cài đặt sẽ được đưa vào `WebPortal/` để người chơi tải về từ website.
