# I. Cơ bản về anti-debug.

## 1.Khái niệm:
- Là 1 kỹ thuật được sử dụng để ngăn chặn việc phân tích và giám sát chương trình máy tính. 

- Gây khó khăn cho các kỹ sư đảo ngược và nhà phân tích malware khi cố gắng phân tích mã nguồn hoặc quá trình chạy của 1 chương trình. 

- Kỹ thuật này thường được các Malware dùng để tránh bị reverse

## 2. Lợi ích
- **Bảo vệ bản quyền và sở hữu trí tuệ**: Bảo vệ phần mềm và ứng dụng khỏi việc sao chép và crack, giúp tăng thu nhập và đảm bảo lợi ích cho các nhà phát triển và chủ sở hữu.

- **Bảo mật và phòng ngừa tấn công**: ngăn chặn kẻ tấn công khai thác lỗ hổng bằng cách giảm khả năng reverse và hiểu hơn về cấu trúc và logic của phần mềm -> Tăng cường bảo mật, khó bị tấn công.
## 3. Tác hại
- **Gây khó khăn cho các Malware analysiser và reverser** (thường được các hacker sử dụng).

- **Gây thách thức cho việc duy trì và sửa lỗi**: Khi các công cụ gỡ lỗi không thể được sử dụng, việc tìm và sửa lỗi có thể trở nên phức tạp hơn và tốn nhiều thời gian hơn.

# II. Một số kỹ thuật Anti debug
## [1. Debug flags:](https://anti-debug.checkpoint.com/techniques/debug-flags.html)
 Là các cờ đặc biệt ở hệ thống, dùng để chỉ các tiến trình (process) đang bị debug.

 Có 2 cách xác định: dùng hàm API hoặc kiểm tra các bảng của hệ thống ở trong bộ nhớ.

Thường được các malware sử dụng.

### 1.1. Dùng Win32 API

Có 6 hàm API hỗ trợ

#### 1.1.1. IsDebuggerPresent(): 

 Kiểm tra cờ BeingDebugged của Khối môi trường quy trình (PEB).
 
 Kiểm tra tiến trình có **debug nào gán vào** không.

Hàm `IsDebuggerPresent()` trả về 1 nếu có debug gán vào, 0 nếu không có. Sau đó thoát chương trình với lỗi.

Code C/C++:
```cpp
if (IsDebuggerPresent())
    ExitProcess(-1);
```

Code assembly
```asm
 call IsDebuggerPresent    
    test al, al
    jne  being_debugged
    ...
being_debugged:
    push 1
    call ExitProcess
```

#### 1.1.2. CheckRemoteDebuggerPresent()
- kiểm tra xem tiến trình hiện tại có đang bị **debug bởi một tiến trình bên ngoài** (remote debugger) hay không.

Cú pháp
```c
BOOL CheckRemoteDebuggerPresent(
    HANDLE hProcess,  // Handle của tiến trình cần kiểm tra
    PBOOL pbDebuggerPresent // Con trỏ đến biến BOOL để nhận kết quả
    );
```
code assembly
```assembly
    lea eax, [bDebuggerPresent]
    push eax
    push -1  ; GetCurrentProcess()
    call CheckRemoteDebuggerPresent
    cmp [bDebuggerPresent], 1
    jz being_debugged
    ...
being_debugged:
    push -1
    call ExitProcess
```
`bDebuggerPresent` là một biến lưu kết quả kiểm tra debugger. 3 dòng đầu là đẩy 2 tham số vào hàm.
biến bằng 1 nếu có debug, 0 nếu không có.

### 1.2. Kiểm tra thủ công (Manual Check)
- Cách này dùng để xác định cờ debug trong cấu trúc hệ thống bằng cách kiểm tra bộ nhớ tiến trình mà không dùng các hàm API.
#### 1.2.1 PEB!BeingDebugged Flag
Kiểm tra cờ `BeingDebugged` mà không gọi hàm `IsDebuggerPresent()`.

Code
```asm
mov eax, fs:[30h]         ; lay dia chi PEB
cmp byte ptr [eax+2], 0   ; kiem tra gia tri BeingDebugged (offset 0x02 trong PEB)
jne being_debugged        ; neu khac 0 -> tien trinh dang bi debug -> nhay den being_debugged
```
Lưu ý: địa chỉ PEB khác nhau tùy theo kiến trúc

