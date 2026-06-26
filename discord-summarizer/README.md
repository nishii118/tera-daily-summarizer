# Discord Summarizer

Tự động export tin nhắn từ Server A (công ty) và tóm tắt bằng Claude, gửi kết quả vào Server B (cá nhân).

**Luồng hoạt động:**
```
[9:00 / 12:00 / 18:00 hàng ngày]
  Windows Task Scheduler
    → export_daily.ps1          (export tin nhắn mới từ Server A)
    → exports/YYYY-MM-DD_HH-mm/ (lưu file .txt theo từng kênh)

[Khi bạn muốn đọc tóm tắt]
  Mở Claude Code → gõ "tóm tắt mới nhất"
    → Claude đọc file export
    → Tóm tắt nội dung
    → post_webhook.ps1          (gửi vào Server B tự động)
```

---

## Yêu cầu hệ thống

- Windows 10/11
- PowerShell 5.1 (có sẵn)
- Claude Code đã cài trong VSCode (extension) hoặc desktop app

---

## Cài đặt lần đầu

### Bước 1 — Bật Developer Mode trong Discord

`Settings` → `Advanced` → bật **Developer Mode**

> Cần thiết để copy được Channel ID, Category ID, Server ID.

---

### Bước 2 — Tải DiscordChatExporter CLI

1. Vào: https://github.com/Tyrrrz/DiscordChatExporter/releases/latest
2. Tải file `DiscordChatExporter.Cli.zip`
3. Giải nén toàn bộ vào thư mục `dce\` trong project

Kiểm tra: `dce\DiscordChatExporter.Cli.exe` phải tồn tại.

---

### Bước 3 — Lấy Discord User Token

> Token này cho phép DCE đọc tin nhắn bằng tài khoản của bạn.
> **Không chia sẻ token cho ai.**

1. Mở Discord trên **trình duyệt web** (không phải app)
2. Nhấn `F12` → chọn tab **Network**
3. Nhấn `Ctrl+R` để reload trang
4. Gõ `api/v` vào ô filter
5. Click vào bất kỳ request nào → tab **Headers**
6. Tìm dòng `Authorization:` → copy toàn bộ giá trị

---

### Bước 4 — Lấy Server ID và Category ID của Server A

- **Server ID**: Chuột phải vào tên server → `Copy Server ID`
- **Category ID**: Chuột phải vào tên category (dòng chữ IN HOA) → `Copy Category ID`

Nếu theo dõi nhiều category: ngăn cách bằng dấu phẩy.

---

### Bước 5 — Tạo Webhook cho Server B

1. Vào Server B → kênh muốn nhận tóm tắt
2. Click icon bánh răng (Edit Channel) → tab **Integrations**
3. **Webhooks** → **New Webhook** → **Copy Webhook URL**

---

### Bước 6 — Cấu hình file `.env`

Copy file mẫu:
```powershell
Copy-Item .env.example .env
```

Mở `.env` và điền đầy đủ:

```env
DISCORD_USER_TOKEN=   # Lấy từ Bước 3
SERVER_A_GUILD_ID=    # Lấy từ Bước 4
SOURCE_CATEGORY_IDS=  # Lấy từ Bước 4 (nhiều ID ngăn cách bằng dấu phẩy)
SERVER_B_WEBHOOK_URL= # Lấy từ Bước 5
```

---

### Bước 7 — Chạy setup Task Scheduler

Mở PowerShell, chạy:
```powershell
cd D:\apero\projects\discord-summarizer
powershell -ExecutionPolicy Bypass -File setup_scheduler.ps1
```

Lệnh này tạo 3 task tự động chạy export lúc **9:00**, **12:00**, **18:00** mỗi ngày.

> Máy tính cần bật và có mạng vào các khung giờ đó.

---

### Bước 8 — Test toàn bộ hệ thống

**Test export thủ công:**
```powershell
powershell -ExecutionPolicy Bypass -File export_daily.ps1
```

Kết quả mong đợi: thư mục `exports\YYYY-MM-DD_HH-mm\` xuất hiện với các file `.txt`.

**Test gửi webhook:**
```powershell
powershell -ExecutionPolicy Bypass -File post_webhook.ps1 -Message "Test OK"
```

Kết quả mong đợi: tin nhắn xuất hiện trong kênh Server B.

---

## Sử dụng hàng ngày

### Tổng quan một ngày làm việc

```
SÁNG
  9:00  → Máy tự export tin nhắn từ tối hôm qua đến 9h sáng (Task Scheduler)
  
  Bạn mở máy, muốn đọc tóm tắt buổi sáng:
    → Mở Claude Code (VSCode hoặc desktop app)
    → Gõ: "tóm tắt mới nhất"
    → Đợi ~10 giây
    → Tóm tắt xuất hiện trong Server B Discord của bạn

