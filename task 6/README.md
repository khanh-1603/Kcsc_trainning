# ThitNhi.exe
![image](https://hackmd.io/_uploads/r1GNAeB0yx.png)

Đoạn này chỉ là nhập `flag` và sửa giá trị của `v11`.

![image](https://hackmd.io/_uploads/BJ8l81t0Je.png)

![image](https://hackmd.io/_uploads/r1-wwkKCJx.png)


Hàm đầu là đếm số byte của main. Kết thúc khi chạy đến 0xC3 (ret).

![image](https://hackmd.io/_uploads/Hkfdv1Y0kg.png)

Hàm 2 là antidebug. Hàm này truy tìm `software breakpoint`. Lấy từng byte ^ 0x55. Nếu có `software breakpoint` (0xcc) thì sẽ ra 0x99.

![image](https://hackmd.io/_uploads/HJuf6eKCkg.png)

Hàm main có chứa byte `0xcc` nên hàm antidebug không ảnh hưởng đến hàm main.

![image](https://hackmd.io/_uploads/rk8bAlKA1l.png) ![image](https://hackmd.io/_uploads/HkjGCeFAkl.png)

Đây là `v7` ở main. Giá trị không đổi.

Em xác định được hàm bên dưới là mã hóa RC4.

![image](https://hackmd.io/_uploads/HJS9KJY01l.png)
![image](https://hackmd.io/_uploads/HyvgjyYCyl.png)


Hàm này cũng tìm `software breakpoint` và tạo key dựa trên kết quả trả về của hàm antidebug. 

Hàm RC4 không có byte `0xcc` nên antidebug có ảnh hưởng đến hàm này.

Để bypass đầu tiên ta nhảy đến lệnh gọi hàm antidebug.
![image](https://hackmd.io/_uploads/ryD1JbF0kx.png)

![image](https://hackmd.io/_uploads/ryNMkbYA1l.png)
![image](https://hackmd.io/_uploads/S1tVJZFR1g.png)

Hàm này có 2 giá trị. nếu có `software breakpoint` thì` mov eax, 13h`. Nên ta chỉ cần `set ip` sang bên `mov eax, 37h` là xong.

![image](https://hackmd.io/_uploads/HJpQ-bFRJx.png)
Ta tìm được key là DEADBF33

`for` đầu là tạo s-box và tạo key
`for` 2 hoán vị s theo key
`for` cuối là tạo keystream và mã hóa.

Mục đích là làm sao cho `v9 = 7D 08 ED 47 E5 00 88 3A 7A 36 02 29 E4 00`

Do v9 chứa 00 nên không chuyển sang string được. Cần tạo hàm mã hóa cho hexstring.

Code c
```c
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

int main()
{
unsigned char v7[512];
int i, j, k, t;
unsigned char temp;
char v9[14];
char buffer[14] ={0x7d, 0x08, 0xed, 0x47, 0xe5, 0x00, 0x88, 0x3a, 0x7a, 0x36, 0x02, 0x29, 0xe4, 0x00};
int v13 = 0;
int  v8 = 0;
int  v10 = 0;
char v14;

// Bước 1: Tạo S-box
unsigned char K[4] = {0x33, 0xBF, 0xAD, 0xDE};
for ( i = 0; i < 256; ++i )
  {
    v7[i + 256] = i;
    v7[i] = *((unsigned char *)K + i % 4);
  }
  for ( j = 0; j < 256; ++j )
  {
    v13 = ((unsigned __int8)v7[j] + v13 + (unsigned __int8)v7[j + 256]) % 256;
    v14 = v7[v13 + 256];
    v7[v13 + 256] = v7[j + 256];
    v7[j + 256] = v14;
  }
  v13 = 0;
  for ( k = 0; k < 13; ++k )
  {
    v10 = (v10 + 1) % 256;
    v13 = (v13 + (unsigned __int8)v7[v10 + 256]) % 256;
    v14 = v7[v13 + 256];
    v7[v13 + 256] = v7[v10 + 256];
    v7[v10 + 256] = v14;
    v8 = ((unsigned __int8)v7[v13 + 256] + (unsigned __int8)v7[v10 + 256]) % 256;
    *(unsigned char *)(k + v9) = v7[v8 + 256] ^ *(unsigned char *)(k + buffer);
  }
  for(i=0; i<13; i++){
    printf("%02X ", v9[i]);
  }
  return 0;
}
```
![image](https://hackmd.io/_uploads/B1Te2xK0Jl.png)

Chuyển sang string là `D1t_m3_H4_N41`.

![image](https://hackmd.io/_uploads/rk5DngK0kl.png)

# replace.exe
![image](https://hackmd.io/_uploads/H1LuKGY01g.png)
Nhìn sơ qua

`v11 = VdlKe9upfBFkkO0L`

`buff2 = 19 2C 30 2A 79 F9 54 02 B3 A9 
         6C D6 91 80 95 04 29 59 E8 A3 
         0F 79 BD 86 AF 05 13 6C FE 75 
         DB 2B AE E0 F0 5D 88 4B 86 89 
         33 66 AC 45 9A 6C 78 A6`
(48 ký tự)

![image](https://hackmd.io/_uploads/Sym2GQKR1e.png)

Ở `if` đầu.
strlen sẽ tính cả ký tự `\0`.

Nếu `if` chạy:
Rút gọn lại.
```c
  int v9 = strlen;
  int v4 = strlen % 8;
  if ( v9 % 8 )
  {
    for ( i = 0; i < 8 - v4; ++i )
      Buffer[v9 - 1 + i] = 10; //\n
    v9 += 8 - v4;
```
- Đoạn này đặt ký tự xuống dòng cho `buffer` tại ký tự cuối của chuỗi thường là `\n` hoặc `\0`. Tối đa 7 ký tự.
- Sau đó tăng strlen lên đúng bằng số ký tự thay đổi.

![image](https://hackmd.io/_uploads/By5aVYRAkl.png)

Ta tập trung vào hàm `for` dưới cùng.
Nếu lần lượt 8 byte `buffer` khác `buf2` thì sai.

`Buf2` dài 48 byte.
=> `flag` dài 48 ký tự.

Tính j max:
- stlen = 49 => v9 = 49 + 8 - 1 = 56;
- 56/8 = 7
=> lặp 7 lần.

Ở lần lặp thứ 7 ta sẽ so sánh chuỗi 7 ký tự `\n` và ký tự `\0`.
Trước đó `buffer` tham gia vào 1 hàm khác.

![image](https://hackmd.io/_uploads/ryfy3GY0Je.png)
Hàm này lấy 8 byte `buffer`.

Sau `if` `buffer` và `buf2` sẽ tăng 8 byte.

Hàm sub rút gọn như sau:
```c    
    buffer[0] ^= v11[0] + v11[1];  
    buffer[1] ^= v11[2] + v11[3];
    return buffer[1];
```
Trong đó `v11` là 1 mảng 4 byte có 4 phần tử:
- v11[0] = 0x4B6C6456 (VdlK)
- v11[1] = 0x70753965 (e9up)
- v11[2] = 0x6B464266 (fBFk)
- v11[3] = 0x4C304F6B (kO0L)
`v11[0] + v11[1] = 0xBBE19DBB`
`v11[2] + v11[3] = 0xB77691D1`

`Buffer` là 1 mảng 4 byte có 2 phần tử. Tổng 8 byte

Yêu cầu sau hàm sub thì `buffer = buf2`

Vậy nên ta xor `buf2` với `v11`. Đổi buf2 theo thứ tự little endian:
 `19 2C 30 2A 79 F9 54 02` -> `0x2A302C19, 0x0254F979`
 `B3 A9 6C D6 91 80 95 04` -> `0xD66CA9B3, 0x04958091`
 `29 59 E8 A3 0F 79 BD 86` -> `0xA3E85929, 0x86BD790F`
 `AF 05 13 6C FE 75 DB 2B` -> `0x6C1305AF, 0x2BDB75FE`
 `AE E0 F0 5D 88 4B 86 89` -> `0x5DF0E0AE, 0x89864B88`
 `33 66 AC 45 9A 6C 78 A6` -> `0x45AC6633, 0xA6786C9A`
 Làm lần lượt từng dòng được
 
 ```c
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include <stdint.h>

int main ()
{
uint32_t buffer[] ={
    0x2A302C19, 0x0254F979, 0xD66CA9B3, 0x04958091,
    0xA3E85929, 0x86BD790F, 0x6C1305AF, 0x2BDB75FE,
    0x5DF0E0AE, 0x89864B88, 0x45AC6633, 0xA6786C9A
};
uint32_t v11[2] ={0xBBE19DBB, 0xB77691D1};

uint32_t flag[2];
int i;
for ( i = 0; i < 6; i++) {
  buffer[i % 12] ^= v11[0];
  flag[0] = buffer[i % 12];

  buffer[i % 12 +1] = buffer[i % 12 +1] ^ v11[1];
  flag[1] = buffer [i % 12 +1];

  printf("%08X %08X ", flag[0],flag[1]);
}
return 0;
}
```
Tuy nhiên nó trả về dãy hex không dịch được. Có thể có `anti debug`. `main` không có hàm `anti debug` nào. Nhưng trong danh sách hàm có `TlsCallback`. 

![image](https://hackmd.io/_uploads/BycUnkZJle.png)
Hàm này có `WriteProcessMemory` có tác dụng ghi dữ liệu vào không gian bộ nhớ của 1 tiến trình khác. Có nghĩa là nó sẽ thay đổi opcode.

![image](https://hackmd.io/_uploads/HkwfaJWyee.png)

Nó sẽ thay đổi dòng `call sub_401180` thành 1 lệnh khác.

Việc ta cần làm làm sửa `if` để nó chạy qua.

![image](https://hackmd.io/_uploads/ByaD01-keg.png)

`jnz` -> `jz`.

![image](https://hackmd.io/_uploads/B10GJx-Jxl.png)

Giờ ta kiểm tra sự thay đổi ở `main`.

![image](https://hackmd.io/_uploads/HyxqMebJgg.png)

Đã gọi hàm khác.

![image](https://hackmd.io/_uploads/B1Y2Ggb1ee.png)

Đây là mã hóa TEA (Tiny Encryption Algorithm).

```c
#include <stdio.h>
#include <string.h>
#include <stdint.h>

// Hàm giải mã TEA
int __fastcall tea_decrypt(unsigned int *a1, uint32_t *a2) {
    int result;
    unsigned int i;
    int v4;
    unsigned int v5;
    unsigned int v6;
    
    v6 = *a1;
    v5 = a1[1];
    v4 = -0x61C88647 * 32; // Giá trị delta sau 32 vòng lặp (sẽ tràn số đúng như mong muốn)
    
    for (i = 0; i < 32; ++i) {
        v5 -= (a2[3] + (v6 >> 5)) ^ (v4 + v6) ^ (a2[2] + 16 * v6);
        v6 -= (a2[1] + (v5 >> 5)) ^ (v4 + v5) ^ (*a2 + 16 * v5);
        v4 += 0x61C88647;
    }
    
    *a1 = v6;
    result = 4;
    a1[1] = v5;
    return result;
}

int main() {
    unsigned char buf2[] = {
        0x19, 0x2c, 0x30, 0x2a, 0x79, 0xf9, 0x54, 0x02, 
        0xb3, 0xa9, 0x6c, 0xd6, 0x91, 0x80, 0x95, 0x04, 
        0x29, 0x59, 0xe8, 0xa3, 0x0f, 0x79, 0xbd, 0x86, 
        0xaf, 0x05, 0x13, 0x6c, 0xfe, 0x75, 0xdb, 0x2b, 
        0xae, 0xe0, 0xf0, 0x5d, 0x88, 0x4b, 0x86, 0x89, 
        0x33, 0x66, 0xac, 0x45, 0x9a, 0x6c, 0x78, 0xa6
    };
    
    char v11[] = "VdlKe9upfBFkkO0L";
    uint32_t v11_as_int[4]; 
    
    // Chuyển đổi khóa thành mảng 4 số nguyên 32-bit
    memcpy(v11_as_int, v11, 16);
    
    // Giải mã từng khối 8 byte (2 số nguyên 32-bit) trong dữ liệu
    unsigned int *buffer = (unsigned int *)buf2;
    int len = 48 / 8; // 48 byte = 6 khối, mỗi khối 8 byte
    
    for (int i = 0; i < len; i++) {
        tea_decrypt(&buffer[i*2], v11_as_int);
    }
    
    printf("\nKết quả giải mã (hex):\n");
    for (int i = 0; i < 48; i++) {
        printf("%02X ", buf2[i]);
        if ((i+1) % 8 == 0) printf("\n");
    }
    
    printf("\nKết quả giải mã (ASCII):\n");
    for (int i = 0; i < 48; i++) {
        if (buf2[i] >= 32 && buf2[i] <= 126) {
            printf("%c", buf2[i]);
        } else {
            printf(".");
        }
    }
    printf("\n");
    
    return 0;
}
```
![image](https://hackmd.io/_uploads/rJGCZI0klg.png)

Em không hiểu sao khi thay vào vẫn sai. Em bí rồi.

flag: PTITCTF{bdc90e23aa0415e94d0ac46a938efcf3} (em thay lại không đúng)


# Antidebug3

Chạy thử thì xuất hiện lỗi chia cho 0.

![image](https://hackmd.io/_uploads/Byy1OMqygg.png)
Khi gặp lỗi thì sẽ nhảy vào hàm này.

### Disassembly
![image](https://hackmd.io/_uploads/Byev_M5ylg.png)

Xuất hiện dòng đỏ. Là kỹ thuật Anti disassembly. Ở đây do cùng nhảy vào loc_4013CD+1 nên có thể có byte thừa. Ta undefine nó.

![image](https://hackmd.io/_uploads/HJy4Fzcyxl.png)

Byte `0E8h` là byte thừa vì đoạn trên nhảy qua nó. Ta bôi đen và bấm C (code) và sửa byte `e8` -> `nop`. Được:

![image](https://hackmd.io/_uploads/SJjsFfqJgg.png)

![image](https://hackmd.io/_uploads/r1G-qzcyll.png)
Ngay dưới ta xuất hiện dòng này. Chỉ có `e8` và `e9` là byte thừa. Dòng này chưa được code nên ta code nó (bấm c).
![image](https://hackmd.io/_uploads/BkPj9Gq1ex.png)

Tiếp tục truy tìm.

![image](https://hackmd.io/_uploads/S1Ywof5Jxl.png)
Đầu tiên undefine đoạn data ở dưới. 
Ta thấy đoạn `jz` luôn nhảy do có `xor eax, eax`(cờ ZF = 1). Hơn nữa địa chỉ nhảy là `loc +2`. Tuy nhiên địa chỉ đó không xuất hiện (từ 133a -> 133e). Ta phải undefine nó.

![image](https://hackmd.io/_uploads/H1lfrhzqyge.png)
Đã có 133c. Ta code đoạn này được.
![image](https://hackmd.io/_uploads/Hk0YnGcyle.png)
Tiếp tục code đoạn data ở dưới. Đoạn trên sửa thành `nop` do bị nhảy qua nên không có tác dụng.

![image](https://hackmd.io/_uploads/BycGTfc1ee.png)
CODE XREF chuyển xanh -> đúng. sửa e8 -> nop.
Đã tìm hết.

Giờ ta đã có thể compile sang C.
Nếu chưa compile được là do chưa có biến. Ta chỉ cần chọn dòng đầu của proc và bấm `P`.

### bắt đầu debug.


![image](https://hackmd.io/_uploads/Bkio0fcJge.png)
4 dòng đầu là để kiểm tra `software breakpoint` (0xCC) và kiểm tra debug (Beingdebug). 

![image](https://hackmd.io/_uploads/S1QX17qyel.png)

v4 ~ `[ebp + var_c]` Nếu nó = 1 thì `1 ^ 0xCD = 0xCC` nên ta sửa jz ở đoạn dưới -> jmp để nó không bị `mov` thành 1.

Tiếp tục sửa đoạn `v3->beingdebug ^ 0xAB` là dòng xanh. Sửa `xor eax, 0ABh` -> `mov eax, 0ABh`. Như vậy dù có debug hay không giá trị luôn là `0ABh`.

![image](https://hackmd.io/_uploads/BkS6x75kgx.png)
Sửa 1 số hàm với biến cho dễ đọc.

![image](https://hackmd.io/_uploads/r1wdNQckge.png)


**Đoạn cần chú ý tiếp là hàm `sub_401400()`**

![image](https://hackmd.io/_uploads/H1vDbX5klx.png)

Hàm này kiểm tra khoảng cách giữa 2 hàm. Nếu ta patch sai thì đoạn này ta sẽ sai.
Ngoài ra còn tìm từng byte của hàm `sub_401330`. Nếu có `0xcc` thì thoát for (`0x55 ^ 153 = 0xcc`).
Vì mục đích của ta là không để nó phát hiên debug nên mặc định là chạy for không gặp lỗi. Khi đó i = v1. 
=> Sửa return -> `return 48879`.
![image](https://hackmd.io/_uploads/rJ5Of79kxe.png)
![image](https://hackmd.io/_uploads/rki9fm9Jgl.png)
![image](https://hackmd.io/_uploads/rkijGXcyll.png)

Trở về main
![image](https://hackmd.io/_uploads/ryRCVQc1lx.png)

đoạn dưới là xor 17 phần tử đầu của buffer với 1. Tạm thời bỏ qua.

kiểm tra biến unk và hàm sub
![image](https://hackmd.io/_uploads/r1vYDZGgxx.png)
Tham số của `sub_401460` là `(int)00D24652` (offset unk). 

![image](https://hackmd.io/_uploads/B1oFQ79kxg.png)

Ta sẽ nhìn qua từng hàm sub
![image](https://hackmd.io/_uploads/HJQWBm9klx.png)
![image](https://hackmd.io/_uploads/BJsR_bMgxg.png)
4 byte là offset unk.

![image](https://hackmd.io/_uploads/BkiUFWMgel.png)
4 byte lưu địa chỉ chứa offset unk

a1 là 0xcdd10:0xd24652. (con trỏ 2 chiều sẽ trỏ vào unk).
Đơn giản hóa:
```c
void sub_101330(int **unk) {
    for (int i = 0; i < 8; ++i)
        ((char *)*unk)[i] ^= 0xAB;

    *unk += 9;  // dịch con trỏ lên 9 byte

    for (int j = 0; j < 12; ++j)
        ((char *)*unk)[j] = ((2 * ((char *)*unk)[j]) | 1) ^ (j + 0xCD);

    *unk += 13; // dịch tiếp 13 byte
}
```
- Đoạn đầu:
    - Truy cập `unk` như một con trỏ `char**`, XOR 8 byte đầu tiên với `0xAB`.
    - `*a1 += 9`: dịch con trỏ đi 9 byte, tức bỏ qua vùng đã xử lý.

![image](https://hackmd.io/_uploads/BkVPibzeel.png)

- Đoạn sau:
    - Lấy 12 byte tiếp theo, thực hiện biến đổi: `((a1 << 1) | 1) ^ (j + 0xCD)`
    - `*a1 += 13`: tiếp tục bỏ qua vùng đã mã hóa.
 
![image](https://hackmd.io/_uploads/SJ4S48flex.png)


![image](https://hackmd.io/_uploads/rJiJdD1lxx.png)

`xor *(short*)unk[2n] với 0xBEEF.`
Có thể hiểu là lấy 2 byte đầu của `offset unk` ^ 0xBEEF.

![image](https://hackmd.io/_uploads/ryjREIMexx.png)

Hàm cuối lại tăng địa chỉ lên 19.
![image](https://hackmd.io/_uploads/r1LhmQ5yge.png)
![image](https://hackmd.io/_uploads/BJksnw1xlg.png)

Có vẻ là hàm này.
Hàm này gây `exception` để break debug. Em tìm được ở giá trị trả về có chứa cờ.

![image](https://hackmd.io/_uploads/BkFPSX5Jll.png)
byte_404118: (100 byte)
`74 6F 69 35 4F 65 6D 32 32 79 42 32 71 55 68 31 6F
5F DB CE C9 EF CE C9 FE 92 5F 10 27 BC 09 0E 17 BA 4D 18 0F BE AB 5F 9C 8E A9 89 98 8A 9D 8D D7 CC DC 8A A4 CE DF 8F 81 89 5F 69 37 1D 46 46 5F 5E 7D 8A F3 5F 59 01 57 67 06 41 78 01 65 2D 7B 0E 57 03 68 5D 07 69 23 55 37 60 14 7E 1D 2F 62 5F 62 5F`

Hàm này so sánh 100 ký tự flag_buffer với dãy trên. Nếu bằng hết thì mới in ra cờ. Nếu không in ra số phần tử bằng nhau và trả về số đó.

![image](https://hackmd.io/_uploads/ryHvRbq1ll.png)

Trước đó buffer xor 17 phần tử đầu với 1. Để tìm 17 phần tử của flag thì ta xor 17 phần tử đầu của chuỗi trên với 1 được:
`75 6e 68 34 4e 64 6c 33 33 78 43 33 70 54 69 30 6e` = `unh4Ndl33xC3pTi0n`

83 byte bên dưới là đoạn đã được mã hóa ở trên. Cho đến hiện tại tổng số byte được mã hóa là:
`00 AB AB AB AB AB AB AB AB 00 CC CF CE D1 D0 D3 D2 D5 D4 D7 D6 D9 00 EF BE EF BE EF BE EF BE EF BE EF BE EF BE EF BE EF BE` (21).


Để debug được hàm này ta sẽ sửa `int 3` và `2d` thành `nop`. Sau đó sửa jmp sao cho nhảy vào khối `_except`.

![image](https://hackmd.io/_uploads/HkWIyMzxll.png)

![image](https://hackmd.io/_uploads/B1vR7MGlxe.png)
Sau khi qua 2 dòng trên ta được:
![image](https://hackmd.io/_uploads/rypUvLfgee.png)


![image](https://hackmd.io/_uploads/HydkHMGxgg.png)
Đoạn này mã hóa 30 dòng từ:
![image](https://hackmd.io/_uploads/rJ9CULGxlg.png)

Thuật toán là xor 2 byte kề nhau nhưng chúng vốn bằng 0 nên không có thay đổi. Có thể em làm sai chỗ nào rồi.

Hàm cuối cùng
![image](https://hackmd.io/_uploads/B1jvBzGgee.png)
![image](https://hackmd.io/_uploads/BJJ0HGzgxg.png)

00 AB AB AB AB AB AB 55 A7 C0 23 CF CE D1 D0 D3 D2 D5 D4 D7 D6 D9 00 EF BE EF BE EF BE EF BE EF BE EF BE EF BE EF BE EF BE 00 00 00 00 00 00 00 37 13 FE C0 00 00 ... 00.

Đây là toàn bộ thay đổi trên data gồm 52 byte.
Có vẻ em làm sai vì xor không ra cờ. 
Đọc kỹ hàm `flag_func` em rút ra được:
- `flag_buffer` có 18 byte.
- Toàn bộ byte thứ 19 trở đi đều do chương trình tạo ra.
- `flag` in ra là `flag_buffer2`. Mà nó copy `flag_buffer` từ lúc chưa mã hóa các byte bên dưới.
=> Flag gồm 18 ký tự:`unh4Ndl33xC3pTi0n` (17 ký tự) + 1 byte cuối không bị mã hóa là `5F`.

![image](https://hackmd.io/_uploads/SJFAn8Gelx.png)
![image](https://hackmd.io/_uploads/Syvla8Mxll.png)
![image](https://hackmd.io/_uploads/Hy49pLMeee.png)

EM thử tải file mới và xem lại thì thấy lập luận không sai.
Copy 100 byte của flag ngay sau khi nhập.

flag:`unh4Ndl33xC3pTi0n_`.
![image](https://hackmd.io/_uploads/BJmmi8zlll.png)
Em đúng được 18 ký tự vậy là lập luận của em đúng. Em sai ở cách patch. Em xin phép ngừng tại đây vì em hết cách rồi.

# anti1
Đầu tiên chạy thử file.
![image](https://hackmd.io/_uploads/ByNoGvXlxl.png)

![image](https://hackmd.io/_uploads/BJGCfPmlxl.png)
Có rất nhiều return. Ta sẽ chuyển sang text view để tìm hiểu.

![image](https://hackmd.io/_uploads/S1Um7PQxxe.png)
Ta cần code đoạn này.
![image](https://hackmd.io/_uploads/S1-D7DQlxg.png)
Bắt đầu từ đây. undefine và code lại + nop. Sau đó nó sẽ tự code hết toàn bộ phần dưới.

![image](https://hackmd.io/_uploads/HyVJ4vQegl.png)
Còn 3 phát nữa.

![image](https://hackmd.io/_uploads/SkcEND7xxl.png)
![image](https://hackmd.io/_uploads/rknZrw7gle.png)
![image](https://hackmd.io/_uploads/HJv8Bvmgxx.png)
Có `jge` không nhảy vào đầu nên ta kiểm tra chỗ đấy. 
![image](https://hackmd.io/_uploads/B1l5IPXllg.png)
Có thể là flag. Code nó.
![image](https://hackmd.io/_uploads/BJp1wwmlgl.png)
![image](https://hackmd.io/_uploads/HkdvwP7glg.png)
Nó `jmp` về đoạn cũ này. Code cái `data 8b` nó sẽ sửa luôn cái bên dưới. Cứ code và sử dụng kỹ thuật như trên ta sẽ được:
![image](https://hackmd.io/_uploads/BkyWKvmell.png)
Đâu là vòng lặp so sánh từng byte. Ta nop các dữ liệu thừa là xong.

Ta cũng tìm được hướng làm luôn.
![image](https://hackmd.io/_uploads/HJqBcvQxex.png)
![image](https://hackmd.io/_uploads/ByVP5DXgge.png)

So sánh 53 byte của biến `byte_4218b0` với với giá trị ở địa trị `var_78` trở xuống, khả năng là bufer.
`byte_`:
`00 00 00 00 06 38 73 2D 70 7E 11 47 1D 3F 3B 76 1A 26 77 30 2A 12 52 55 1D 28 3B 24 29 2F 1C 2B 2C 51 12 7E 3B 7B 26 1A 20 2D 29 73 3A 7E 10 55 1D 6A 0D 1B 38` (53 byte).

Sau khi tìm hiểu em phát hiện ra chương trình có 2 luồng nhảy vào cờ.
- luồng 1: Rất nhiều khối như dưới. Đều liên quan đến `var_78`
 ![image](https://hackmd.io/_uploads/rkR8G_Xleg.png)

- Luồng 2: Có vẻ đơn giản hơn
![image](https://hackmd.io/_uploads/rJJsMOQlgl.png)
![image](https://hackmd.io/_uploads/B1MkXdXgxx.png)
Đây là vòng lặp 53 lần.

![image](https://hackmd.io/_uploads/HyWMXOmxee.png)
mov 53 byte của 1 vùng nhớ vào biến `byte_` trên. Giá trị ở trên không còn ý nghĩa.
![image](https://hackmd.io/_uploads/SyzXQOXxgg.png)
Tăng index.

`buffer`:
`00 00 00 00 06 38 26 77 30 58 7E 42 2A 7F 3F 29 1A 21 36 37 1C 55 49 12 30 78 0C 28 30 30 37 1C 21 12 7E 52 2D 26 60 1A 24 2D 37 72 1C 45 44 43 37 2C 6C 7A 38` (53 byte).

Ở trên nữa là:
![image](https://hackmd.io/_uploads/r1BOs97lel.png)
Chú ý ở dưới cùng có truy cập vào PEB->beingdebugged. Nếu debug thì không nhảy vào luồng 2. Vậy ta chọn đúng luồng rồi. Sửa thành `jmp`.

Đọc nốt hàm sub. Hàm này ngắn có thể compile sang c.
![image](https://hackmd.io/_uploads/By-92cXgxg.png)
a1 là edx => a1 là địa chỉ `var_78`.
a2 là ecx => a2 là offset Bksec.
a3 = 64h = 100.

Đầu tiên tính độ dài `bksec` = 12
a1[i] ^ a2[i % len].


![image](https://hackmd.io/_uploads/HknL-j7glg.png)
Đây là khối lệnh ở trên. Nó tạo 1 vùng nhớ cho flag là đúng 100 byte. Hơn nữa offset buffer là giá trị của `var_78`.

![image](https://hackmd.io/_uploads/SylMzsQeex.png)
Đây là khối lệnh sau khối ở trên. Do ở trên `mov var_bc, 0f` nên nó không nhảy mà đi xuống khối gây exception ở dưới.

![image](https://hackmd.io/_uploads/S1kXMjQxgl.png)
Đây là đầu hàm main. Nó tạo 1 `SEH` để xử lý exception.

Em đã hình dung qua luồng chương trình.
- Tạo SEH.
- Nhập flag và gây exception.
- nhảy vào bksecc, encode flag bằng cách xor với bksec
- tạo 1 buffer để so sánh với flag.

Giờ ta làm ngược lại như sau:
- buffer đã có 53 byte.
- xor với bksec
- Nhận được flag.

```c
#include <stdio.h>
#include <string.h>

int main() {
    char bksec[12] ="BKSEECCCC!!!";
    char buffer[53] ={0x00,0x00,0x00,0x00,0x06,0x38,0x26,0x77,0x30,0x58,0x7e,0x42,
        0x2a,0x7f,0x3f,0x29,0x1a,0x21,0x36,0x37,0x1c,0x55,0x49,0x12,0x30,0x78,0x0c,
        0x28,0x30,0x30,0x37,0x1c,0x21,0x12,0x7e,0x52,0x2d,0x26,0x60,0x1a,0x24,0x2d,
        0x37,0x72,0x1c,0x45,0x44,0x43,0x37,0x2c,0x6c,0x7a,0x38};
int i;
for (i = 0; i<53; i++){
    buffer[i] = buffer[i] ^ bksec[i % 12];
}
for(i =0 ; i< 53; i++){
    printf("%c",buffer[i]);
}
    return 0;
}
```

flag: `BKSEC{e4sy_ch4ll_but_th3r3_must_b3_som3_ant1_debug??}`
