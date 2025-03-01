# Giải thích sơ qua về calling convention được sử dụng:
Hầu hết hàm ở Win32 API sử dụng calling convention (giao thức gọi hàm) `stdcall`. `MessageBox` và `ExitProcess` cũng không ngoại lệ.

`stdcall`:

https://learn.microsoft.com/en-us/cpp/cpp/stdcall?view=msvc-170

- Cú pháp: return-type __stdcall function-name[( argument-list )]

- Khi sử dụng `stdcall`, hàm gọi(caller) sẽ push giá trị của các đối số vào stack. Hàm được gọi (callee) pop các tham số của nó trên stack theo thứ tự từ phải sang trái do stack hoạt động theo cơ chế LIFO. Callee có trách nghiệm làm sạch stack.

- `stdcall` chỉ phổ biến ở kiến trúc x86.

- Ngoài ra trong stdcall thường sử dụng lệnh `ret n` sẽ làm tăng `esp` lên n byte để giải phóng các tham số trên stack. Đây là cách callee làm sạch stack.
# Trở lại với đoạn code:

![Capture](https://github.com/user-attachments/assets/682eeb7b-a1ba-4980-ae3a-174295fbbf5e)

Ta thực hiện đúng 2 lệnh đó là `invoke MessageBox` và `invoke ExitProcess`
Nhưng khi ta debug bằng ida 

![Capture2](https://github.com/user-attachments/assets/3d5564c2-edb8-4ff5-a2af-9a718cd1f7e6)

Hàm `main` xuất hiện các lệnh push, pop và call. Như vậy, ta đã thấy sự khác nhau cơ bản giữa 2 lệnh gọi hàm. `Call` yêu cầu caller phải thủ công push các đối số vào stack trong khi `invoke` tự động thực hiện tiến trình này.

## Khi debug:
![Capture7](https://github.com/user-attachments/assets/8e250b44-8df9-4a40-a908-2c67cb62c570)


![Capture8](https://github.com/user-attachments/assets/a0a33a90-ac40-4c43-ae97-3c62e22b5ba5)


![Capture9](https://github.com/user-attachments/assets/af88d33a-eab6-4a90-a283-4b8183e886f9)

Có 2 sự thay đổi ta cần quan tâm. 
- Ở stack có chứa các đối số và địa chỉ của dòng lệnh.
- Thanh ghi `eax`, `ecx`, `edx`, `eip`, `esp` thay đổi giá trị.

Vậy là `call` và `invoke` tự động push `[eip +4]` chứa địa chỉ bên dưới vào stack. 

Vì ta đang bàn luận về calling convention nên em sẽ nói ngắn gọn về cách hoạt động của callee.
- Callee tạo 1 stack frame để lưu lại địa chỉ trước đó sau đó mới pop các đối số và thực hiện chức năng của hàm.
- Sau đó giải phóng stack frame và push lại địa chỉ.
- Lệnh `ret` sẽ làm 2 việc. 1 là `pop eip` để lấy lại địa chỉ trả vể và 2 là tăng `esp`.
- Giá trị trả về được lưu ở eax.

Với sự thay đổi của thanh ghi, ta có thể suy ra `eax` chứa giá trị trả về `ecx`, `edx` được callee sử dụng và `eip`, `esp` thay đổi để chương trình có thể chạy tiếp. 

## Tổng kết:
- Calling convention được sử dụng là stdcall.
- Khi sử dụng lệnh `call` hay `invoke` thì trên stack phải chứa các đối số. 2 lệnh sẽ tự động push `eip`.
- Khi trả về hàm thì dùng `ret`. `eip` sẽ nhảy về dòng dưới lệnh gọi hàm và tiếp tục thực thi chương trình.
- Stack được callee làm sạch bằng lệnh `ret`.