| Kiến trúc | cách truy cập PEB | Địa chỉ cờ|
| -------- | -------- | -------- |
| x86 (32-bit)    | fs:[30h]    | fs:[32h]     |
| x64 (64-bit)    | gs:[60h]    | gs:[62h]|

#### 1.2.2. NtGlobalFlag
`tGlobalFlag` là một cờ trong PEB, giúp hệ điều hành theo dõi các tính năng đặc biệt, bao gồm cả debugging mode. Nếu một tiến trình đang bị debug, một số bit trong `NtGlobalFlag` sẽ được bật, giúp phát hiện debugger mà không cần gọi API như `IsDebuggerPresent()`.
Các cờ được bật khi có debug:


| Cờ | Giá trị | Ý nghĩa |
| -------- | -------- | -------- |
| FLG_HEAP_ENABLE_TAIL_CHECK     | 0x10    | Kiểm tra heap cuối     |
|FLG_HEAP_ENABLE_FREE_CHECK| 0x20| Kiểm tra heap đã giải phóng|
|FLG_HEAP_VALIDATE_PARAMETERS| 0x40| Xác thực tham số heap|
|Tổng|0x70|Debugger đang bật|

code assembly
```asm
mov eax, fs:[30h]
mov al, [eax+68h]
and al, 70h
cmp al, 70h
jz  being_debugged
```
| Kiến trúc | cách truy cập PEB | Địa chỉ cờ |
| -------- | -------- | -------- |
| x86 (32-bit)    | fs:[30h]    | fs:[30h+68h]     |
| x64 (64-bit)    | gs:[60h]    | gs:[60h+BCh]|


## [2. Object Handle:](https://anti-debug.checkpoint.com/techniques/object-handles.html)
Kiểm tra sử dụng các xử lý đối tượng kernel để phát hiện sự hiện diện của trình gỡ lỗi
### 2.1 OpenProcess()
- Vì chương trình ta là 1 process con của process của debugger.Vì thế nó cũng sẽ thừa kế quyền từ debugger.Chính vì lý do này.Ta có thể mở bất cứ process nào đang chạy từ chương trình chúng ta.

- `OpenProcess()` sẽ trả về giá trị khac 0 nếu bị debug.

Cú pháp
```cpp
HANDLE OpenProcess(
    DWORD dwDesiredAccess,  // quyen truy cap (PROCESS_ALL_ACCESS)
    BOOL  bInheritHandle,   // ke thua handle hay khong (true hoac false)
    DWORD dwProcessId       // PID cua tien trinh can mo
);
```

Code C/C++
```cpp
   typedef DWORD (WINAPI *TCsrGetProcessId)(VOID);

bool Check()
{   
    HMODULE hNtdll = LoadLibraryA("ntdll.dll");
    if (!hNtdll)
        return false;
    
    TCsrGetProcessId pfnCsrGetProcessId = (TCsrGetProcessId)GetProcAddress(hNtdll, "CsrGetProcessId");
    if (!pfnCsrGetProcessId)
        return false;

    HANDLE hCsr = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pfnCsrGetProcessId());
    if (hCsr != NULL)
    {
        CloseHandle(hCsr);
        return true;
    }        
    else
        return false;
}
}
```

### 2.2. CreateFile()
- Thông tin file thực thi được lưu ở `CREATE_PROCESS_DEBUG_INFO`. Do đó các Debugger có thể đọc dữ liệu từ đây, một số Debugger có thể quên đóng Handle này.

- Sử dụng hàm `CreateFileW()` hoặc`CreateFileA()` để mở tệp tin với quyền truy cập độc quyền. Nếu thất bại kết quả trả về là:`INVALID_HANDLE_VALUE` thì có nghĩa là chương trình đang được debug.

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

### 2.3. CloseHandle()
Nếu process đang được debug và có handle không hợp lệ pass qua hàm `ntdll!NtClose()` hoặc là `kernel32!CloseHandle()` thì `EXCEPTION_INVALID_HANDLE` (0xC0000008) sẽ được bật, nó có thể được lưu vào bộ nhớ đệm, nếu phát hiện thì ta có thể biết được chương trình đang được debug.

