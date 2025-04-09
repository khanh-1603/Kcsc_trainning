```c
#include <windows.h>
#include <stdio.h>
#include <wchar.h>

// Cấu trúc tương tự với các cấu trúc trong Windows API
typedef struct _PEB_LDR_DATA {
    ULONG Length;
    BOOLEAN Initialized;
    PVOID SsHandle;
    LIST_ENTRY InLoadOrderModuleList;
    LIST_ENTRY InMemoryOrderModuleList;
    LIST_ENTRY InInitializationOrderModuleList;
} PEB_LDR_DATA, *PPEB_LDR_DATA;

typedef struct _UNICODE_STRING {
    USHORT Length;         // Độ dài chuỗi (tính bằng byte, không tính null-terminator)
    USHORT MaximumLength;  // Dung lượng tối đa (tính bằng byte)
    PWSTR  Buffer;         // Con trỏ đến chuỗi wchar_t
} UNICODE_STRING, *PUNICODE_STRING;

typedef struct _LDR_DATA_TABLE_ENTRY {
    LIST_ENTRY InLoadOrderLinks;
    LIST_ENTRY InMemoryOrderLinks;
    LIST_ENTRY InInitializationOrderLinks;
    PVOID DllBase;
    PVOID EntryPoint;
    ULONG SizeOfImage;
    UNICODE_STRING FullDllName;
    UNICODE_STRING BaseDllName;
    // ... 
} LDR_DATA_TABLE_ENTRY, *PLDR_DATA_TABLE_ENTRY;

typedef struct _PEB {
    BYTE Reserved1[12];
    PPEB_LDR_DATA Ldr;
    // Các trường khác không cần thiết cho chương trình này
} PEB, *PPEB;

// Hàm lấy PEB phù hợp với kiến trúc
PPEB GetPEB(void) {
// Kiến trúc 64-bit
        PPEB peb = NULL;
        peb = (PPEB)__readgsqword(0x60);    // Sử dụng __readgsqword cho x64
        return peb;
    }

// Hàm so sánh chuỗi Unicode
int unicode_cmp(const wchar_t* str1, const wchar_t* str2) {
    while (*str1 && *str2) {
        if (*str1 != *str2) {
            return 1; // Khác nhau
        }
        str1++;                    // tăng địa chỉ lên 2 byte
        str2++;
    }
    
    if (*str1 == *str2) {           // Kiểm tra cả hai chuỗi đều kết thúc
        return 0; // Bằng nhau
    } 
    else {
        return 1; // Khác nhau
    }
}

// Hàm lấy địa chỉ hàm từ DLL
FARPROC Get_function_address() {   
    wchar_t Module_nameW[] = L"USER32.dll";
    wchar_t Function_nameW[] = L"MessageBoxA";
    
    // Lấy PEB (Process Environment Block)
    PPEB pPeb = GetPEB();
    if (!pPeb) {
        return NULL;                        // không lấy được peb
    }

    PPEB_LDR_DATA pLdr = pPeb->Ldr;        // Lấy con trỏ đến PEB_LDR_DATA
    
    PLIST_ENTRY pModuleList = &(pLdr->InMemoryOrderModuleList);    // Lấy danh sách module đã load (InMemoryOrderModuleList)
    PLIST_ENTRY pEntry = pModuleList->Flink;                       // phần tử đầu tiên của danh sách - thường là ntdll.dll
    PLIST_ENTRY pFirstEntry = pEntry;
    
    // Duyệt qua danh sách module
    do {
        PLDR_DATA_TABLE_ENTRY pDataEntry = (PLDR_DATA_TABLE_ENTRY)((BYTE*)pEntry - offsetof(LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks));

        BYTE* moduleBase = *((BYTE**)(((BYTE*)pEntry) + 0x10)); // DllBase
        wchar_t* moduleName = *((wchar_t**)(((BYTE*)pEntry) + 0x48)); // BaseDllName.Buffer
        if (moduleName) {
            wprintf(L"%s\n", moduleName);
            
            // So sánh tên module
            if (unicode_cmp(moduleName, Module_nameW) == 0) {
                // Tìm thấy module cần tìm
                // Lấy địa chỉ PE header
                DWORD peHeader = *(DWORD*)(moduleBase + 0x3C);
                DWORD exportTableRVA = *(DWORD*)(moduleBase + peHeader + 0x78);
                
                if (exportTableRVA == 0) {
                    return NULL;
                }
                
                // Lấy bảng Export
                BYTE* exportTable = moduleBase + exportTableRVA;
                
                // Lấy các mảng quan trọng
                DWORD* addressOfNames = (DWORD*)(moduleBase + *(DWORD*)(exportTable + 0x20));
                WORD* addressOfOrdinals = (WORD*)(moduleBase + *(DWORD*)(exportTable + 0x24));
                DWORD* addressOfFunctions = (DWORD*)(moduleBase + *(DWORD*)(exportTable + 0x1C));
                
                // Số lượng hàm export
                DWORD numberOfNames = *(DWORD*)(exportTable + 0x14);
                
                // Tìm hàm theo tên
                for (int i = numberOfNames - 1; i >= 0; i--) {
                    char* functionName = (char*)(moduleBase + addressOfNames[i]);
                    
                    // Chuyển đổi sang wchar_t để so sánh
                    wchar_t wideFunctionName[256] = {0};
                    for (int j = 0; functionName[j]; j++) {
                        wideFunctionName[j] = (wchar_t)functionName[j];
                    }
                    
                    if (unicode_cmp(wideFunctionName, Function_nameW) == 0) {
                        // Tìm thấy hàm
                        WORD ordinal = addressOfOrdinals[i];
                        DWORD functionRVA = addressOfFunctions[ordinal];
                        return (FARPROC)(moduleBase + functionRVA);
                    }
                }
            }
        }
        
        pEntry = pEntry->Flink;
    } while (pEntry != pFirstEntry);
    
    return NULL;
}

int main() {
    char msg_title[] = "MessageBoxA";
    char msg_text[] = "da tim thay";
    char msg_not_found[] = "khong tim thay";
    
    // Lấy địa chỉ hàm MessageBoxA
    typedef int (WINAPI *MessageBoxAFunc)(HWND, LPCSTR, LPCSTR, UINT);
    MessageBoxAFunc messageBoxFunc = (MessageBoxAFunc)Get_function_address();
    
    if (messageBoxFunc) {
        // Gọi hàm MessageBoxA với các tham số
        messageBoxFunc(NULL, msg_text, msg_title, 0);
        ExitProcess(0);
    } else {
        printf("%s\n", msg_not_found);
        ExitProcess(0);
    }
    
    return 0;
}
```

