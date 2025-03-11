# Tính số fibonacci thứ 100
## Code
```assembly
include Irvine32.inc

.data
a TBYTE  0		                ; bien 10 byte - 80 bit du de chua fibo100
b TBYTE  0
d TBYTE  0
sochia dw 16	                        ; so 16
fibo100 db 30 DUP(0)
byte_trung_gian db 0

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

for_fibo:
    xor	    eax, eax
    xor	    ebx, ebx
    xor	    edx, edx
    lea	    esi, [a]			 ; luu esi = OFFFSET a de xem vi tri a

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

    lea	    esi, [a]			 ; luu esi = OFFFSET a de xem vi tri a
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

in_fibo:
    lea	    edx, [fibo100]
    call    WriteString
    push    0
    call    ExitProcess

    main    endp
end main
```
## Giải thích code
[Danh sách 100 số fibonacci](https://miniwebtool.com/list-of-fibonacci-numbers/?number=101)

![fibo100](https://hackmd.io/_uploads/By8d2KOoye.png)
### Giải thích đoạn khai báo biến
```assembly
.data
a TBYTE  0                             ; bien 10 byte de chua fibo100
b TBYTE  0
d TBYTE  0
sochia dw 16	                        ; so 16
fibo100 db 30 DUP(0)
byte_trung_gian db 0
```
- Số này quá lớn 3.5x10^20^ < 2^69^. Có nghĩa là cần tới 69 bit để chứa nó nên ta phải tạo 1 vùng nhớ tối thiểu 9 byte
- `TBYTE` là khai báo biến 10 byte
- `sochia` ở dạng int để sau còn chuyển kết quả sang dạng string hex
- `fibo100` là nơi lưu chuỗi hex
- `byte_trung_gian` để tách 4 bit của đoạn hex 1 byte
- 
### Giải thích thuật toán
thuật toán như sau:
```cpp
// a là fibo thứ n, b là fibo thứ n-1
d = a            
a= a + b         
b = d 
```
Ta đang dùng `masm x86` nên các lệnh của nó chỉ dành cho 4 byte. Do đó phải thao tác với từng phần của biến 10 byte.

Khi bị bị tràn thì thanh ghi được sử dụng sẽ chỉ lấy n bit cuối như `ax` sẽ lấy 16 bit, `ebx` lấy 32 bit. Phần trần sẽ không được lưu lại nhưng `cờ CF sẽ = 1`. Ví dụ:

![testoverflow](https://hackmd.io/_uploads/B15zwcdiye.png)  ![testoverflow2](https://hackmd.io/_uploads/B1sGv5OsJl.png)
- `eax = 0xffffffff` khi cộng với chính nó sẽ ra 0x1fffffffe
- `eax` đã giữ lại 32 bit cuối -> mất bit thứ 33 là số 1

Vì vậy ta cần sử dụng lệnh `adc` - cộng có nhớ hay cộng với cờ CF

Sau khi tạo được thuật toán ta kiểm tra bằng debug:
- Số fibonacci thứ 24 là 46368. Đây là giới hạn của thanh ghi ax. Chuyển sang dạng hex là 0xb520

![tràn 1,5](https://hackmd.io/_uploads/rkkfO5Os1x.png)

- Số fibonacci thứ 25 là 75025 ~ 0x12511

![tràn 2,5](https://hackmd.io/_uploads/SydzucOj1l.png)
:::info
:information_source:Thang ghi sẽ lưu theo kiểu little endian: lưu byte thấp trước byte cao sau nên thứ tự chữ số bị đảo lộn theo từng byte
:::
 Code của em đã chính xác.
 
 ### Giải thích đoạn chuyển sang string
 Khi được số fibo100 ta cần phải in nó ra. Nhưng hàm `WriteDec` sẽ chỉ in số trong eax. Thanh ghi này không đủ lớn nên ta cần chuyển nó thành 1 mảng ký tự.

 Số fibo100
 
![fibo100hex](https://hackmd.io/_uploads/Skfop5dskl.png)

![fibo100dectohex](https://hackmd.io/_uploads/B14oa9ujyx.png)

Để chuyển sang dạng chuỗi số thì rất phức tạp và em cũng không biết cách làm nên em sẽ chỉ chuyển sang dạng chuỗi hex.

**Hàm fibo_hex:**
- Ta lấy phần tử của mảng a theo chiều từ phải sang trái.
- Sau đó chia cho 16. Phần dư sẽ lưu vào edx. 
    - Nếu edx <10 thì nhảy vào hàm `hex0_9` nơi sẽ chuyển edx sang dạng char từ 0->9
    - Nếu edx >=10 thì nhảy vào hàm `hexA_F` tương tự hàm `hex0_9`
    - 2 hàm trên chỉ khác nhau phần cộng để chuyển sang dạng char còn lại y như nhau. 2 Hàm sẽ gán `edx` vào chuỗi fibo100 theo đúng thứ tự.
    - Cuối 2 hàm, ta kiểm tra xem chuỗi a đã chạy đến hết phần tử đầu chưa. Chưa thì nhảy lên `fibo_hex`.
    - Hàm `đảo_trong_1byte` đơn giản là lưu lại 4 bit cuối của 1 byte để thêm vào chuỗi fibo100 cho đúng thứ tự

**Kết quả:**

 ![Capture](https://hackmd.io/_uploads/SytSg8YoJe.png)

# Tạo 1 cửa sổ chứa 2 text box, 1 input, 1 output với chuỗi lộn ngược
## Hướng làm như sau:
- Tạo 1 cửa sổ cha, và 2 cửa sổ con. 1 cái cho input, 1 cho output. Ta sẽ dùng `CreateWindowExA`.
- Đăng ký lớp của sổ cho cửa sổ cha ta dùng `RegisterClassA`. Hàm này sẽ giúp ta tạo 1 lớp cửa sổ theo mong muốn.
    - Lớp của sổ của con là `EDIT`. (có sẵn)
    - Lớp của cha là tự tạo.
- Trong quá trình đăng ký lớp ta cần quan tâm đến biến thành viên `lpfnWndProc` của `WNDCLASS STRUCT`. Đây là con trỏ trỏ đến hàm thủ tục trên của sổ, là cốt lõi của cửa sổ.
- Hàm thủ tục trên cửa sổ `WndProc`. Hàm này có vai trò phản hồi lại các sự kiện diễn ra trên cửa sổ chính.
- Tạo 1 hàm để đảo chuỗi ở cửa sổ input và in ra ở output. `WndProc` sẽ sử dụng hàm này.
- Để hiện cửa sổ dùng `ShowWindow`. Để cửa sổ in luôn ra output ta dùng `UpdateWindow`.
- Tạo message cho hWndProc `xử lý`

### Bước 1: Tạo lớp của sổ
Đầu tiên là tạo 1 biến lớp cửa sổ wc.

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
```
```
.data
wc WINCLASS <?>                                  ; bien lop cua so
class_name db "My class", 0                      ; ten lop cua so
window_title db "Dao chuoi", 0			   ; tieu de cua so
msgloi1 db "Khong the dang ky lop cua so", 0     ; bao loi

.code
    mov     wc.style, 1 or 2                     ; style = CS_HREDRAW or CS_VREDRAW
    mov     wc.lpfnWndProc, offset WndProc       ; dia chi cua ham xu ly cua so 
    mov     wc.cbClsExtra, 0
    mov     wc.cbWndExtra, 0

    push    0
    call    GetModuleHandleA                     ; lay handle
    mov     wc.hInstance, eax                    ; handle cua chuong trinh

    push    IDI_APPLICATION
    push    0
    call    LoadIconA
    mov     wc.hIcon, eax                        ; icon cua so

    push    IDC_ARROW
    push    0
    call    LoadCursorA
    mov     wc.hCursor, eax                      ; con tro chuot cua so

    mov     wc.hbrBackground, COLOR_WINDOW       ; mau nen cua so
    mov     wc.lpszMenuName, 0                   ; khong co menu
    mov     wc.lpszClassName, offset class_name  ; ten lop cua so
```
Sau đó đơn giản chỉ cần `call RegisterClassA` và thêm hàm báo lỗi nếu không đăng ký được lớp của sổ là xong. Hàm lỗi dùng `MessageBoxA`
```
    lea     esi, wc                              ; dia chi cua wc
    push    esi
    call    RegisterClassA                       ; dang ky lop cua so
    cmp     eax, 0
    je      loi1                                 ; thong bao loi 
```
```
loi1:
    push    0                                    ; MB_OK
    push    offset window_title                  ; tieu de cua so
    push    offset msgloi1                       ; text
    push    0                                    ; con tro hWnd
    call    MessageBoxA
    jmp     end_loop                             ; nhay den ket thuc main
```

### Bước 2: Tạo cửa sổ
```
CreateWindowExA PROTO,	; create and register a window class
	exWinStyle:DWORD,
	className:PTR BYTE,
	winName:PTR BYTE,
	winStyle:DWORD,
	X:DWORD,
	Y:DWORD,
	rWidth:DWORD,
	rHeight:DWORD,
	hWndParent:DWORD,
	hMenu:DWORD,
	hInstance:DWORD,
	lpParam:DWORD
```
Tạo của sổ cha
```
.data
msgloi2 db "Khong the tao cua so", 0
hWnd1 dd ?     		            ; handle chinh cua cua so
hWndInput dd ?                              ; Handle cho textbox nhap chuoi
hWndOutput dd ?                             ; Handle cho textbox hien thi chuoi dao nguoc

.code
    push    0                              ; lpParam = NULL
    push    wc.hInstance                   ; hInstance
    push    0                              ; hMenu = NULL
    push    0                              ; hWndParent = NULL
    push    200                            ; window_height
    push    400                            ; window_width
    push    CW_USEDEFAULT                  ; y
    push    CW_USEDEFAULT                  ; x
    push    WS_OVERLAPPEDWINDOW            ; window style
    push    offset window_title            ; window title
    push    offset class_name              ; window class name
    push    0                              ; exWinStyle
    call    CreateWindowExA

    mov     hWnd1, eax
    cmp     hWnd1, 0
    je      loi2                            ; thong bao loi khong tao duoc cua so
```
```
loi2:
    push    0
    push    offset window_title
    push    offset msgloi2
    push    0
    call    MessageBoxA
```
Tạo 2 của sổ con
```
; tao textbox nhap chuoi
    push    0
    push    wc.hInstance
    push    101                             ; ID
    push    hWnd1                           ; hWndParent
    push    25                              ; textbox hight
    push    350                             ; textbox width
    push    20                              ; y
    push    20                              ; x
    push    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL  
    push    0
    push    offset editClass                ; lop cua TextBox
    push    0                               ; exstyle cua TextBox la default
    call    CreateWindowExA
    mov     hWndInput, eax                  ; luu handle cua textbox input

; tao textbox hien thi ket qua
    push    0
    push    wc.hInstance
    push    102                             ; ID
    push    hWnd1                           ; hWndParent
    push    25                              ; textbox hight
    push    350                             ; textbox width
    push    60                              ; y
    push    20                              ; x
    push    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL or ES_READONLY 
    push    0
    push    offset editClass
    push    0
    call    CreateWindowExA
    mov     hWndOutput, eax                 ; luu handle cua textbox output
```
3 cửa sổ có chung 1 handle của chương trình là `wc.hInstance`

Cửa sổ cha có style là `WS_OVERLAPPEDWINDOW`. 

Của cửa sổ input có `WS_CHILD` (cửa sổ con- giờ trở thành 1 textbox). 

Của cửa sổ output có thêm `ES_READONLY` là style của lớp `EDIT`, chỉ cho phép đọc.

Ngoài ra 2 cửa sổ con phải có ID để `hWndProc` nhận biết và phải có cửa sổ cha (`hWnd1` là con trỏ trỏ đến handle của cửa sổ cha).

### Bước 3: ShowWindow, UpdateWindow và xử lý message
```
.data
msg MSGStruct <?>		    ; bien cua thong diep

.code
    push    SW_SHOW                
    push    hWnd1
    call    ShowWindow

    push    hWnd1
    call    UpdateWindow

    msg_loop:                    ; vong lap xu ly thong diep
    lea     edi, msg
    push    0
    push    0
    push    0                    ; lay thong diep toan bo chuong trinh
    push    edi                  ; con tro tro den bien thong diep
    call    GetMessageA          ; tao thong diep
    cmp     eax, 0
    je      end_loop

    push    edi
    call    DispatchMessageA     ; gui thong diep den WndProc
    jmp     msg_loop
```
```
GetMessageA PROTO,
	lpMsg:PTR BYTE,
	hWnd:DWORD,
	firstMsg:DWORD,
	lastMsg:DWORD
```

### Bước 4: Tạo WndProc để xử lý luồng
```
WndProc proc, hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    cmp uMsg, WM_COMMAND      ; kiem tra su kien WM_COMMAND
    je nhap_du_lieu           ; neu dung thi xu ly nhap lieu

    cmp uMsg, WM_CLOSE        ; neu la su kien dong cua so
    je thoat

    push hWnd
    push uMsg
    push wParam
    push lParam
    call DefWindowProcA        ; goi ham xu ly cua so mac dinh
    ret

nhap_du_lieu:

dao_chuoi:

thoat:
    push 0
    call PostQuitMessage       ; thoat cua so
    xor eax, eax
    ret
WndProc endp

```

## Code