Code C/C++
```c
bool Check()
{
    __try
    {
        CloseHandle((HANDLE)0xDEADBEEF);
        return false;
    }
    __except (EXCEPTION_INVALID_HANDLE == GetExceptionCode()
                ? EXCEPTION_EXECUTE_HANDLER 
                : EXCEPTION_CONTINUE_SEARCH)
    {
        return true;
    }
}
```

## [3. Exceptions:](https://anti-debug.checkpoint.com/techniques/exceptions.html)
Các phương pháp sau đây cố tình gây ra ngoại lệ để xác minh xem hành vi tiếp theo có phải là hành vi điển hình đối với một quy trình đang chạy mà không có trình gỡ lỗi hay không.

### 3.1. UnhandledExceptionFilter()
- Khi xảy ra exception và không có Exception Handlers được đăng kí. Hàm `UnhandledExceptionFilter` sẽ được gọi.

- Có thể đăng ký một `custom unhandled exception filter` dùng `kernel32!SetUnhandledExceptionFilter()`. Nhưng nếu chương trình đang được debug, custom filter sẽ không được gọi.

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

### 3.2. RaiseException()
Các exceptions như `DBC_Control_C` hoặc `DBG_RIPEVENT` không được chuyển tới exception handlers của process hiện tại và được debugger sử dụng. Điều này cho phép chúng ta đăng ký một trình xử lý ngoại lệ, đưa ra các ngoại lệ này bằng cách sử dụng hàm `kernel32!RaiseException()` và kiểm tra xem điều khiển có được chuyển đến process của chúng ta hay không. Nếu exception handlers không được gọi thì quá trình này có thể đang được gỡ lỗi.

Code C/C++
```c
bool Check()
{
    __try
    {
        RaiseException(DBG_CONTROL_C, 0, 0, NULL);
        return true;
    }
    __except(DBG_CONTROL_C == GetExceptionCode()
        ? EXCEPTION_EXECUTE_HANDLER 
        : EXCEPTION_CONTINUE_SEARCH)
    {
        return false;
    }
}
```
Gây Exception bằng RaiseException
- Nếu Debugger không chạy, Windows sẽ chuyển Exception này đến khối __except{}. Nếu Debugger đang chạy, nó sẽ bắt Exception này trước khi Windows xử lý, và chương trình tiếp tục chạy bình thường → Trả về true (bị debug).

Nếu Exception không bị Debugger bắt, __except xử lý nó
- `GetExceptionCode()` lấy mã Exception.
Nếu `ExceptionCode == DBG_CONTROL_C`, Windows xử lý nó mà không có Debugger. Khi đó, chương trình sẽ nhảy vào khối `{ return false; }`, nghĩa là không bị Debug.


## [4. Timing:](https://anti-debug.checkpoint.com/techniques/timing.html)
Phương pháp này kiểm tra độ trễ giữa các phần của đoạn code.
Khi một tiến trình bị theo dõi trong trình gỡ lỗi, sẽ có một độ trễ lớn giữa các lệnh và việc thực thi.

### 4.1. RDPMC/RDTSC
- RDPMC (Read Performance-Monitoring Counters) và RDTSC (Read Time-Stamp Counter) là các instruction x86 ASM được sử dụng để đo thời gian và hiệu suất của CPU, thường được sử dụng trong việc tối ưu hóa mã máy tính và phân tích hiệu suất hệ thống.

- 2 instructions này sử dụng cờ PCE trong thanh ghi CR4.
- RDPMC chỉ được sử dụng ở Kernel.

Code C/C++
```cpp
bool IsDebugged(DWORD64 qwNativeElapsed)
{
    ULARGE_INTEGER Start, End;
    __asm
    {
        xor  ecx, ecx
        rdtsc
        mov  Start.LowPart, eax
        mov  Start.HighPart, edx
    }
    // ... some work
    __asm
    {
        xor  ecx, ecx
        rdtsc
        mov  End.LowPart, eax
        mov  End.HighPart, edx
    }
    return (End.QuadPart - Start.QuadPart) > qwNativeElapsed;
}
```
Tương tự với RDPMC
- Lấy giá trị Timestamp trước và sau khi làm việc. Giá trị này nằm trong EDX:EAX

- `qwNativeElapsed` là ngưỡng thời gian tối đa mà một lần thực thi bình thường không có Debugger mất.
- Có debug -> độ trễ lớn -> khoảng thời gian sẽ lớn hơn 
- `return (End.QuadPart - Start.QuadPart) > qwNativeElapsed;` : lấy end trừ start. Nếu giá trị này bé hơn hoặc bằng thì cụm này sai -> trả về false -> không có debug. Ngược lại trả về true -> có debug.

