# Giải thích sơ qua về calling convention được sử dụng:
Hầu hết hàm ở Win32 API sử dụng calling convention (giao thức gọi hàm) `stdcall`. `MessageBox` và `ExitProcess` cũng không ngoại lệ.

`stdcall`:

https://learn.microsoft.com/en-us/cpp/cpp/stdcall?view=msvc-170

- Cú pháp: return-type __stdcall function-name[( argument-list )]

- Khi sử dụng `stdcall`, hàm gọi(caller) sẽ push giá trị của các đối số vào stack. Hàm được gọi (callee) pop các tham số của nó trên stack theo thứ tự từ phải sang trái do stack hoạt động theo cơ chế LIFO. Callee có trách nghiệm làm sạch stack.

- `stdcall` chỉ phổ biến ở kiến trúc x86.

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

Ở stack có chứa các đối số và địa chỉ của dòng lệnh. Vậy là `call` và `invoke` tự động push địa chỉ bên dưới vào stack. Để pop được các đối số, callee phải pop địa chỉ trước tiên. Sử dụng phương pháp tạo stack frame, địa chỉ được giữ lại.

Thanh ghi `eax`, `ecx`, `edx`, `eip`, `esp` thay đổi giá trị.

## Tổng kết:
Caller push lần lượt các đối số lên stack, cuối cùng push địa chỉ dòng lệnh phía dưới lên stack và jump đến c
allee. Callee pop các đối số đó để làm tham số. Sau khi return, nó trả về giá trị tại eax đồng thời push lại các đối số. Callee jump trở lại caller bằng lệnh ret. Vị trí jump là địa chỉ được lưu trước đó.

