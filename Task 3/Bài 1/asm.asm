include Irvine32.inc

.data
a TBYTE  0		; bien 10 byte - 80 bit du de chua fibo100
b TBYTE  0
d TBYTE  0
sochia dw 16	; so 16
fibo100 db 30 DUP(0)
byte_trung_gian db 0

.code
main proc
	mov		ebp, esp
	mov		ecx, 2						; i = 2

	mov		WORD PTR [a], 1				; mov 2 byte dau cua a = 1
	mov		DWORD PTR [a+2], 0			; mov 4 byte giua cua a = 0
	mov		WORD PTR [a+6], 0			; mov 4 byte cuoi cua a = 0

	mov		WORD PTR [b], 0			
	mov		DWORD PTR [b+2], 0			
	mov		WORD PTR [b+6], 0


	xor		eax, eax
	xor		ebx, ebx
	xor		edx, edx
	lea		esi, [a]									; luu esi = OFFFSET a de xem vi tri a
for_fibo:
	mov		ax, WORD PTR [a]							; eax = 2 byte dau cua a
	mov		ebx, DWORD PTR [a+2]						; ebx = 4 byte giua cua a
	mov     edx, DWORD PTR [a+6]						; edx = 4 byte cuoi cua a

	mov		WORD PTR [d], ax							; d = a
	mov		DWORD PTR [d+2], ebx						
	mov		DWORD PTR [d+6], edx						

	add		ax, WORD PTR [b]							; cong 2 byte dau cua b voi eax
	adc		ebx, DWORD PTR [b+2]						; cong 4 byte giua cua b voi ebx va Carry Flag o tren
	adc		edx, DWORD PTR [b+6]						; cong 4 byte cuoi cua b voi edx va Carry Flag o tren

	mov		WORD PTR [a], ax							; a = a + b
	mov		DWORD PTR [a+2], ebx						
	mov		DWORD PTR [a+6], edx
	
	mov		ax, WORD PTR [d]							; eax = 2 byte dau cua d
	mov		ebx, DWORD PTR [d+2]						; ebx = 4 byte giua cua d
	mov     edx, DWORD PTR [d+6]						; edx = 4 byte cuoi cua d

	mov		WORD PTR [b], ax							; b = d
	mov		DWORD PTR [b+2], ebx						 
	mov		DWORD PTR [b+6], edx						 

	inc		ecx
	cmp		ecx, 100
	jle		for_fibo					

	lea		esi, [a]									; luu esi = OFFFSET a de xem vi tri a
	mov		BYTE PTR [a+10], 0							; dat ket thuc chuoi
	mov		ecx, 0										; phan tu dem

dem_PT:
	xor		eax, eax									; lam sach eax sau moi vong lap
	mov		al, BYTE PTR [a+ecx]						; eax = tung byte 1 cua fibo100
	inc		ecx
	test	eax, eax									; kiem tra tung phan tu voi 0
	jnz		dem_PT

	xor		ebx, ebx									; lam sach ebx
	dec		ecx											; bo phan tu 0

fibo_hex:
	dec		ecx
	mov		al, BYTE PTR [a+ecx]						; lay phan tu cuoi

div_loop:
	xor		edx, edx									; lam sach edx
	div		sochia										; chia cho 16
	cmp		dl, 9										; neu dl < 10 thi chuyen sang he hex 0-9
	jle		hex0_9
	
	cmp		dl, 10										; neu dl >= 10 thi chuyen sang he hex A-F
	jge		hexA_F

hex0_9:
	add		edx, 30h									; chuyen sang he hex 0-9
	test	eax, eax									; kiem tra da chia het chua
	jnz		dao_trong_1byte
	
	mov		fibo100[ebx], dl							; luu pt dau cua byte vao mang fibo100
	inc		ebx
	push	ecx
	mov		cl, [byte_trung_gian]
	mov		fibo100[ebx], cl							; luu pt cuoi cua byte vao mang fibo100
	inc		ebx
	pop		ecx
	test	ecx, ecx									; kiem tra chuoi het chua
	jz		in_fibo
	
	jmp		fibo_hex

hexA_F:
	add		edx, 37h									; chuyen sang he hex A-F
	test	eax, eax									; kiem tra da chia het chua
	jnz		dao_trong_1byte

	mov		fibo100[ebx], dl							; luu pt dau cua byte vao mang fibo100
	inc		ebx
	push	ecx
	mov		cl, [byte_trung_gian]
	mov		fibo100[ebx], cl							; luu pt cuoi cua byte vao mang fibo100
	inc		ebx
	pop		ecx
	test	ecx, ecx									; kiem tra chuoi het chua
	jz		in_fibo
	
	jmp		fibo_hex

dao_trong_1byte:
	mov		[byte_trung_gian], dl						; luu phan tu cuoi cua byte vao bien trung gian
	jmp		div_loop

in_fibo:
	lea		edx, [fibo100]
	call	WriteString
	push	0
	call	ExitProcess

main		endp
end main