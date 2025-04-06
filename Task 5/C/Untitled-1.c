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

typedef struct _PEB {
    BYTE Reserved1[12];
    PPEB_LDR_DATA Ldr;
    // Các trường khác không cần thiết cho chương trình này
} PEB, *PPEB;

// Hàm lấy PEB phù hợp với kiến trúc
PPEB GetPEB(void) {
    // x64: sử dụng gs:[0x60]
    PPEB peb = NULL;
    __asm__ (
        "movl %rax, gs:[0x60]"
        "movl [peb], %rax"
    );
    return peb;
}

// Hàm so sánh chuỗi Unicode
int unicode_cmp(const wchar_t* str1, const wchar_t* str2) {
    while (*str1 && *str2) {
        if (*str1 != *str2) {
            return 1; // Khác nhau
        }
        str1++;
        str2++;
    }
    
    // Kiểm tra cả hai chuỗi đều kết thúc
    if (*str1 == *str2) {
        return 0; // Bằng nhau
    } else {
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
        return NULL;
    }
    
    // Lấy con trỏ đến PEB_LDR_DATA
    PPEB_LDR_DATA pLdr = pPeb->Ldr;
    
    // Lấy danh sách module đã load (InMemoryOrderModuleList)
    PLIST_ENTRY pModuleList = &(pLdr->InMemoryOrderModuleList);
    PLIST_ENTRY pEntry = pModuleList->Flink;
    PLIST_ENTRY pFirstEntry = pEntry;
    
    // Duyệt qua danh sách module
    do {
        // LDR_DATA_TABLE_ENTRY cấu trúc
        // Offset có thể khác nhau giữa x86 và x64
#ifdef _WIN64
        // x64 offsets
        BYTE* moduleBase = *((BYTE**)(((BYTE*)pEntry) + 0x10)); // DllBase
        wchar_t* moduleName = *((wchar_t**)(((BYTE*)pEntry) + 0x48)); // BaseDllName.Buffer
#else
        // x86 offsets
        BYTE* moduleBase = *((BYTE**)(((BYTE*)pEntry) + 0x08)); // DllBase
        wchar_t* moduleName = *((wchar_t**)(((BYTE*)pEntry) + 0x28)); // BaseDllName.Buffer
#endif
        
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