TRƯA
  12:00 → Máy tự export tin nhắn từ 9h đến 12h (Task Scheduler)
  
  Sau ăn trưa, muốn cập nhật:
    → Claude Code → "tóm tắt mới nhất"

CHIỀU
  18:00 → Máy tự export tin nhắn từ 12h đến 18h (Task Scheduler)
  
  Cuối ngày, muốn review:
    → Claude Code → "tóm tắt mới nhất"
```

---

### Các bước chi tiết để đọc tóm tắt

**Bước 1** — Mở Claude Code

- Trong VSCode: nhấn `Ctrl+Shift+P` → gõ "Claude" → chọn **Open Claude**
- Hoặc mở terminal trong VSCode → gõ `claude`

**Bước 2** — Gõ prompt

```
tóm tắt mới nhất
```

hoặc tùy mục đích:

| Muốn xem | Gõ |
| -------- | --- |
| Tin nhắn mới nhất (batch gần nhất) | `tóm tắt mới nhất` |
| Toàn bộ tin nhắn hôm nay | `tóm tắt hôm nay` |
| Tin nhắn buổi sáng | `tóm tắt export lúc 9h` |

**Bước 3** — Nhận kết quả

Claude sẽ:
1. Tự tìm file export trong thư mục `exports\`
2. Đọc và tóm tắt nội dung từng kênh
3. Tự gửi vào Server B qua webhook

→ Mở Discord Server B là thấy tóm tắt ngay.

---

### Nếu mở máy muộn hơn giờ export

Ví dụ: Task Scheduler đặt lúc 9:00 nhưng bạn mở máy lúc 9:15.

**Cách xử lý:**

Option A — Bật "chạy bù khi lỡ giờ" (làm 1 lần):

1. Mở `taskschd.msc`
2. Tìm `DiscordSummarizer-9AM` → chuột phải → **Properties**
3. Tab **Settings** → tích **"Run task as soon as possible after a scheduled start is missed"**
4. Lặp lại cho `DiscordSummarizer-12PM` và `DiscordSummarizer-18PM`

→ Sau đó mỗi lần bật máy muộn, Windows tự chạy bù ngay lập tức.

Option B — Chạy export thủ công bất kỳ lúc nào:

```powershell
cd D:\apero\projects\discord-summarizer
powershell -ExecutionPolicy Bypass -File export_daily.ps1
```

Sau đó quay lại Claude Code và gõ `tóm tắt mới nhất` như bình thường.

---

## Cấu trúc thư mục

```
discord-summarizer/
├── dce/                        ← DiscordChatExporter CLI
├── exports/
│   ├── 2026-06-27_09-00/       ← Export lúc 9h ngày 27/6
│   │   ├── aap861-ai-hair.txt
│   │   └── ...
│   └── 2026-06-27_12-00/       ← Export lúc 12h ngày 27/6
├── .env                        ← Cấu hình (không commit lên git)
├── .env.example                ← Mẫu cấu hình
├── export_daily.ps1            ← Script export (Task Scheduler gọi)
├── post_webhook.ps1            ← Script gửi tin nhắn vào Server B
├── setup_scheduler.ps1         ← Setup Task Scheduler (chạy 1 lần)
├── last_run.txt                ← Lưu thời điểm export gần nhất
└── bot.py                      ← Bot Discord (tùy chọn)
```

---

## Xử lý sự cố

**Export không chạy tự động:**
- Kiểm tra Task Scheduler: `taskschd.msc` → tìm `DiscordSummarizer-*`
- Chạy thủ công: `Start-ScheduledTask -TaskName "DiscordSummarizer-9AM"`
- Đảm bảo máy bật và có mạng đúng giờ

**Lỗi `forbidden` khi export:**
- Tài khoản không có quyền đọc kênh đó — bình thường, script bỏ qua

**Token hết hạn:**
- Lấy lại token theo Bước 3 và cập nhật `.env`

**Không nhận được tin nhắn trên Server B:**
- Kiểm tra `SERVER_B_WEBHOOK_URL` trong `.env`
- Chạy test: `powershell -ExecutionPolicy Bypass -File post_webhook.ps1 -Message "test"`

---

## Lưu ý bảo mật

- File `.env` chứa token Discord — **không chia sẻ, không commit lên git**
- Token Discord = mật khẩu tài khoản, ai có token có thể đăng nhập thay bạn
- Nếu token bị lộ: đổi mật khẩu Discord ngay (token sẽ tự hết hạn)
