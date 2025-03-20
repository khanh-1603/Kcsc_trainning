# GetMessage(), TranslateMessage(), DispatchMessage():
Sau khi ta thao tác cửa sổ thì `GetMessage()` sẽ đọc các sự kiện (messages) từ hàng đợi thông điệp (message queue) của cửa sổ. `GetMessage()` chặn chương trình và chờ cho đến khi có thông điệp mới xuất hiện. Khi có thông điệp, nó lưu vào `lpMsg` và trả về `TRUE`.

`TranslateMessage()`  dùng để xử lý các thông điệp bàn phím (`WM_KEYDOWN`, `WM_KEYUP`) và chuyển đổi chúng thành thông điệp ký tự (`WM_CHAR`, `WM_DEADCHAR`). 

`DispatchMessage()` sẽ chuyển thông điệp này đến hàm xử lý thông điệp, `DispatchMessage()` không xử lý thông điệp. Do ta dùng handle của cửa sổ cha làm đối số nên hàm xử lý thông điệp là `WndProc`, có địa chỉ nằm ở `wc.lpfnWndProc`.

`Messageloop` sẽ loop vô tận nếu ta không bấm cancel.

# So sánh GetMessage() với PeekMessage():
Giống nhau:
- Đều đọc các sự kiện từ hàng đợi thông điệp của cửa sổ.
Khác nhau:
- GetMessage(): Chặn chương trình. Phù hợp để dùng trong vòng lặp xử lý thông điệp chính của ứng dụng WinAPI.
- PeekMessage(): Không chặn chương trình. Dùng khi cần kiểm tra hoặc xử lý thông điệp mà không chặn chương trình, như trong game hoặc đa luồng.
  
