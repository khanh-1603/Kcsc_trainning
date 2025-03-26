# [1. Debug flags:](https://anti-debug.checkpoint.com/techniques/debug-flags.html)
## 1.1.1. IsDebuggerPresent():

Code C/C++:
```cpp
if (IsDebuggerPresent())
    ExitProcess(-1);
```

Code assembly
```asm
 include C:\masm32\include\masm32rt.inc

.data
msg  db "Debugging?", 0
msg1 db "Khong bi debug", 0
msg2 db "Dang bi debug" , 0

.code
main proc
call IsDebuggerPresent    
    test al, al
    jne  being_debugged
    
    push 0
    push offset msg
    push offset msg1
    push 0
    call MessageBoxA

    push 0
    call ExitProcess

being_debugged:
    push 0
    push offset msg
    push offset msg2
    push 0
    call MessageBoxA
    push 1
    call ExitProcess
main endp
end main
```

![Capture](https://hackmd.io/_uploads/HJmMbnchyx.png)

![Capture1](https://hackmd.io/_uploads/ByQG-h92Je.png)

# [2. Object Handle:](https://anti-debug.checkpoint.com/techniques/object-handles.html)

## 2.2. CreateFile():

Code C/C++
```cpp
bool Check()
{
    CHAR szFileName[MAX_PATH];
    if (0 == GetModuleFileNameA(NULL, szFileName, sizeof(szFileName)))
        return false;
    
    return INVALID_HANDLE_VALUE == CreateFileA(szFileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, 0);
}
```
Code assembly
```asm
include C:\masm32\include\masm32rt.inc

.data
msg  db "Debugging?", 0
msg1 db "Khong bi debug", 0
msg2 db "Dang bi debug" , 0
szFileName db MAX_PATH dup(0)

.code
main proc
; lay path cua chinh file hien tai
    
    lea ebx, szFileName
    push MAX_PATH
    push ebx
    push 0
    call GetModuleFileNameA
    test eax, eax
    jz thoat
;mo file
    push 0
    push 0
    push OPEN_EXISTING
    push 0
    push 0
    push GENERIC_READ
    push ebx
    call CreateFileA
    cmp eax, INVALID_HANDLE_VALUE
    je  being_debugged      

    push 0
    push offset msg
    push offset msg1
    push 0
    call MessageBoxA

thoat:
    push 0
    call ExitProcess

being_debugged:
    push 0
    push offset msg
    push offset msg2
    push 0
    call MessageBoxA

    push 1
    call ExitProcess
main endp
end main

```
Nếu chạy luôn trên `Visual Code` thì không bị báo là debugger. Còn nếu dùng `ida` thì sẽ bị báo là debugger,

![Capture](https://hackmd.io/_uploads/Sy5FGp931e.png)

Dùng `ida`.

![Capture1](https://hackmd.io/_uploads/SkujzT52Jx.png)

Dùng `VS Code`.

# [3. Exceptions:](https://anti-debug.checkpoint.com/techniques/exceptions.html)

## 3.1. UnhandledExceptionFilter()

Code C/C++
```cpp
LONG UnhandledExceptionFilter(PEXCEPTION_POINTERS pExceptionInfo)
{
    PCONTEXT ctx = pExceptionInfo->ContextRecord;
    ctx->Eip += 3; // Skip \xCC\xEB\x??
    return EXCEPTION_CONTINUE_EXECUTION;
}

bool Check()
{
    bool bDebugged = true;
    SetUnhandledExceptionFilter((LPTOP_LEVEL_EXCEPTION_FILTER)UnhandledExceptionFilter);
    __asm
    {
        int 3                      // CC
        jmp near being_debugged    // EB ??
    }
    bDebugged = false;

being_debugged:
    return bDebugged;
}
```

Code assembly
```asm
include C:\masm32\include\masm32rt.inc

.data
msg  db "Debugging?", 0
msg1 db "Khong bi debug", 0
msg2 db "Dang bi debug" , 0

.code
main proc
    push offset not_debugged
    call SetUnhandledExceptionFilter
    int  3
    jmp  being_debugged

not_debugged:
    push 0
    push offset msg
    push offset msg1
    push 0
    call MessageBoxA

thoat:
    push 0
    call ExitProcess

being_debugged:
    push 0
    push offset msg
    push offset msg2
    push 0
    call MessageBoxA

    push 1
    call ExitProcess
main endp
end main

```
- Đăng ký `not_debugged` làm Exception Handler. Nếu có Exception xảy ra, Windows sẽ gọi not_debugged.

- `int 3` (mã opcode 0xCC) là một `Software Breakpoint`.
-  Nếu Debugger đang chạy, nó sẽ bắt lỗi `int 3` và không để `SetUnhandledExceptionFilter` xử lý. Khi đó, chương trình tiếp tục chạy và nhảy đến being_debugged.
-  Nếu không có Debugger, Windows sẽ gọi `SetUnhandledExceptionFilter()`, và nhảy đến `not_debugged`.

![Capture](https://hackmd.io/_uploads/Syl0UTcnkl.png)

![dang bi debug](https://hackmd.io/_uploads/ByBR8p5hyg.png)

# [4. Timing:](https://anti-debug.checkpoint.com/techniques/timing.html)

## 4.2. GetLocalTime():

Code C/C++
```cpp
bool IsDebugged(DWORD64 qwNativeElapsed)
{
    SYSTEMTIME stStart, stEnd;
    FILETIME ftStart, ftEnd;
    ULARGE_INTEGER uiStart, uiEnd;

    GetLocalTime(&stStart);
    // ... some work
    GetLocalTime(&stEnd);

    if (!SystemTimeToFileTime(&stStart, &ftStart))
        return false;
    if (!SystemTimeToFileTime(&stEnd, &ftEnd))
        return false;

    uiStart.LowPart  = ftStart.dwLowDateTime;
    uiStart.HighPart = ftStart.dwHighDateTime;
    uiEnd.LowPart  = ftEnd.dwLowDateTime;
    uiEnd.HighPart = ftEnd.dwHighDateTime;
    return (uiEnd.QuadPart - uiStart.QuadPart) > qwNativeElapsed;
}
```

Code assembly
```asm
include C:\masm32\include\masm32rt.inc


.data
msg  db "Debugging?", 0
msg1 db "Khong bi debug", 0
msg2 db "Dang bi debug" , 0
szFileName db MAX_PATH dup(0)
uiStart dq 0                      ; bien unsigned int 8 byte 
uiResult dq 0
stStart SYSTEMTIME <>           ;bien luu thoi gian
stEnd SYSTEMTIME <>
ftStart FILETIME <>             ; bien timestamp
ftEnd FILETIME <>

.code
main proc
    push offset stStart     ; luu thoi gian ban dau
    call GetLocalTime

    add eax, 1000
    add eax, eax           ; lam gi do
    xor ebx, ebx                            
    add ebx, 100
    div ebx

    push offset stEnd     ; luu thoi gian ket thuc
    call GetLocalTime

    push offset ftStart
    push offset stStart
    call SystemTimeToFileTime  ; chuyen thoi gian sang dang timestamp

    cmp eax, 0              ; tra ve false thi thoat voi loi
    je thoat_voi_loi

    push offset ftEnd
    push offset stEnd
    call SystemTimeToFileTime

    cmp eax, 0              ; tra ve false thi thoat voi loi
    je thoat_voi_loi
        
    mov eax, ftStart.dwLowDateTime      ; chuyen timestamp sang dang int de tinh toan
    mov ebx, ftStart.dwHighDateTime
             
    mov ecx, ftEnd.dwLowDateTime
    mov edx, ftEnd.dwHighDateTime

    sub ecx, eax                        ; start - end
    sbb edx, ebx                        ; tru co borrow
    
    lea esi, offset uiResult
    mov dword ptr [esi], ecx
    mov dword ptr [esi+4], edx
    
    cmp ecx, 5                        ; gia su thoi gian chay binh thuong la 5s
    ja being_debugged

not_debugged:
    push 0
    push offset msg
    push offset msg1
    push 0
    call MessageBoxA

thoat:
    push 0
    call ExitProcess

being_debugged:
    push 0
    push offset msg
    push offset msg2
    push 0
    call MessageBoxA

thoat_voi_loi:
    push 1
    call ExitProcess

main endp
end main

```
- Lấy thời gian bắt đầu và kết thúc của công việc bằng cách gọi hàm `GetLocalTime()`.

- Chuyển đổi thời gian từ định dạng `SYSTEMTIME` sang `FILETIME` bằng cách sử dụng hàm `SystemTimeToFileTime()`.
- Chuyển đổi thời gian từ định dạng `FILETIME` sang `ULARGE_INTEGER` để có thể thực hiện so sánh.
- So sánh sự chênh lệch thời gian giữa `uiEnd` và `uiStart` với thời gian chạy bình thường của chương trình.
- Em giả sử thời gian chạy bình thường là `5s`.

![Khong bi debug](https://hackmd.io/_uploads/Sy9Sqxinke.png)

Khi bấm `run`.

![dang bi debug](https://hackmd.io/_uploads/Syzw9xs3Jg.png)

Khi đặt `breakpoint` và để im trong `5s`.

# [5. Process Memory:](https://anti-debug.checkpoint.com/techniques/process-memory.html)

## 5.1.3. Hardware Breakpoint:

Code C/C++
```cpp
bool IsDebugged()
{
    CONTEXT ctx;
    ZeroMemory(&ctx, sizeof(CONTEXT)); 
    ctx.ContextFlags = CONTEXT_DEBUG_REGISTERS; 

    if(!GetThreadContext(GetCurrentThread(), &ctx))
        return false;

    return ctx.Dr0 || ctx.Dr1 || ctx.Dr2 || ctx.Dr3;
}
```
- Dùng `ZeroMemory()` để set toàn bộ ctx về 0, tránh chứa dữ liệu rác.

- Gán `ContextFlags = CONTEXT_DEBUG_REGISTERS` để chỉ lấy thông tin của Debug Registers.
- `GetCurrentThread()`: Lấy handle của thread hiện tại.
- `GetThreadContext()`: Lấy thông tin trạng thái CPU của thread hiện tại.
- Nếu `GetThreadContext()` thất bại → Trả về false (không bị Debug). Ngược lại nếu bất kỳ thanh ghi Debug nào (Dr0 - Dr3) khác 0, nghĩa là Debugger đã đặt Hardware Breakpoint → Trả về true (bị Debug).

Code assembly
```asm
include C:\masm32\include\masm32rt.inc

.data
 ctx CONTEXT <>
 msg  db "Debugging?", 0
msg1 db "Khong bi debug", 0
msg2 db "Dang bi debug" , 0

.code
main proc
    mov eax, 100
    add eax, 100
    sub eax, 100
    xor eax,eax

    push sizeof ctx                
    push 0
    push offset ctx
    call crt_memset                 ; ZeroMemory

    mov ctx.ContextFlags, CONTEXT_DEBUG_REGISTERS
    call GetCurrentThread

    push eax
    call GetThreadContext

    test eax, eax
    jz return_false              ; that bai -> tra ve false

    mov eax, ctx.iDr0            ; lay Dr0
    or  eax, ctx.iDr1            ; or voi cac thanh ghi con lai
    or  eax, ctx.iDr2            ; chi can 1 thanh ghi khac 0 la co debug
    or  eax, ctx.iDr3

    test eax, eax                ; ca 4 thanh ghi deu = 0
    jz return_false              ; neu tat ca = 0 -> false 

    mov eax, 1   ; tra ve true
    add esp, 4
    jmp being_debugged

return_false:
    mov eax, 0
    add esp, 4


not_debugged:
    push 0
    push offset msg
    push offset msg1
    push 0
    call MessageBoxA

    push 0
    call ExitProcess

being_debugged:
    push 0
    push offset msg
    push offset msg2
    push 0
    call MessageBoxA

    push 1
    call ExitProcess
main endp 
end main 
```
![Khong bi debug](https://github.com/user-attachments/assets/770189a0-7482-45ff-aa4e-79986e2f8194)

Khi chạy trên `VS code`.

![dang bi debug](https://github.com/user-attachments/assets/b7479e52-0bcd-4621-9726-ad65e04e8da5)

Khi đặt 1 `hardware breakpoint` trên `ida`.

# [6. Assembly instructions:](https://anti-debug.checkpoint.com/techniques/assembly.html)

## 6.1. INT 3

Code C/C++
```cpp
bool IsDebugged()
{
    __try
    {
        __asm int 3;
        return true;
    }
    __except(EXCEPTION_EXECUTE_HANDLER)
    {
        return false;
    }
}
```
- Nếu không có Debugger gắn vào, hệ thống sẽ ném ra một exception, sau đó khối `__except` bắt exception đó.
- Nếu exception được ném ra và được bắt bởi` __except`, hàm sẽ trả về false.
- Ngược lại nếu có debugger gắn vào, thì debugger sẽ chặn ngoại lệ này, và chương trình không bắt được. Trả về true.

Code assembly
```asm
include C:\masm32\include\masm32rt.inc


.data
msg  db "Debugging?", 0
msg1 db "Khong bi debug", 0
msg2 db "Dang bi debug" , 0
ctx CONTEXT <>
.code

 assume fs:nothing                   ; tranh loi use of register assum to ERROR

IsDebugged proc
    push ebp
    mov ebp, esp
    pushad                            ; luu tat ca thanh ghi

; Dang ky exception handler vao FS:[0] de window xu ly

    xor eax, eax                                        ; dat eax = 0
    push offset SEH_handler                             ; dia chi xu ly exception
    push fs: [eax]                                      ; handle cu
    mov fs: [eax], esp                                  ; dang ky ham xu ly exception moi

    int 3                                               ; gay exception bang INT 3

    ;jmp debugged                                       ; neu khong bi bat tra ve true

SEH_handler:
    mov esi, [esp + 0Ch]                      ;  lay con tro ngu canh
    assume esi: PTR CONTEXT
    mov eax, dword ptr [esp + 4]            ; lay exceptionRecord
    cmp dword ptr [eax], 80000003h          ; kiem tra loi int 3
    jne debugged                            ; khong phai loi int 3 coi nhu khong phai debug

    mov [esi].regEip, offset not_debugged   ;  nhay qua int 3 neu khong bi debug

not_debugged:
    pop dword ptr FS:[0]  ; khoi phuc SEH cu
    add esp, 4
    popad
    mov eax, 0            ; khong co debug -> tra ve 0
    pop ebp
    ret

debugged:
    pop dword ptr FS:[0]  ; Khoi phuc SEH cu
    add esp, 4
    popad
    mov eax, 1            ; co debug -> tra ve 1
    pop ebp
    ret
IsDebugged endp

main proc
    mov eax, 10
    add eax, eax
    mov ecx, 10
    mul ecx
    call IsDebugged
    cmp eax, 1
    je being_debugged

not_debugged:
    push 0
    push offset msg
    push offset msg1
    push 0
    call MessageBoxA

thoat:
    push 0
    call ExitProcess

being_debugged:
    push 0
    push offset msg
    push offset msg2
    push 0
    call MessageBoxA

thoat_voi_loi:
    push 1
    call ExitProcess

main endp
end main
```
![Capture](https://github.com/user-attachments/assets/34aac42b-0fe4-4bfb-bdbd-f919d4ff3dc2)

![Khong bi debug](https://github.com/user-attachments/assets/20c6f548-68fb-492c-97c2-9ba025377c2e)

**Khi chạy masm32 trên window 64-bit thì window nó chặn không cho truy cập vào SEH. Do đó cách này không khả thi. Em xin phép bỏ qua code mục 6**

# [7. Direct debugger interaction:](https://anti-debug.checkpoint.com/techniques/interactive.html)

## 7.3. NtSetInformationThread():

Code C/C++
```cpp
bool AntiDebug()
{
    NTSTATUS status = ntdll::NtSetInformationThread(
        NtCurrentThread,  // luong hien tai
        ntdll::THREAD_INFORMATION_CLASS::ThreadHideFromDebugger, //an luong
        NULL,  // khong can du lieu bo sung
        0);  // kich thuoc du lieu la 0
    return status >= 0; // tra ve true -> chan debug thanh cong
}
```
- `NtSetInformationThread()`: Là một hàm của dùng để thay đổi thuộc tính của một luồng. Khi có `ThreadHideFromDebugger` (Giá trị 0x11) luồng hiện tại sẽ bị ẩn khỏi debug.

Code assembly
```asm
include C:\masm32\include\masm32rt.inc
include C:\masm32\include\ntdll.inc
includelib C:\masm32\lib\ntdll.lib


.data
msg  db "Debugging?", 0
msg1 db "Khong bi debug", 0
msg2 db "Dang bi debug" , 0

.code
AntiDebug proc
    push ebp
    mov ebp, esp

    call GetCurrentThreadId
    push eax
    push 0
    push THREAD_SET_INFORMATION
    call OpenThread
    mov esi, eax

    push 0                    ; Length = 0
    push 0                    ; ThreadInformation = NULL
    push 11h                   ; THREAD_INFORMATION_CLASS = 0x11 (ThreadHideFromDebugger)
    push esi                   ; thread handle
    call ZwSetInformationThread 
    
    mov ebx, eax
    push esi
    call CloseHandle

    mov eax, 0
    cmp ebx, 0
    je success
    
    mov eax, 1
    success:
    pop ebp
    ret
AntiDebug endp


main proc
    mov eax, 6          ;code linh tinh
    call AntiDebug
    test eax, eax
    jz being_debugged

not_debugged:
    push 0
    push offset msg
    push offset msg1
    push 0
    call MessageBoxA

thoat:
    push 0
    call ExitProcess

being_debugged:
    push 0
    push offset msg
    push offset msg2
    push 0
    call MessageBoxA

thoat_voi_loi:
    push 1
    call ExitProcess
main endp
end main
```
![Khong bi debug](https://github.com/user-attachments/assets/93e51fcd-dee8-4f9d-a368-66cebccf97ea)

Khi `step over` dòng `call NtSetInformationThread` thì em bị ngừng debug lại. Còn khi dùng `call ZwSetInformationThread` Thì nó báo lỗi ngay khi đi qua. Có vẻ nó đã chặn thành công.

![dang bi debug](https://github.com/user-attachments/assets/4edddffe-1aa7-4c92-90eb-aef75dd19509)

# [8. MISC:](https://anti-debug.checkpoint.com/techniques/misc.html)

## 8.1. FindWindow()

Code C/C++
```cpp
const std::vector<std::string> vWindowClasses = {
    "antidbg",
    "ID",               // Immunity Debugger
    "ntdll.dll",        // peculiar name for a window class
    "ObsidianGUI",
    "OLLYDBG",
    "Rock Debugger",
    "SunAwtFrame",
    "Qt5QWindowIcon"
    "WinDbgFrameClass", // WinDbg
    "Zeta Debugger",
};

bool IsDebugged()
{
    for (auto &sWndClass : vWindowClasses)
    {
        if (NULL != FindWindowA(sWndClass.c_str(), NULL))
            return true;
    }
    return false;
}
```
- `vWindowClasses`: Chứa tên class của cửa sổ từ các trình debug phổ biến.
- 
- `FindWindowA(sWndClass.c_str(), NULL)`: 
    - Nếu tìm thấy cửa sổ với class tương ứng → Trả về handle (HWND). 
    - Nếu không tìm thấy → Trả về NULL.
- Lặp liên tục. Nếu tìm thấy cửa sổ của trình debug -> trả về `true`. Ngược lại trả về `false`.

Code assembly
```asm
include C:\masm32\include\masm32rt.inc

.data
    msg db "Debug Class: ", 0
    msg_not_found db "Khong tim thay cua so", 0
    msg1 db "Khong bi debug", 0
    msg2 db "debugged", 0
    msg_title db "Debugging ?", 0

    vWindowClasses db "idawindow", 0,
                      "Qt5QWindowIcon", 0,
                      "IDAWIN", 0,
                     0  ; ket thuc

.code
FindDebugWindows proc
    pushad
    lea esi, vWindowClasses                 ;offset dau danh sach

check_class:
    cmp byte ptr [esi], 0                   ; kiem tra ket thuc danh sach
    je no_debug_found

    push 0                                  ; window title (NULL)   
    push esi                                ; class name
    call FindWindowA
    
    test eax, eax                           ; tra ve 0 neu khong tim thay
    jnz debug_found

    xor eax, eax                            ; eax = null
find_next_class:
    cmp byte ptr [esi], al                  ; kiem tra tung byte voi null
    je found_end_of_class                   ; thay thi ket thuc lap

    inc esi                                 ; tang offset
    jmp find_next_class

found_end_of_class:
    inc esi                                 ; nhay qua ky tu null
    jmp check_class

debug_found:
    push 0
    push offset msg
    push esi                                ; offset classname
    push 0
    call MessageBoxA
    
    popad
    mov eax, 1
    ret

no_debug_found:
    push 0
    push offset msg
    push offset msg_not_found               ; khong co cua so
    push 0
    call MessageBoxA

    popad
    mov eax, 0
    ret
FindDebugWindows endp

main proc
    call FindDebugWindows
    test eax, eax                          ; tra ve 0 la khong co debug
    jnz debugged
    
    push 0
    push offset msg_title
    push offset msg1                       ; khong bi debug
    push 0
    call MessageBoxA
    jmp thoat

debugged:
    push 0
    push offset msg_title
    push offset msg2                       ; bi debug
    push 0
    call MessageBoxA

thoat:
    push 0
    call ExitProcess
main endp
end main
```

Em tiện thể tìm luôn cửa sổ debug của ida.
Kết quả:

![ko cua so debug](https://github.com/user-attachments/assets/37bdb5ab-1048-4f7e-bd9d-c3421060bc2c)

![Khong bi debug](https://github.com/user-attachments/assets/84ddb900-ec1c-4c8f-87df-6d2d9cb11137)

Khi dùng `VS code`.

![cua so debug](https://github.com/user-attachments/assets/14c98034-52be-472e-97a0-1ef6bafbdd02)

![dang bi debug](https://github.com/user-attachments/assets/8c423b4f-8c49-4b81-9f3d-45322598020c)

Khi dùng `ida`.
