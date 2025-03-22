%include "io.inc"

section .data
msg1 db 'Nhap key:', 0
msg2 db 'Nhap text:', 0
msg3 db 'RC4:', 0

section .bss
s            resb 256
key          resb 257
keystream    resb 1000
text         resb 1000
key_len      resd 1
text_len     resd 1
encoded_text resb 1000
section .text 
global main

main:
    mov ebp, esp             
    PRINT_STRING msg1        ; hàm in string của sasm
    GET_STRING key, 256      ; nhập string của sasm
    lea esi, [key]
    call remove_newline
    NEWLINE                  ; xuống dòng của sasm
    
    PRINT_STRING msg2
    GET_STRING text, 1000
    NEWLINE
    
    lea esi, [text]
    call remove_newline
    
    xor ecx, ecx            ; làm sạch thanh ghi trước khi gọi hàm
    call tao_s
    
    lea esi, [key]   ; lưu offset key để đếm
    xor ecx, ecx     ; i hàm đếm
    call demPT
    mov [key_len], eax
    call ksa
    
    lea esi, [text]  ; lưu offset text để đếm
    xor ecx, ecx     ; i hàm đếm
    call demPT
    mov [text_len], eax
    call prga
    
    PRINT_STRING msg3
    xor ecx, ecx    ; i hàm encode_text
    call encode_text
    call print_hex
    ret
    
remove_newline:
    mov ecx, 0
loop_remove:
    movzx eax, byte [esi + ecx]
    cmp eax, 0        ; so sánh với '\0'
    je done_remove          ; nếu là phần tử cuối thì trả về hàm
    cmp eax, 10       ; so sánh với '\n'
    jne continue_remove     ; nếu là xuống dòng thì xóa 
    mov byte [esi + ecx], 0
    jmp done_remove
continue_remove:
    inc ecx
    jmp loop_remove
done_remove:
    ret
    
tao_s:          
    mov [s + ecx], cl   ; s[i] = i
    inc ecx             ; i++
    cmp ecx, 256        ; i < 256
    jl tao_s
    ret
    
demPT:
    xor eax, eax
    movzx eax, byte [esi +ecx]     ;esi chứa offset chuỗi, eax chứa ký tự thứ i
    inc ecx         
    cmp eax, 0                     ; so sánh ký tự i với '\0'
    jne demPT 
    mov eax, ecx                   ; lưu eax = len
    dec eax                        ; ko đếm '\0'
    ret
    
dao:
    push eax
    push ebx
    mov al, [s+esi]   ; al = s[j] 
    mov bl, [s+ecx]   ; bl = s[i]
    mov [s+esi], bl  
    mov [s+ecx], al 
    pop ebx
    pop eax
    ret
    
ksa:
    mov edi, [key_len]   ; edi = key_len
    xor ecx, ecx         ; i hàm s1
    xor esi, esi         ; j hàm s1
ksa_loop:
    xor eax, eax  
    xor ebx, ebx     
    mov eax, ecx        ; eax = i
    xor edx, edx
    div edi             ; i % key_len
    mov bl, [key+edx]   ; key[i % len]
    add bl, [s+ecx]     ; s[i]
    add esi, ebx        ; j  = j + s[i] + k[i % len]
    and esi, 0xff       ; % 256
    call dao
    inc ecx             ;i++
    cmp ecx, 256        ;i < 256
    jl ksa_loop
    ret
    
prga:
    xor ecx, ecx                ; i hàm s2
    xor esi, esi                ; j hàm s2
    xor edi, edi                ; n hàm s2
    xor eax, eax
    xor ebx, ebx
prga_loop:
    inc ecx                     ; i+1
    and ecx, 0xff               ; i = (i+1) % 256
    movzx ebx, byte [s+ecx]
    add esi, ebx                ; j = j + s[i]
    and esi, 0xff               ; % 256
    call dao
    xor ebx, ebx
    movzx ebx, byte [s+ecx]     ; s[i]
    movzx eax, byte [s+esi]     ; s[j]
    add eax, ebx                ; t = s[j] + s[i]
    and eax, 0xff               ; % 256
    xor ebx, ebx
    movzx ebx, byte [s+eax]    ; eax = t, ebx = s[t]
    mov [keystream+edi], bl    ; k[n] = s[t]
    inc edi                    ; n++
    cmp edi, [text_len]        ;n < text_len
    jl prga_loop
    ret
    
encode_text:
    mov al, [text+ecx]            ; text[i]
    mov bl, [keystream+ecx]       ; keystream[i]
    xor al, bl                    ; text[i] ^ keystream[i]
    mov [encoded_text+ecx], al
    inc ecx                       ; i++
    cmp ecx, [text_len]           ; i < text_len
    jl encode_text
    ret
    
print_hex:
    xor ecx, ecx
loop_print_hex:
    xor eax, eax
    movzx eax, byte [encoded_text+ecx]
    shr al, 4                                   ; kiểm tra xem định dạnh hex có phải là 0x0(x) ko
    cmp al, 0
    jne in_xx                                   ; nếu ko thì in bth
in_0x:
    PRINT_DEC 1, 0                              ; thêm 0 vào 
in_xx:
    PRINT_HEX 1, [encoded_text+ecx]
    inc ecx                                     ; i++
    cmp ecx, [text_len]                         ; i < text_len
    jl loop_print_hex
    ret
