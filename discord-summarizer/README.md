# Discord Summarizer

Tự động export tin nhắn từ một Discord server nguồn, tóm tắt bằng Claude, và gửi kết quả vào một server hoặc kênh khác qua webhook.

**Luồng hoạt động:**
```
[9:00 / 12:00 / 18:00 hàng ngày]
  Windows Task Scheduler
    → export_daily.ps1           (export tin nhắn mới từ Server nguồn)
    → exports/YYYY-MM-DD_HH-mm/  (lưu file .txt theo từng kênh)

[Khi bạn muốn đọc tóm tắt]
  Mở Claude Code → gõ "tóm tắt mới nhất"
    → Claude đọc file export
    → Tóm tắt nội dung
    → post_webhook.ps1           (gửi vào server đích tự động)
```

---

## Yêu cầu hệ thống

- Windows 10/11
- PowerShell 5.1 (có sẵn mặc định)
- [Claude Code](https://claude.ai/code) đã cài trong VSCode (extension) hoặc desktop app

---

## Cài đặt lần đầu

### Bước 1 — Clone hoặc tải project về máy

```powershell
git clone <repo-url>
cd discord-summarizer
```

> Tất cả lệnh trong hướng dẫn này đều phải chạy từ trong thư mục `discord-summarizer/` (thư mục chứa file `export_daily.ps1`).

---

### Bước 2 — Bật Developer Mode trong Discord

`Settings` → `Advanced` → bật **Developer Mode**

> Cần thiết để copy được Channel ID, Category ID, Server ID bằng cách chuột phải.

---

### Bước 3 — Tải DiscordChatExporter CLI

1. Vào: https://github.com/Tyrrrz/DiscordChatExporter/releases/latest
2. Tải file `DiscordChatExporter.Cli.zip`
3. Giải nén toàn bộ vào thư mục **`dce\`** trong project

Kiểm tra: `dce\DiscordChatExporter.Cli.exe` phải tồn tại.

---

### Bước 4 — Lấy Discord User Token

> Token này cho phép DiscordChatExporter đọc tin nhắn bằng tài khoản của bạn.
> **Không chia sẻ token cho bất kỳ ai.**

1. Mở Discord trên **trình duyệt web** (không phải app)
2. Nhấn `F12` → chọn tab **Network**
3. Nhấn `Ctrl+R` để reload trang
4. Gõ `api/v` vào ô filter
5. Click vào bất kỳ request nào → tab **Headers**
6. Tìm dòng `Authorization:` → copy toàn bộ giá trị

---

### Bước 5 — Lấy thông tin Server nguồn

Trong **Server nguồn** (server bạn muốn đọc tin nhắn):

- **Server ID**: Chuột phải vào tên server → `Copy Server ID`
- **Category ID**: Chuột phải vào tên category (dòng chữ IN HOA) → `Copy Category ID`
  - Nếu theo dõi nhiều category: ngăn cách bằng dấu phẩy
- **Channel ID riêng lẻ** _(tùy chọn)_: Chuột phải vào tên kênh → `Copy Channel ID`
  - Dùng khi muốn theo dõi kênh cụ thể nằm ngoài các category trên

---

### Bước 6 — Tạo Webhook cho server đích

1. Vào server/kênh muốn nhận tóm tắt
2. Click icon bánh răng (Edit Channel) → tab **Integrations**
3. **Webhooks** → **New Webhook** → **Copy Webhook URL**

---

### Bước 7 — Cấu hình file `.env`

Copy file mẫu:
```powershell
Copy-Item .env.example .env
```

Mở `.env` và điền đầy đủ:

```env
DISCORD_USER_TOKEN=    # Lấy từ Bước 4
SERVER_A_GUILD_ID=     # Server ID của server nguồn (Bước 5)
SOURCE_CATEGORY_IDS=   # Category ID cần theo dõi, nhiều ID ngăn cách bằng dấu phẩy (Bước 5)
SERVER_A_CHANNEL_IDS=  # (Tùy chọn) Channel ID riêng lẻ ngoài category, nhiều ID ngăn cách bằng dấu phẩy (Bước 5)
SERVER_B_WEBHOOK_URL=  # Webhook URL của server đích (Bước 6)
```

> `SERVER_A_CHANNEL_IDS` không bắt buộc. Nếu bỏ trống, chỉ export theo category.

---

### Bước 8 — Chạy setup Task Scheduler

Mở PowerShell **với quyền Administrator**, `cd` vào thư mục project rồi chạy:

```powershell
cd "C:\path\to\discord-summarizer"
powershell -ExecutionPolicy Bypass -File setup_scheduler.ps1
```

Lệnh này tạo 3 task tự động chạy export lúc **9:00**, **12:00**, **18:00** mỗi ngày.

> Máy tính cần bật và có mạng vào các khung giờ đó.

---

### Bước 9 — Test toàn bộ hệ thống

**Cd vào thư mục project trước:**
```powershell
cd "C:\path\to\discord-summarizer"
```

**Test export thủ công:**
```powershell
powershell -ExecutionPolicy Bypass -File export_daily.ps1
```

Kết quả mong đợi: thư mục `exports\YYYY-MM-DD_HH-mm\` xuất hiện với các file `.txt`.

**Test gửi webhook:**

```powershell
powershell -ExecutionPolicy Bypass -File post_webhook.ps1 -Message "Test OK"
```

Kết quả mong đợi: tin nhắn xuất hiện trong kênh server đích.

---

## Sử dụng hàng ngày

### Tổng quan một ngày làm việc

```
SÁNG
  9:00  → Máy tự export tin nhắn (Task Scheduler)

  Muốn đọc tóm tắt buổi sáng:
    → Mở Claude Code (VSCode hoặc desktop app)
    → Gõ: "tóm tắt mới nhất"
    → Đợi ~10 giây
    → Tóm tắt xuất hiện trong kênh đích Discord

TRƯA
  12:00 → Máy tự export tin nhắn (Task Scheduler)

  Sau ăn trưa, muốn cập nhật:
    → Claude Code → "tóm tắt mới nhất"

CHIỀU
  18:00 → Máy tự export tin nhắn (Task Scheduler)

  Cuối ngày, muốn review:
    → Claude Code → "tóm tắt mới nhất"
```

---

### Đọc tóm tắt thủ công

**Bước 1** — Mở Claude Code

- Trong VSCode: nhấn `Ctrl+Shift+P` → gõ "Claude" → chọn **Open Claude**
- Hoặc mở terminal trong VSCode → gõ `claude`

**Bước 2** — Gõ prompt

```text
tóm tắt mới nhất
```

| Muốn xem | Gõ |
| --- | --- |
| Tin nhắn mới nhất (batch gần nhất) | `tóm tắt mới nhất` |
| Toàn bộ tin nhắn hôm nay | `tóm tắt hôm nay` |
| Tin nhắn buổi sáng | `tóm tắt export lúc 9h` |

**Bước 3** — Nhận kết quả

Claude sẽ tự tìm file export trong thư mục `exports\`, đọc, tóm tắt, và gửi vào kênh đích qua webhook.

---

### Nếu mở máy muộn hơn giờ export

**Option A — Bật "chạy bù khi lỡ giờ" (làm 1 lần):**

1. Mở `taskschd.msc`
2. Tìm task `DiscordSummarizer-9AM` → chuột phải → **Properties**
3. Tab **Settings** → tích **"Run task as soon as possible after a scheduled start is missed"**
4. Lặp lại cho `DiscordSummarizer-12PM` và `DiscordSummarizer-18PM`

**Option B — Chạy export thủ công:**

```powershell
cd "C:\path\to\discord-summarizer"
powershell -ExecutionPolicy Bypass -File export_daily.ps1
```

Sau đó quay lại Claude Code và gõ `tóm tắt mới nhất` như bình thường.

---

## Cấu trúc thư mục

```
discord-summarizer/
├── dce/                        ← DiscordChatExporter CLI (tải về, không commit)
├── exports/
│   ├── 2026-06-27_09-00/       ← Export lúc 9h ngày 27/6
│   │   ├── channel-name-1.txt
│   │   └── channel-name-2.txt
│   └── 2026-06-27_12-00/       ← Export lúc 12h ngày 27/6
├── .env                        ← Cấu hình bí mật (không commit lên git)
├── .env.example                ← Mẫu cấu hình
├── export_daily.ps1            ← Script export (Task Scheduler gọi tự động)
├── post_webhook.ps1            ← Script gửi tin nhắn vào kênh đích
├── setup_scheduler.ps1         ← Setup Task Scheduler (chạy 1 lần duy nhất)
└── last_run.txt                ← Lưu thời điểm export gần nhất (tự sinh)
```

---

## Xử lý sự cố

**Lỗi "file does not exist" khi chạy script:**

- Bạn đang đứng sai thư mục. Phải `cd` vào đúng thư mục chứa `export_daily.ps1` trước khi chạy bất kỳ lệnh nào.

**Export không chạy tự động:**

- Kiểm tra Task Scheduler: `taskschd.msc` → tìm task `DiscordSummarizer-*`
- Chạy thủ công trong PowerShell: `Start-ScheduledTask -TaskName "DiscordSummarizer-9AM"`
- Đảm bảo máy bật và có mạng đúng giờ

**Lỗi `forbidden` khi export:**

- Tài khoản không có quyền đọc kênh đó — bình thường, script tự bỏ qua

**Token hết hạn / lỗi xác thực:**

- Lấy lại token theo Bước 4 và cập nhật `.env`

**Không nhận được tin nhắn ở kênh đích:**

- Kiểm tra `SERVER_B_WEBHOOK_URL` trong `.env`
- Chạy test: `powershell -ExecutionPolicy Bypass -File post_webhook.ps1 -Message "test"`

**Channel ID không tìm thấy:**

- Kiểm tra lại ID trong `SERVER_A_CHANNEL_IDS` — phải là kênh text (type 0) trong cùng server

---

## Bảo mật

- File `.env` chứa token Discord — **không commit lên git, không chia sẻ**
- Token Discord tương đương mật khẩu tài khoản
- Nếu token bị lộ: đổi mật khẩu Discord ngay (token sẽ tự hết hạn)
- `.gitignore` nên có dòng `.env` và `exports/` để tránh commit dữ liệu cá nhân