### 4.2. GetLocalTime()
`GetLocalTime()` là một hàm trong Windows API dùng để lấy thời gian hệ thống hiện tại theo múi giờ cục bộ (Local Time).

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

- Lấy thời gian bắt đầu và kết thúc của công việc bằng cách gọi hàm `GetLocalTime()`.

- Chuyển đổi thời gian từ định dạng `SYSTEMTIME` sang `FILETIME` bằng cách sử dụng hàm `SystemTimeToFileTime()`.
- Chuyển đổi thời gian từ định dạng `FILETIME` sang `ULARGE_INTEGER` để có thể thực hiện so sánh.
- So sánh sự chênh lệch thời gian giữa `uiEnd` và `uiStart` với thời gian chạy bình thường của chương trình `qwNativeElapsed`.

Nhận xét: Cũng tương tự như **4.1**

### 4.3. GetSystemTime(), GetTickCount(), QueryPerformanceCounter(), timeGetTime()
Tương tự như các tricks ở trên.

Cách phát hiện debug ở các tricks này cũng sẽ chỉ phát hiện độ trễ nếu debugger có đặt breakpoint hay steptrace.

## [5. Process Memory:](https://anti-debug.checkpoint.com/techniques/process-memory.html)
Kỹ thuật chính là Detect Breakpoints và một số Memory check khác

### 5.1. Breakpoints
Luôn có thể kiểm tra bộ nhớ tiến trình để tìm các `software breakpoints`, hoặc kiểm tra các thanh ghi CPU debug để tìm các `hardware breakpoints`.

Breakpoint là bản chất của các quá trình reverses.

#### 5.1.1 Software Breakpoints (INT3)
Chỉ cần kiểm tra trong vùng nhớ chương trình đang chạy có bất kỳ opcode 0xCC (int 3).

Cách detect này không phải lúc nào cũng đúng vì nhiều như debugger đặt breakpoint để ngắt debug ở những vùng không nằm trong vùng nhớ test.

Code C/C++
```cpp
bool CheckForSpecificByte(BYTE cByte, PVOID pMemory, SIZE_T nMemorySize = 0)
{
    PBYTE pBytes = (PBYTE)pMemory; 
    for (SIZE_T i = 0; ; i++)
    {
        // Break on RET (0xC3) if we don't know the function's size
        if (((nMemorySize > 0) && (i >= nMemorySize)) ||
            ((nMemorySize == 0) && (pBytes[i] == 0xC3)))
            break;

        if (pBytes[i] == cByte)
            return true;
    }
    return false;
}

bool IsDebugged()
{
    PVOID functionsToCheck[] = {
        &Function1,
        &Function2,
        &Function3,
    };
    for (auto funcAddr : functionsToCheck)
    {
        if (CheckForSpecificByte(0xCC, funcAddr))
            return true;
    }
    return false;
}
```
- `CheckForSpecificByte()`: Kiểm tra xem trong vùng nhớ của một hàm có chứa một byte cụ thể hay không.

    - Duyệt từng byte trong bộ nhớ của hàm.
    - Nếu `nMemorySize == 0`, chỉ dừng khi gặp 0xC3 (lệnh RET, đánh dấu kết thúc hàm). Hoặc nếu nMemorySize > 0, dừng sau nMemorySize bytes.
    - Nếu tìm thấy byte cByte, trả về true.( có breakpoints).
- `IsDebugged()`
    - Kiểm tra 3 hàm .
    - Dùng `CheckForSpecificByte()` để kiểm tra sự có mặt của byte 0xCC.
    - Nếu có thì trả về true -> có breakpoints -> có debug. Ngược lại trả về false.

**Cách này không ổn khi chuyển sang masm vì độ dài 1 dòng lệnh không cố định. Việc duyệt từng byte không phải duyệt từng dòng. Do đó sẽ có trường hợp có byte `0xC3` nhưng không phải lệnh `RET`**

#### 5.1.2. Anti-Step-Over
Debugger cho phép bạn bỏ qua lệnh gọi hàm. Trong trường hợp như vậy, debugger sẽ ngầm đặt Software Breakpoint trên lệnh theo sau lệnh gọi (tức là địa chỉ trả về của hàm được gọi).