Em code bằng minGW nên sử dụng kiến trúc x64. Offset có thể khác nhau giữa x86 và x64.

```c
BYTE* moduleBase = *((BYTE**)(((BYTE*)pEntry) + 0x10));         // DllBase
        wchar_t* moduleName = *((wchar_t**)(((BYTE*)pEntry) + 0x48));     // BaseDllName.Buffer
```
Đầu tiên là ép kiểu pEntry từ PLIST_ENTRY -> con trỏ  byte để cộng với 0x10. Sau đó lại ép kiểu thành một con trỏ đến con trỏ BYTE. Cả câu lệnh cho ra 1 con trỏ byte chứa offset của DLLBase. Tương tự với moduleName.

Đến đây code của em bị lỗi `PLIST_ENTRY pEntry = pModuleList->Flink;`. Đoạn này pEntry = 0x0 nên ko thể tham chiếu được

![Capture1](https://github.com/user-attachments/assets/e100a0d7-45f0-4df6-a611-da6e2922df62)


```asm
include C:\masm32\include\masm32rt.inc
assume fs:nothing
includelib C:\masm32\lib\user32.lib
extern MessageBoxA@16:proc

.data
dummy_ref dd MessageBoxA
Module_nameW dw 'U', 'S', 'E', 'R', '3', '2', '.', 'd', 'l', 'l', 0         ; UNICODE
Function_nameW dw 'M', 'e', 's', 's', 'a', 'g', 'e', 'B', 'o', 'x', 'A', 0   ; UNICODE
msg_title db "MessageBoxA", 0
msg_text db "da tim thay", 0
msg_not_found db "khong tim thay", 0

.code
unicode_cmp proc
    push esi
    push edi
    push ebx
    mov esi, eax   
    mov edi, edx 
    xor eax, eax
    xor ebx, ebx

loop_cmp:
    mov ax, [esi]
    mov bx, [edi]
    cmp ax, bx                   ; so sanh 2 byte
    jne not_equal  

    test ax, ax                  ; kiem tra ket thuc chuoi
    jz equal                    

    add esi, 2                   ; dich sang ky tu tiep
    add edi, 2
    jmp loop_cmp

not_equal:
    pop ebx
    pop edi
    pop esi
    mov eax, 1                  ; tra ve 1 neu khac
    ret

equal:
    pop ebx
    pop edi
    pop esi
    xor eax, eax                ; tra ve 0 neu bang nhau
    ret

unicode_cmp endp

Get_function_address proc 
	push ebp
	mov	ebp, esp

	mov eax, fs:[30h]               ; offset PEB
	mov eax, [eax + 0Ch]            ; PEB_LDR_DATA - danh sach module da load trong tien trinh
	mov esi, [eax + 1Ch]        	; InMemoryOrderModuleList danh sach cac dll da load
    mov esi, [esi+4]                ; head
    mov ebx, esi                    ; luu dia chi head

find_module:
    mov esi, [esi]                ; duyet module ke tiep trong dslk doi
    cmp esi, ebx                  ; neu quay tro lai dau danh sach -> duyet xong
    je not_found

    mov edi, [esi + 8]            ; dia chi thuc te cua dll

    mov eax, [esi + 20h]             ; ten dll
    invoke crt_wprintf, eax

    mov eax, [esi + 20h]
    mov edx, offset Module_nameW
    call unicode_cmp                 ; so sanh ten dll
    

    test eax, eax
    jnz find_module               ; khong khop tim tiep

                   
    jmp parse_exports

 ; vi du qua trinh duyet module:
 ;head -> [ntdll.dll] -> [kernelbase.dll] -> [kernel32.dll] -> [user32.dll] -> head - > [ntdll.dll] (quay lai dau).

not_found:
    pop ebp
    xor eax, eax
    ret

parse_exports:
    mov edx, edi                 ; dia chi thuc te cua dll
    mov eax, [edx + 3Ch]         ; offset PE Header 
    add eax, edx                 ; tinh dia chi thuc te cua PE Header
   ; mov ecx, IMAGE_DIRECTORY_ENTRY_EXPORT * 8
    mov eax, [eax + 78h]         ; lay Export Table RVA
    add eax, edx 
    test eax, eax
    jz not_found

    add eax, edx                 ; chuyen RVA thanh dia chi thuc te
    mov ecx, [eax + 20h]         ; AddressOfNames: bang chua danh sach ten ham
    add ecx, edx                 ; chuyen RVA thanh dia chi thuc te
    mov [esp-28], ecx            ; luu AddressOfNames vao stack

    mov ecx, [eax + 24h]         ; AddressOfOrdinals
    add ecx, edx                 ; RVA -> dia chi thuc te
    mov [esp - 32], ecx          ; luu vao stack

    mov ecx, [eax + 1Ch]         ; AddressOfFunctions
    add ecx, edx                 ; RVA -> dia chi thuc te
    mov [esp - 36], ecx          ; luu vao stack

find_function:
    mov ecx, [eax + 14h]         ; NumberOfNames
    test ecx, ecx
    jz not_found

    dec ecx                       ; duyet tu cuoi ve dau
    mov eax, [esp - 28]           ; AddressOfNames
    mov esi, [eax + ecx * 4]      ; Function name RVA
    add esi, edx                  ; dia chi thuc te
    push eax
    push edx
    mov edx, offset Function_nameW
    mov eax, esi    
    call unicode_cmp               ; So sanh ten ham
    pop eax
    pop edx
    test eax, eax
    jnz find_function

    cmp ecx,0
    ja find_function

    mov eax, [esp - 32]            ; AddressOfOrdinals
    mov cx, [eax + ecx * 2]        ; lay ordinal
 ;cx chua ordinal cua ham can tim

    mov eax, [esp - 36]            ; AddressOfFunctions
    mov eax, [eax + ecx * 4]       ; Function RVA
    add eax, edx                   ; dia chi thuc te
    pop ebp
    ret
Get_function_address endp

main proc
    ;push offset Module_nameW
    ;call LoadLibraryW

    call Get_function_address

    test eax, eax
    jz not_found

    push 0
    push offset msg_text
    push offset msg_title
    push 0
    call eax
    push 0
    call ExitProcess

not_found:
    push offset msg_not_found
    call crt_printf
    push 0
    call ExitProcess
main endp
end main
```

Em sử dụng masm32 nên kiến trúc là x86.

Danh sách các module cho đến user32.dll

![image](https://github.com/user-attachments/assets/8309d47e-bc88-4b37-8c6a-6a75c09eb056)

```asm
    mov eax, [edx + 3Ch]         ; offset PE Header 
    add eax, edx                 ; tinh dia chi thuc te cua PE Header
```
Em trỏ đúng đến địa chỉ PE header: PE/0/0

![Capture1](https://github.com/user-attachments/assets/8a9a4873-3cf0-45dc-a4e3-4d6cf1e68cf6)

Em sai ở `parse_exports`. Em bị lỗi ở  `mov eax, [eax + 78h]         ; lay Export Table RVA`. Em không trỏ đến đúng địa chỉ bảng. Em cũng không tìm được luôn.

![Capture1](https://github.com/user-attachments/assets/11c9da74-cdf2-4496-b6fd-ae4526ef7b1a)

chatGPT bảo IMAGE_DIRECTORY_ENTRY_EXPORT = 0 là không có export table.

[bảng PE file format(64-bit)](https://upload.wikimedia.org/wikipedia/commons/1/1b/Portable_Executable_32_bit_Structure_in_SVG_fixed.svg)
