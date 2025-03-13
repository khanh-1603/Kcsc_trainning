.386
.model flat, stdcall


includelib C:\masm32\lib\kernel32.lib
include C:\masm32\include\kernel32.inc
includelib C:\masm32\lib\gdi32.lib
include C:\masm32\include\gdi32.inc
includelib C:\masm32\lib\user32.lib
include C:\masm32\include\user32.inc

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

.data
wc WNDCLASS <?>								; bien cua lop cua so
msg1 MSG <?>							; bien cua cau truc message
class_name db "MyClass", 0					; ten lop cua so
window_title db "Dao chuoi", 0				; tieu de cua so
hWnd1 dd ?									; handle chinh cua cua so
WS_OVERLAPPEDWINDOW equ WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX 
hWndInput dd ?                              ; Handle cho textbox nhap chuoi
hWndOutput dd ?                             ; Handle cho textbox hien thi chuoi dao nguoc
editClass db "EDIT", 0                      ; lop cua TextBox
button db "BUTTON", 0                       ; nut
buttontext db "cancel", 0                   
msgloi1 db "Khong the dang ky lop cua so", 0
msgloi2 db "Khong the tao cua so", 0

.code
WndProc proc, hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov eax, uMsg
    cmp uMsg, 111h         ; kiem tra su kien WM_COMMAND
    je nhap_du_lieu        ; neu dung thi xu ly nhap lieu
    
    jmp defaultwindow

    nhap_du_lieu:
    sub esp, 256              ; cap phat bo nho cho buffer
    mov edi, esp              ; edi tro den buffer
    mov ebx, wParam
    and ebx, 0FFFFh       ; lay LOWORD(wParam) -> ID cua control
    cmp ebx, 101          ; kiem tra co phai la ID cua textbox nhap chuoi
    je  xu_ly

    add esp, 256
    cmp ebx, 103           ; neu la nut thoat
    je thoat

    jmp defaultwindow
thoat:
    push 0
    call PostQuitMessage
    xor eax, eax
    ret

xu_ly:
    mov eax, wParam
    shr eax, 16           ; lay HIWORD(wParam) -> su kien cua control
    cmp eax, 0300h        ; kiem tra co phai la EN_CHANGE
    jne defaultwindow

    cmp  hWndInput, 0
    je   defaultwindow

    push 256                  ; so ky tu toi da cua chuoi
    push edi                  ; dia chi cua buffer
    push hWndInput            ; Handle cua texbbox
    call GetWindowTextA       ; lay chuoi tu textbox

    cmp eax, 1                ; kiem tra chuoi rong hoac co 1 ky tu
    jle defaultwindow

    mov ecx, eax              ; luu lai do dai cua chuoi
    dec ecx                   ; giam thanh index dem nguoc
    mov ebx, 0                ; index dau tien
dao_loop:

    mov al, [edi + ebx]       ; lay ky tu dau
    mov ah, [edi + ecx]       ; lay ky tu cuoi

    mov [edi + ebx], ah       ; doi vi tri
    mov [edi + ecx], al

    inc ebx
    dec ecx
    cmp ebx, ecx              ; kiem tra xem da dao het chuoi chua
    jl  dao_loop              ; lap lai neu chua
    
    push edi                  ; dia chi cua chuoi
    push hWndOutput            ; handle cua textbox output
    call SetWindowTextA        ; hien thi chuoi
    add esp, 256              ; giai phong bo nho
    ret

defaultwindow:
    invoke DefWindowProcA, hWnd, uMsg, wParam, lParam
    ret
WndProc endp


WinMain PROC hInstance:DWORD, hPrevInstance:DWORD, lpCmdLine:DWORD, nCmdShow:DWORD
; tao lop cua so
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

    mov     wc.hbrBackground, 5h          ; mau nen cua so
    mov     wc.lpszMenuName, 0                      ; khong co menu
    mov     wc.lpszClassName, offset class_name     ; ten lop cua so

    lea     esi, wc                                 ; dia chi cua wc
    push    esi
    call    RegisterClassA                          ; dang ky lop cua so

    cmp     eax, 0
    je      loi1                                    ; thong bao loi khong dang ky duoc lop cua so

; tao cua so
    push    0                              ; lpParam = NULL
    push    wc.hInstance                   ; hInstance
    push    0                              ; hMenu = NULL
    push    0                              ; hWndParent = NULL
    push    200                            ; window_height
    push    400                            ; window_width
    push    80000000h                  ; y
    push    80000000h                  ; x
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
    push	101                             ; ID
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
    push	102                             ; ID
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
    push	wc.hInstance
    push    103                             ; ID
    push    hWnd1
    push    25                              ; button height
    push    100                             ; button width
    push    100                             ; y
    push    150                             ; x
    push	50010000h
    push    offset buttontext
    push    offset button
    push    0
    call    CreateWindowExA

    push    5h
    push    hWnd1
    call    ShowWindow

    push    hWnd1
    call    UpdateWindow

    msg_loop:
    lea     edi, msg1
    push    0
    push    0
    push    0 
    push    edi 
    call    GetMessageA

    cmp     eax, 0
    jle     end_loop

    push    edi
    call    TranslateMessage
    push    edi
    call    DispatchMessageA
    jmp     msg_loop

    loi1:
    push    0
    push    offset window_title
    push    offset msgloi1
    push    0
    call    MessageBoxA
    jmp     end_loop

loi2:
    push    0
    push    offset window_title
    push    offset msgloi2
    push    0
    call    MessageBoxA

    end_loop:
    push    0
    call    ExitProcess
WinMain endp
end WinMain
