# Discord Summarizer — Claude Instructions

## Khi người dùng gõ "tóm tắt mới nhất" (hoặc tương tự)

Thực hiện đúng thứ tự sau, không bỏ bước nào:

1. Tìm thư mục export mới nhất trong `exports/` (sort theo tên, lấy folder cuối cùng)
2. Đọc tất cả file `.txt` trong thư mục đó (song song)
3. Bỏ qua file có `Exported 0 message(s)`
4. Tóm tắt nội dung theo từng kênh có hoạt động
5. **Bắt buộc: gửi tóm tắt lên Discord** bằng lệnh:

```powershell
powershell -ExecutionPolicy Bypass -File post_webhook.ps1 -Message "<nội dung tóm tắt>"
```

> Script phải chạy từ thư mục chứa `post_webhook.ps1` (cùng thư mục với CLAUDE.md này).
> Webhook URL được đọc tự động từ `.env` — không cần truyền thêm tham số.

**Không được chỉ hiển thị tóm tắt trong chat mà không gửi Discord.**

## Model — ưu tiên tiết kiệm token

Tác vụ tóm tắt Discord là việc lặp lại hằng ngày (3 lần/ngày), nên **luôn ưu tiên model rẻ/nhẹ nhất đủ tốt là Haiku** để tiết kiệm token/hạn mức.

- Model dùng: **`claude-haiku-4-5-20251001`** (Haiku 4.5).
- Khi chạy thủ công bằng `claude` CLI, thêm cờ: `--model claude-haiku-4-5-20251001`.
- Chỉ nâng lên model mạnh hơn nếu người dùng yêu cầu rõ ràng chất lượng cao hơn.

## Luồng tự động (Task Scheduler)

Hệ thống chạy tự động 9h/12h/18h qua `auto_summarize.ps1` (Task Scheduler gọi):

1. `export_daily.ps1` — export tin nhắn mới ra `exports/<timestamp>/`
2. Gọi `claude -p` với **model Haiku**, prompt yêu cầu **chỉ in ra tóm tắt** (KHÔNG tự gọi webhook — vì claude headless bị chặn hành động gửi mạng).
3. `auto_summarize.ps1` (PowerShell thuần) hứng text đó rồi gọi `post_webhook.ps1` gửi Discord.

> Lý do tách vai: claude headless không được phép gửi webhook ra mạng (bị lớp an toàn chặn, không có ai bấm Approve). Nên claude chỉ sinh text, PowerShell lo việc gửi. Wrapper cũng tự chặn không gửi nếu claude trả về thông báo lỗi/hết hạn mức.
> Log & bản tóm tắt sạch (UTF-8) lưu ở `logs/`.
