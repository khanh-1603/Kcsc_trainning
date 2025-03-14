# Tính số fibonacci thứ 100
**Nói sơ qua về thuật toán:**

thuật toán như sau:
```cpp
d = a            
a= a + b         
b = d 
```
a là số fibo thứ n, b là số fibo thứ n-1.

Để có số fibo tiếp theo ta cộng a với b nhưng như thế sẽ là mất giá trị cũ của a. Vì thế ta sử dụng d để lưu giá trị cũ của a và gán cho b sau khi cộng.

[Danh sách 100 số fibonacci](https://miniwebtool.com/list-of-fibonacci-numbers/?number=101)

![fibo100](https://hackmd.io/_uploads/By8d2KOoye.png)

Số này quá lớn 3.5x10^20^ khoảng 2^69^. Có nghĩa là cần tới 69 bit để chứa nó nên ta phải tạo 1 vùng nhớ tối thiểu 9 byte.
```assembly
include Irvine32.inc

.data
a TBYTE  0		                ; bien 10 byte - 80 bit du de chua fibo100
b TBYTE  0
d TBYTE  0
sochia dw 16	                        ; so 16 de chuyen fibo100 sang hex string
fibo100 db 30 DUP(0)			; hex string
byte_trung_gian db 0			; bien ho tro dao chuoi
```

Ta đang dùng `masm x86` nên các lệnh của nó chỉ dành cho 4 byte. Do đó phải thao tác với từng phần của biến 10 byte.

Đầu tiên khởi tạo giá trị a=1, b=0, c=2.
```
.code
main proc
    mov	    ebp, esp
    mov	    ecx, 2			 ; i = 2

    mov	    WORD PTR [a], 1		 ; mov 2 byte dau cua a = 1
    mov	    DWORD PTR [a+2], 0		 ; mov 4 byte giua cua a = 0
    mov	    WORD PTR [a+6], 0		 ; mov 4 byte cuoi cua a = 0

    mov	    WORD PTR [b], 0			
    mov	    DWORD PTR [b+2], 0			
    mov	    WORD PTR [b+6], 0
```
Sau đó ta sẽ lặp thuật toán cộng.

Masm không hỗ trợ cộng trực tiếp các biến nên em lưu giá trị vào thanh ghi rồi mới cộng
- add là cộng bit bình thường. adc là cộng bit có cộng thêm cờ CF
```
    xor	    eax, eax			 ; lam sach cac bien truoc khi cộng 
    xor	    ebx, ebx
    xor	    edx, edx
    lea	    esi, [a]			 ; luu esi = OFFFSET a de xem vi tri a

for_fibo:
    mov	    ax, WORD PTR [a]     	 ; eax = 2 byte dau cua a
    mov	    ebx, DWORD PTR [a+2]	 ; ebx = 4 byte giua cua a
    mov     edx, DWORD PTR [a+6]	 ; edx = 4 byte cuoi cua a

    mov	    WORD PTR [d], ax		 ; d = a
    mov	    DWORD PTR [d+2], ebx						
    mov	    DWORD PTR [d+6], edx						

    add	    ax, WORD PTR [b]		 ; cong 2 byte dau cua b voi eax
    adc	    ebx, DWORD PTR [b+2]	 ; cong 4 byte giua cua b voi ebx va Carry Flag o tren
    adc	    edx, DWORD PTR [b+6]	 ; cong 4 byte cuoi cua b voi edx va Carry Flag o tren

    mov	    WORD PTR [a], ax  		 ; a = a + b
    mov	    DWORD PTR [a+2], ebx						
    mov	    DWORD PTR [a+6], edx
	
    mov	    ax, WORD PTR [d]		 ; eax = 2 byte dau cua d
    mov	    ebx, DWORD PTR [d+2]	 ; ebx = 4 byte giua cua d
    mov     edx, DWORD PTR [d+6]	 ; edx = 4 byte cuoi cua d

    mov	    WORD PTR [b], ax		 ; b = d
    mov	    DWORD PTR [b+2], ebx						 
    mov	    DWORD PTR [b+6], edx						 

    inc	    ecx
    cmp	    ecx, 100
    jle	    for_fibo					
```
Khi lặp đủ 98 lần ta được số fibo100

 Số fibo100
 
![fibo100hex](https://hackmd.io/_uploads/Skfop5dskl.png)

![fibo100dectohex](https://hackmd.io/_uploads/B14oa9ujyx.png)

Việc tiếp theo là in số. Ta không thể in bình thường được vì các lệnh không hỗ trợ biến 10 byte.

Do đó ta cần chuyển số sang dạng string. Em xin phép được chuyển sang dạng hex string vì em không biết cách chuyển sang dạng dec string

Trước khi chuyển em đếm số byte của fibo100
```
    mov	    BYTE PTR [a+10], 0		 ; dat ket thuc chuoi
    mov	    ecx, 0			 ; phan tu dem

dem_PT:
    xor	    eax, eax			 ; lam sach eax sau moi vong lap
    mov	    al, BYTE PTR [a+ecx]	 ; eax = tung byte 1 cua fibo100
    inc	    ecx
    test    eax, eax			 ; kiem tra phan tu cuoi
    jnz	    dem_PT

    xor	    ebx, ebx			 ; lam sach ebx
    dec	    ecx				 ; bo phan tu 0
```
Thang ghi sẽ lưu theo kiểu little endian: lưu byte thấp trước byte cao sau nên thứ tự chữ số bị đảo lộn theo từng byte.

Thế nên em lấy byte từ cuối lên đầu.

Phương pháp chuyển là chia lấy dư cho 16 sau đó kiểm tra giá trị và gán ký tự phù hợp.

Khi chia bit cao sẽ là phần dư edx, bit thấp là phần thương eax. 

Nếu tạo hàm đổi ký tự cho từng thanh ghi thì hơi mất thời gian nên em chia 1 byte cho 16 2 lần và lưu phần dư vào biến trung gian rồi đảo vị trí.

```
fibo_hex:
    dec	    ecx
    mov	    al, BYTE PTR [a+ecx]	 ; lay phan tu cuoi

div_loop:
    xor	    edx, edx			 ; lam sach edx
    div	    sochia			 ; chia cho 16
    cmp	    dl, 9			 ; neu dl < 10 thi chuyen sang he hex 0-9
    jle	    hex0_9
	
    cmp	    dl, 10			 ; neu dl >= 10 thi chuyen sang he hex A-F
    jge	    hexA_F

hex0_9:
    add	    edx, 30h			 ; chuyen sang he hex 0-9
    test    eax, eax			 ; kiem tra da chia het chua
    jnz	    dao_trong_1byte
	
    mov	    fibo100[ebx], dl		 ; luu pt dau cua byte vao mang fibo100
    inc	    ebx
    push    ecx
    mov	    cl, [byte_trung_gian]
    mov	    fibo100[ebx], cl		 ; luu pt cuoi cua byte vao mang fibo100
    inc	    ebx
    pop	    ecx
    test    ecx, ecx			 ; kiem tra chuoi het chua
    jz	    in_fibo
	
    jmp	    fibo_hex

hexA_F:
    add	    edx, 37h			 ; chuyen sang he hex A-F
    test    eax, eax			 ; kiem tra da chia het chua
    jnz	    dao_trong_1byte

    mov	    fibo100[ebx], dl	 	 ; luu pt dau cua byte vao mang fibo100
    inc	    ebx
    push    ecx
    mov	    cl, [byte_trung_gian]
    mov	    fibo100[ebx], cl		 ; luu pt cuoi cua byte vao mang fibo100
    inc	    ebx
    pop	    ecx
    test    ecx, ecx			 ; kiem tra chuoi het chua
    jz	    in_fibo
	
    jmp	    fibo_hex

dao_trong_1byte:
    mov	    [byte_trung_gian], dl	 ; luu phan tu cuoi cua byte vao bien trung gian
    jmp	    div_loop
```
Bước cuối ta chỉ cần gán địa chỉ chuỗi vào edx và in ra
```
in_fibo:
    lea	    edx, [fibo100]
    call    WriteString
    push    0
    call    ExitProcess

    main    endp
end main
```
**Kết quả:**

 ![Capture](https://hackmd.io/_uploads/SytSg8YoJe.png)
 ![fibo100dectohex](https://hackmd.io/_uploads/B14oa9ujyx.png)

# Tạo 1 cửa sổ chứa 2 text box, 1 input, 1 output với chuỗi lộn ngược

Thư viện em import
```
includelib C:\masm32\lib\kernel32.lib
include C:\masm32\include\kernel32.inc
includelib C:\masm32\lib\gdi32.lib
include C:\masm32\include\gdi32.inc
includelib C:\masm32\lib\user32.lib
include C:\masm32\include\user32.inc
```
Em khai báo cái kiểu dữ liệu liên quan
```
WNDCLASS STRUCT
  style           DWORD ?
  lpfnWndProc     DWORD ?
  cbClsExtra      DWORD ?
  cbWndExtra      DWORD ?
  hInstance       DWORD ?
  hIcon           DWORD ?
  hCursor         DWORD ?
  hbrBackground   DWORD ?
  lpszMenuName    DWORD ?
  lpszClassName   DWORD ?
WNDCLASS ENDS

MSG STRUCT
    hwnd    DWORD ?    
    message DWORD ?    
    wParam  DWORD ?    
    lParam  DWORD ?   
    time    DWORD ?    
    ptX     DWORD ?    
    ptY     DWORD ?    
MSG ENDS
```
Khai báo các biến
```
.data
wc WNDCLASS <?>							; bien cua lop cua so
msg1 MSG <?>							; bien cua cau truc message
class_name db "MyClass", 0					; ten lop cua so
window_title db "Dao chuoi", 0					; tieu de cua so
hWnd1 dd ?							; handle chinh cua cua so
WS_OVERLAPPEDWINDOW equ WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX 
hWndInput dd ?                            		  	; Handle cho textbox nhap chuoi
hWndOutput dd ?                             			; Handle cho textbox hien thi chuoi dao nguoc
editClass db "EDIT", 0                      			; lop cua TextBox
button db "BUTTON", 0                       			; nut
buttontext db "cancel", 0                   
msgloi1 db "Khong the dang ky lop cua so", 0
msgloi2 db "Khong the tao cua so", 0
```
Khởi đầu bằng việc khai báo hàm WinMain

`WinMain PROC hInstance:DWORD, hPrevInstance:DWORD, lpCmdLine:DWORD, nCmdShow:DWORD`

Dùng WinMain là phù hợp khi tạo các ứng dụng và cửa sổ

Đầu tiên em đăng ký lớp của sổ cho cửa sổ cha
```
    mov     wc.style, 1 or 2                        ; style = CS_HREDRAW or CS_VREDRAW
    mov     wc.lpfnWndProc, offset WndProc          ; dia chi cua ham xu ly cua so
    mov     wc.cbClsExtra, 0                        
    mov     wc.cbWndExtra, 0

    push    0
    call    GetModuleHandleA
    mov     wc.hInstance, eax                       ; handle cua chuong trinh

    push    7F00h
    push    0
    call    LoadIconA
    mov     wc.hIcon, eax                           ; icon cua so

    push    7F00h
    push    0
    call    LoadCursorA
    mov     wc.hCursor, eax                         ; con tro chuot cua so

    mov     wc.hbrBackground, 5h                    ; mau nen cua so
    mov     wc.lpszMenuName, 0                      ; khong co menu
    mov     wc.lpszClassName, offset class_name     ; ten lop cua so

    lea     esi, wc                                 ; dia chi cua wc
    push    esi
    call    RegisterClassA                          ; dang ky lop cua so

    cmp     eax, 0
    je      loi1                                    ; thong bao loi khong dang ky duoc lop cua so
```
Sau đó em tạo 4 của sổ gồm: cửa sổ chính, 2 textbox, 1 nút
```
; tao cua so cha
    push    0                              ; lpParam = NULL
    push    wc.hInstance                   ; hInstance
    push    0                              ; hMenu = NULL
    push    0                              ; hWndParent = NULL
    push    200                            ; window_height
    push    400                            ; window_width
    push    80000000h                      ; y default
    push    80000000h                      ; x default
    push    0C00000h                       ; window style; overlapped window
    push    offset window_title            ; window title
    push    offset class_name              ; window class name
    push    0                              ; exWinStyle default
    call    CreateWindowExA

    mov     hWnd1, eax
    cmp     hWnd1, 0
    je      loi2                            ; thong bao loi khong tao duoc cua so

; tao textbox nhap chuoi
    push    0
    push    wc.hInstance
    push	101                         ; ID textbox input
    push    hWnd1                           ; cua so cha
    push    25                              ; textbox hight
    push    350                             ; textbox width
    push    20                              ; y
    push    20                              ; x
    push    50810080h   
    push    0
    push    offset editClass                ; lop cua TextBox
    push    0                               ; exstyle cua TextBox la default
    call    CreateWindowExA
    mov     hWndInput, eax                  ; luu handle cua textbox input

; tao textbox hien thi ket qua
    push    0
    push    wc.hInstance
    push	102                         ; ID textbox output
    push    hWnd1
    push    25                              ; textbox hight
    push    350                             ; textbox width
    push    60                              ; y
    push    20                              ; x
    push    50800880h 
    push    0
    push    offset editClass
    push    0
    call    CreateWindowExA
    mov     hWndOutput, eax                 ; luu handle cua textbox output

; tao 1 nut thoat
    push    0
    push    wc.hInstance
    push    103                             ; ID
    push    hWnd1
    push    25                              ; button height
    push    100                             ; button width
    push    100                             ; y
    push    150                             ; x
    push    50010000h
    push    offset buttontext		    ; tieu de nut
    push    offset button		    ; lop button
    push    0
    call    CreateWindowExA
```
Sau khi tạo xong ta cần dùng hàm `ShowWindow` để hiện cửa sổ và `UpdateWindow` để cập nhật lại cửa sổ cha. Sau cập nhật của sổ cha sẽ có 2 textbox và 1 nút
```
    push    5h				; CMD_SHOW
    push    hWnd1
    call    ShowWindow

    push    hWnd1
    call    UpdateWindow
```
Hàm báo lỗi em dùng `MessageBox`
```
loi1:
    push    0
    push    offset window_title
    push    offset msgloi1
    push    0
    call    MessageBoxA
    jmp     end_loop
```
Tương tự với loi2

Hàm end_loop em dùng `ExitProcess`
```
 end_loop:
    push    0
    call    ExitProcess
WinMain endp
end WinMain
```
Em tạo 1 messageloop để liên tục cập nhật cửa sổ
```
 msg_loop:
    lea     edi, msg1
    push    0
    push    0
    push    0 
    push    edi 
    call    GetMessageA			; tao message

    cmp     eax, 0
    jle     end_loop

    push    edi
    call    TranslateMessage		; chuyen cac thong diep ban phim thanh thong diep ky tu
    push    edi
    call    DispatchMessageA		; gui message cho WndProc
    jmp     msg_loop
```
Như vậy là xong WinMain

Em tạo 1 hàm WndProc để xử lý các luồng trên cửa sổ.
`WndProc proc, hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD`

Có 3 sự kiện
- Tạo cửa sổ
- Nhập chuỗi
- Bấm nút

  Đầu tiên em sẽ kiểm tra các thao tác trên cửa sổ bằng `WM_COMMAND`.
  `WM_COMMAND` là một thông điệp `(message)` trong WinAPI khi người dùng thực hiện một số hành động trên cửa sổ như nhập hay bấm nút
```
    mov eax, uMsg
    cmp uMsg, 111h                  ; kiem tra su kien WM_COMMAND
    je nhap_du_lieu                 ; neu dung thi xu ly nhap lieu
    
    jmp defaultwindow
```
Nếu có thao tác em sẽ kiểm tra xem là bấm nút hay nhập.
- Nếu là nhập em sẽ cấp 1 vùng nhớ 256 byte trên stack
- Nếu là bấm nút em sẽ làm sạch stack và thoát.
```
    nhap_du_lieu:
    sub esp, 256                     ; cap phat bo nho cho buffer
    mov edi, esp                     ; edi tro den buffer
    mov ebx, wParam
    and ebx, 0FFFFh                  ; lay LOWORD(wParam) -> ID cua control
    cmp ebx, 101                     ; kiem tra co phai la ID cua textbox nhap chuoi
    je  xu_ly

    add esp, 256
    cmp ebx, 103             	     ; neu bam nut thi thoat
    je thoat

    jmp defaultwindow

thoat:
    push 0
    call PostQuitMessage	    ; tra ve WM_QUIT de ket thuc messageloop 
    xor eax, eax
    ret

xu_ly:
    mov eax, wParam
    shr eax, 16                     ; lay HIWORD(wParam) -> su kien cua control
    cmp eax, 0300h                  ; kiem tra co phai la EN_CHANGE
    jne defaultwindow

    push 256                        ; so ky tu toi da cua chuoi
    push edi                        ; dia chi cua buffer
    push hWndInput                  ; Handle cua texbbox
    call GetWindowTextA             ; lay chuoi tu textbox

    cmp eax, 1                      ; kiem tra chuoi rong hoac co 1 ky tu
    jle defaultwindow

    mov ecx, eax                    ; luu lai do dai cua chuoi
    dec ecx                         ; giam thanh index dem nguoc
    mov ebx, 0                      ; index dau tien
dao_loop:

    mov al, [edi + ebx]             ; lay ky tu dau
    mov ah, [edi + ecx]             ; lay ky tu cuoi

    mov [edi + ebx], ah             ; doi vi tri
    mov [edi + ecx], al

    inc ebx
    dec ecx
    cmp ebx, ecx                    ; kiem tra xem da dao het chuoi chua
    jl  dao_loop                    ; lap lai neu chua
    
    push edi                        ; dia chi cua chuoi
    push hWndOutput                 ; handle cua textbox output
    call SetWindowTextA             ; hien thi chuoi
    add esp, 256                    ; giai phong bo nho
    ret
```
Em cho các sự kiện khác vào hàm `DefWindowProc`. Hàm này là hàm xử lý mặc định của WinAPI.
Em dùng invoke vì call nó không hoạt động
```
defaultwindow:
    invoke DefWindowProcA, hWnd, uMsg, wParam, lParam
    ret
WndProc endp
```
Luồng chương trình như sau:

Tạo cửa sổ cha có sử dụng lớp cửa sổ do em đăng ký. Lớp này có trỏ đến hàm `WndProc`. Nếu hàm này code lỗi thì cửa sổ sẽ không được tạo. 

Sau khi ta thao tác với cửa sổ con (textbox input hay nút) thì `GetMessage` sẽ lấy thông điệp, `TranslateMessage` sẽ chuyển thông điệp bàn phím sang thông diệp ký tự.
`DispatchMessage` sẽ chuyển thông điệp này đến `WndProc` và hàm này xử lý các thông điệp đó. `Messageloop` sẽ loop vô tận nếu ta không bấm `cancel`.

Kết quả:

![Capture1](https://github.com/user-attachments/assets/9f699afa-f674-4e55-a09a-711731c81165)

![Capture2](https://github.com/user-attachments/assets/a6dd4f15-1c0d-4699-99f5-ce3077eb3675)

