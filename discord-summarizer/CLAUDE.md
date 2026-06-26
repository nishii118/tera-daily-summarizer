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
