include Irvine32.inc ; Goi thu vien


.data
tieude db 'Ket qua' , 0
text db 'Sai roi' , 0


.code
main proc                       ; Khai bao ham
invoke MessageBox,              ; Goi ham MessageBox
       0,                       ; hWnd
       addr text,               ; noi dung box
       addr tieude,              ; tieu de box
       MB_OK                    ; nut ok

invoke ExitProcess,0            ; Ket thuc qua trinh va thoat


main endp                       ; ket thuc ham main
end main                        ; ket thuc chuong trinh