Để phát hiện xem debugger có cố gắng vượt qua hàm hay không, chúng ta có thể kiểm tra byte bộ nhớ đầu tiên tại địa chỉ trả về. Nếu `software breakpoint` ( 0xCC ) nằm ở địa chỉ trả về, chúng ta có thể patch nó bằng một số câu lệnh khác (ví dụ NOP ). Rất có thể nó sẽ phá mã và làm hỏng quá trình. Mặt khác, chúng ta có thể patch địa chỉ trả về bằng một số câu lệnh có ý nghĩa thay vì NOP và thay đổi luồng điều khiển của chương trình.

#### 5.1.3. Hardware Breakpoint
Các thanh ghi gỡ lỗi DR0, DR1, DR2 và DR3 có thể được truy xuất từ `thread context`. Nếu chúng chứa các giá trị khác 0, điều đó có thể có nghĩa là tiến trình được thực thi bằng debugger và 1 `hardware breakpoint` đã được đặt.

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

### 5.2. Một số kỹ thuật kiểm tra bộ nhớ khác.
Phần này chứa các kỹ thuật trực tiếp kiểm tra hoặc thao tác bộ nhớ ảo của các tiến trình đang chạy để phát hiện hoặc ngăn chặn debug.

Gồm NtQueryVirtualMemory(), Detecting a function patch, Patch ntdll!DbgBreakPoint(),...

## [6. Assembly instructions:](https://anti-debug.checkpoint.com/techniques/assembly.html)

Các kỹ thuật sau đây nhằm phát hiện sự hiện diện của debugger dựa trên cách debugger hoạt động khi CPU thực thi một lệnh nhất định.

### 6.1. INT 3
- Tạo `EXCEPTION_BREAKPOINT` (0x80000003) để gọi `exception handler`. Nếu không được gọi thì chương trình đang được debug.

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

Ngoài ra còn có opcode CD 03 (dạng dài hơn của lệnh int 3).

### 6.2. INT 2D

Giống với `INT3` thì `INT 2D` cũng tạo `EXCEPTION_BREAKPOINT` VÀ `EXCEPTION HANDLER` sẽ được gọi.

Nhưng với `INT2D` , Windows sử dụng thanh ghi `EIP` làm địa chỉ ngoại lệ và sau đó tăng giá trị thanh ghi `EIP` . Windows cũng kiểm tra giá trị của thanh ghi `EAX` trong khi `INT2D` được thực thi. Nếu là 1, 3 hoặc 4 trên tất cả các phiên bản Windows hoặc 5 trên Vista+, địa chỉ ngoại lệ sẽ tăng thêm 1.

Câu lệnh này có thể gây ra sự cố cho một số debugger vì sau khi kích hoạt `EIP` , byte theo sau lệnh `INT2D` sẽ bị bỏ qua và việc thực thi có thể tiếp tục từ lệnh bị hỏng.

Code C/C++
```cpp
bool IsDebugged()
{
    __try
    {
        __asm xor eax, eax;
        __asm int 0x2d;
        __asm nop;
        return true;
    }
    __except(EXCEPTION_EXECUTE_HANDLER)
    {
        return false;
    }
}
```
- Nếu không có Debugger, lệnh này sẽ gây ra một exception và nhảy vào `__except`.
- Nếu có Debugger, nó có thể bắt ngoại lệ trước, cho phép tiếp tục thực thi bình thường, tức là nó không bị xử lý trong `__except`.
Lệnh `nop` (No Operation) được đặt ngay sau `int 0x2D` để tránh lỗi nếu Debugger cho phép chương trình tiếp tục mà không ném exception.

### 6.3. DebugBreak()
DebugBreak tạo ra một Exception Breakpoint xảy ra trong quy trình hiện tại. Điều này cho phép luồng gọi báo hiệu debugger xử lý Exception.

Nếu chương trình được thực thi mà không có debugger, điều khiển sẽ được chuyển tới trình xử lý ngoại lệ. Nếu không, việc thực thi sẽ bị debugger chặn lại.

