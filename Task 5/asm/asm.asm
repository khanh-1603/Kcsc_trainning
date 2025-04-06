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
 ; [ntdll.dll] -> [kernelbase.dll] -> [kernel32.dll] -> [user32.dll] -> [ntdll.dll] (quay lai dau).

not_found:
    pop ebp
    xor eax, eax
    ret

parse_exports:
    mov edx, edi                 ; dia chi thuc te cua dll
    mov eax, [edx + 3Ch]         ; offset PE Header 
    add eax, edx                 ; tinh dia chi thuc te cua PE Header
   ; mov ecx, IMAGE_DIRECTORY_ENTRY_EXPORT * 8
    mov eax, DWORD PTR [eax + 78h]         ; lay Export Table RVA
    ;add eax, ecx 
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