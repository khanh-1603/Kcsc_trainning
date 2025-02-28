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

Hàm main xuất hiện các lệnh push và pop

![Capture4](https://github.com/user-attachments/assets/60a5292d-e14b-4966-9f2b-3d78781a2fdf) ![Capture3](https://github.com/user-attachments/assets/ab20cc58-b8ea-45e9-b245-f3211b64a7fb)

Ta có thể thấy hàm `main` đã push các đối số vào stack.


![Capture5](https://github.com/user-attachments/assets/3ea8266d-4ece-45cb-8017-83df442e9e53) ![Capture6](https://github.com/user-attachments/assets/eeaf817e-6848-4c62-ad3b-c35f1a5b9936)

Sau khi gọi `MessageBoxA` stack xuất hiện thêm 1 dòng ở trên các đối số là địa chỉ của dòng ngay dưới lệnh call. Các đối số vẫn ở trong stack. Vậy là `MessageBoxA` đã pop rồi push lại các đối số đó. 

![Thanh ghi trước khi call](https://github.com/user-attachments/assets/ef701e2a-baf0-417c-913c-c460041b351e)        

Thanh ghi trước khi call

![Thanh ghi sau khi call](https://github.com/user-attachments/assets/9b13f508-9a86-41b6-9fb0-8745dd8cd1a1)   
Thanh ghi sau khi call

Thanh ghi `eax`, `ecx`, `edx`, `eip`, `esp` thay đổi giá trị.

## Tổng kết:
Caller push lần lượt các đối số lên stack, cuối cùng push địa chỉ dòng lệnh phía dưới lên stack và jump đến callee. Callee pop các đối số đó để làm tham số. Sau khi return, nó trả về giá trị tại eax đồng thời push lại các đối số. Callee jump trở lại caller bằng lệnh ret. Vị trí jump là địa chỉ được lưu trước đó.