Code C/C++
```cpp
bool IsDebugged()
{
    __try
    {
        DebugBreak();
    }
    __except(EXCEPTION_BREAKPOINT)
    {
        return false;
    }
    
    return true;
}
```
Tìm hiểu thêm về hàm [DebugBreak()](https://learn.microsoft.com/en-us/windows/win32/api/debugapi/nf-debugapi-debugbreak).

## [7. Direct debugger interaction:](https://anti-debug.checkpoint.com/techniques/interactive.html)
Các kỹ thuật sau đây cho phép tiến trình đang chạy quản lý giao diện người dùng hoặc tương tác với tiến trình mẹ của nó để phát hiện ra những mâu thuẫn vốn có của 1 tiến trình được debug.

### 7.1. Self-Debugging
Có ít nhất 3 hàm có thể đính kèm như 1 debugger vào 1 tiến trình đang chạy:
- `kernel32!DebugActiveProcess()`
- `ntdll!DbgUiDebugActiveProcess()` 
- `ntdll!NtDebugActiveProcess()`

Vì chỉ có thể gắn một debugger vào một tiến trình tại một thời điểm, việc không thể đính kèm debugger vào tiến trình có thể cho thấy sự hiện diện của một debugger khác.

### 7.2. BlockInput()
Hàm `user32!BlockInput()` có thể chặn tất cả chuột và bàn phím, đây là một cách khá hiệu quả để tắt debugger. Ở Window Vistas và cao hơn thì khi call cần có quyền admin.

Hàm này còn có thể phát hiện các tool hỗ trợ hooking. Cụ thể `BlockInput()` chỉ cho phép chặn input 1 lần. Khi gọi hàm lần 2 thì trả về `false`. Nếu nó vẫn trả về `true` thì tiến trình có thể đang bị hooking.

Code C/C++
```cpp
bool IsHooked ()
{
    BOOL bFirstResult = FALSE, bSecondResult = FALSE;
    __try
    {
        bFirstResult = BlockInput(TRUE);
        bSecondResult = BlockInput(TRUE);
    }
    __finally
    {
        BlockInput(FALSE);
    }
    return bFirstResult && bSecondResult;
}
```
### 7.3. NtSetInformationThread()
Hàm `ntdll!NtSetInformationThread()` có thể được sử dụng để ẩn một chuỗi khỏi debugger. Sau khi luồng bị ẩn khỏi debugger, nó sẽ tiếp tục chạy nhưng debugger sẽ không nhận được các sự kiện liên quan đến luồng này. Chuỗi này có thể thực hiện kiểm tra anti_debug như tổng kiểm tra mã, xác minh debug flags, v.v.

Tuy nhiên, nếu có một breakpoint trong luồng ẩn hoặc nếu chúng ta ẩn luồng chính khỏi debugger thì tiến trình sẽ gặp sự cố và debugger sẽ bị kẹt.

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

## [8. MISC:](https://anti-debug.checkpoint.com/techniques/misc.html)

### 8.1. FindWindow()
Kỹ thuật này bao gồm việc liệt kê đơn giản các lớp cửa sổ trong hệ thống và so sánh chúng với các lớp debugger Windows đã biết.

Các hàm có thể dùng:
- `user32!FindWindowW()`
- `user32!FindWindowA()`
- `user32!FindWindowExW()`
- `user32!FindWindowExA()`

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

### 8.2. DbgPrint()
Các hàm debug như `ntdll!DbgPrint()` và `kernel32!OutputDebugStringW()` gây ra `DBG_PRINTEXCEPTION_C` (0x40010006). Nếu một chương trình được thực thi với debugger đính kèm thì debugger sẽ xử lý exception này. Nhưng nếu không có debugger và `exceptions handler` được bật, thì exceptions này sẽ bị `exceptions handler` bắt.

Code C/C++
```cpp
bool IsDebugged()
{
    __try
    {
        RaiseException(DBG_PRINTEXCEPTION_C, 0, 0, 0);
    }
    __except(GetExceptionCode() == DBG_PRINTEXCEPTION_C)
    {
        return false;
    }

    return true;
}
```
- Nếu có debugger, nó sẽ chặn `DBG_PRINTEXCEPTION_C` và không để chương trình xử lý.

- Nếu không có debugger, ngoại lệ này sẽ đi vào `__except`.
- Nếu `GetExceptionCode()` trả về `DBG_PRINTEXCEPTION_C`, có nghĩa là ngoại lệ không bị bắt bởi debugger → Không bị debug → Trả về `false`. Ngược lại trả về `true`.
