# ThitNhi.exe
Chạy thử thì nó báo file không an toàn không cho chạy.

![image](https://github.com/user-attachments/assets/5528b63e-fd36-4fdb-abdd-29dc04c832d7)

Vào xem nó có gì.

![image](https://github.com/user-attachments/assets/3dfdf8f3-072b-4609-b6ef-9fde2a00c52f)

**Bắt đầu debug**

![image](https://hackmd.io/_uploads/r1GNAeB0yx.png)

Đoạn trên chỉ là nhập `flag`, sửa giá trị của `v11` và đặt tất cả giá trị của v9 bằng 0.

![image](https://github.com/user-attachments/assets/8025ec62-6c48-4860-b3b4-216e22b07b62)

Ta sẽ đọc 3 hàm sub này.

- Hàm 1:

![image](https://hackmd.io/_uploads/r1-wwkKCJx.png)

Hàm này đếm số byte của main. Kết thúc khi chạy đến 0xC3 (ret).

- Hàm 2:

![image](https://hackmd.io/_uploads/Hkfdv1Y0kg.png)

Hàm 2 là antidebug. Hàm này truy tìm `software breakpoint`. Lấy từng byte `^ 0x55`. Nếu có `software breakpoint - 0xcc` thì sẽ ra `0x99`.

Do đó ta sẽ phải kiểm tra main xem có byte `0xcc` không.

![image](https://hackmd.io/_uploads/HJuf6eKCkg.png)

Hàm main có chứa byte `0xcc` nên hàm antidebug không ảnh hưởng đến hàm main. Ta sẽ chạy qua đây để kiểm tra giá trị v7.

![image](https://github.com/user-attachments/assets/d423e627-9d6c-43d9-8a35-833f47424ec5)

`v7 = DEADBEFCh`

-Hàm 3:

![image](https://hackmd.io/_uploads/HJS9KJY01l.png)
![image](https://hackmd.io/_uploads/HyvgjyYCyl.png)

Em xác định được hàm bên trên là mã hóa RC4.

Hàm này cũng tìm `software breakpoint` và tạo key dựa trên kết quả trả về của hàm antidebug.

Hàm RC4 không có byte `0xcc` nên antidebug có ảnh hưởng đến hàm này.

Do hàm `Antidebug` có ở cả `main` và `RC4` nên em sẽ không patch nó mà chuyển luồng sang bên đúng.

![image](https://hackmd.io/_uploads/ryNMkbYA1l.png)
![image](https://hackmd.io/_uploads/S1tVJZFR1g.png)

Hiện tại em đang ở hàm `RC4`. Ta chắc chắn nó sẽ nhảy vào khối `mov eax, 13h` (return 13h) vì đang đặt `software breakpoint`.

Nên em `set ip` nó sang bên `mov eax, 37h` (return 37h) . Có nghĩa là không có byte `0xcc` trong `RC4`.

![image](https://github.com/user-attachments/assets/4ddbc7f3-057b-4f31-8228-6af65676c212)

`eax = 37h`.

Ta tìm được key là DEADBF33

**Bắt đầu đọc thuật toán mã hóa RC4**

- `for` đầu là tạo s-box và tạo key
- `for` 2 hoán vị s theo key
- `for` cuối là tạo keystream và mã hóa.

Mục đích là làm sao cho `v9 = 7D 08 ED 47 E5 00 88 3A 7A 36 02 29 E4 00`

Do v9 chứa byte 0x00 nên không chuyển sang string được. Cần tạo hàm mã hóa cho hexstring.

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
Chạy thử

![image](https://github.com/user-attachments/assets/66f43bc1-f06a-4caf-ade3-118dfabffd70)

**Bắt đầu debug**

Vào `export` ta sẽ thấy có `tlscallback`.

![image](https://github.com/user-attachments/assets/63be43dd-bbab-450d-ba4a-6c02a4f6cb39)

Hàm này chạy trước main nên phải kiểm tra.

![image](https://github.com/user-attachments/assets/582efd52-d8c2-4d63-9ca4-180c7ad87924)

Có Antidebug. Cụ thể:
- Kiểm tra debug bằng `IsDebuggerPresent()`. Trả về 1 nếu có debugger.
- Nếu trả về 1 thì không thực hiện `if`.
- bypass bằng cách patch thành trả về 0.

![image](https://github.com/user-attachments/assets/58fea48e-04de-4a15-8f5b-f7acb0495501)

Là đoạn này đây. Patch lệnh jump thành `jb` thì nó sẽ mất luôn `if`.

![image](https://github.com/user-attachments/assets/a2ecdee6-32c1-4907-8173-dbefebd39d26)

Giờ ta kiểm tra nó thay đổi gì.

![image](https://github.com/user-attachments/assets/fd83c23e-2713-4878-8c39-0f9200dd213f)

`WriteProcessMemory` có tác dụng ghi dữ liệu vào không gian bộ nhớ của 1 tiến trình khác. Có nghĩa là nó sẽ thay đổi opcode.

Có 1 hàm `sub` và 1 `label: loc_4013A2`.

Truy cập vào `loc`

![image](https://github.com/user-attachments/assets/010ef3ac-e986-4093-b3cf-ca3cad2fdb2d)

Đoạn này ở `main`. Có vẻ nó sẽ ghì đè lệnh `call` ở dưới.

Giờ ta kiểm tra sự thay đổi ở `main`.

![image](https://hackmd.io/_uploads/HyxqMebJgg.png)

Hàm `sub` đã thay đổi, là cái ở trong `tlscallback`. Ta sẽ đọc nó.

![image](https://hackmd.io/_uploads/B1Y2Ggb1ee.png)

Đây là mã hóa `TEA (Tiny Encryption Algorithm)`.

Đã patch xong, giờ ta kiểm tra `main`.

![image](https://github.com/user-attachments/assets/572cae34-d3c8-488a-ae62-4a6b90b6c864)

Nhìn sơ qua

![image](https://github.com/user-attachments/assets/bca151e3-1d7a-4afb-ba9a-b4fdb95f0b6d)

`v11 = VdlKe9upfBFkkO0L`

Tạo buffer cho 2 biến và copy giá trị của biến `unk` sao bên `buf2`.

`buff2 = 19 2C 30 2A 79 F9 54 02 B3 A9 
         6C D6 91 80 95 04 29 59 E8 A3 
         0F 79 BD 86 AF 05 13 6C FE 75 
         DB 2B AE E0 F0 5D 88 4B 86 89 
         33 66 AC 45 9A 6C 78 A6`
(48 ký tự)

Dưới nữa là `printf` và `scanf`.

Giờ ta xem phần dưới.

![image](https://github.com/user-attachments/assets/fc6e20bb-5a5a-40e5-86e3-41fb784cb648)

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
Đoạn code này đang thực hiện đệm (padding) thêm các byte vào cuối chuỗi để độ dài của nó là bội số của 8.

![image](https://hackmd.io/_uploads/By5aVYRAkl.png)

Ta tập trung vào vòng lặp `for` dưới cùng. Nếu lần lượt 8 byte `buffer` khác `buf2` thì sai.

Đã có hướng làm:
- `buffer` sẽ bị mã hóa ở hàm `TEA`.
- Sau đó đem so sánh với `buf2`.

Giờ em sẽ code giải mã `TEA`.
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

Em không hiểu sao khi thay vào vẫn sai.

flag: PTITCTF{bdc90e23aa0415e94d0ac46a938efcf3}

Em xin phép dừng tại đây. Em sửa code mãi mà chả ra.

# Antidebug3

Chạy thử thì xuất hiện lỗi chia cho 0.

![image](https://hackmd.io/_uploads/Byy1OMqygg.png)

Khi gặp lỗi thì sẽ nhảy vào hàm này.

### Disassembly

![image](https://hackmd.io/_uploads/Byev_M5ylg.png)

Xuất hiện dòng đỏ. Là kỹ thuật Anti disassembly. Ở đây do cùng nhảy vào `loc_4013CD+1` nên có byte thừa. Ta undefine nó.

![image](https://hackmd.io/_uploads/HJy4Fzcyxl.png)

Byte `0E8h` là byte thừa vì đoạn trên nhảy qua nó. sửa byte `e8` -> `nop`. Được:

![image](https://hackmd.io/_uploads/SJjsFfqJgg.png)

![image](https://github.com/user-attachments/assets/238003d8-4bc6-4a55-8ed6-82b5fd74d815)

Ngay dưới ta xuất hiện dòng này. Chỉ có `e8` và `e9` là byte thừa. Dòng này chưa được code nên ta code nó.

![image](https://hackmd.io/_uploads/BkPj9Gq1ex.png)

Tiếp tục truy tìm.

![image](https://hackmd.io/_uploads/S1Ywof5Jxl.png)

Ta thấy đoạn `jz` luôn nhảy do có `xor eax, eax`(cờ ZF = 1). Hơn nữa địa chỉ nhảy là `loc +2`.

![image](https://hackmd.io/_uploads/H1lfrhzqyge.png)

Em code tại địa chỉ `loc +2` được.

![image](https://hackmd.io/_uploads/Hk0YnGcyle.png)

jmp nên toàn bộ data ta `nop` hết.

![image](https://github.com/user-attachments/assets/1457c471-aaa5-4312-8c7b-4854bdc8a510)

![image](https://github.com/user-attachments/assets/cfc13ed5-3ffe-4401-acff-c36fe9aef265)

Do nó ở ngay dưới `ret` nên em đoán nó là 1 hàm riêng. `Create function` ra cái này.

Đã tìm hết.

Giờ ta đã có thể compile sang C.

### bắt đầu debug.

![image](https://hackmd.io/_uploads/Bkio0fcJge.png)

v4 em không hiểu cho lắm nhưng chắc là antidebug.

![image](https://hackmd.io/_uploads/S1QX17qyel.png)

v4 là  `[ebp + var_c]` Nếu nó = 1 thì `1 ^ 0xCD = 0xCC`.

![image](https://github.com/user-attachments/assets/e8f5405b-6b4b-40c3-b985-04aa34c809ac)

Đây là v4 khi em chạy qua. Có vẻ nó không ảnh hưởng nên em kệ nó vậy.

v3 thì chắc chắn là antidebug.

Tiếp tục sửa đoạn `v3->beingdebug ^ 0xAB` là dòng xanh. Sửa `xor eax, 0ABh` -> `mov eax, 0ABh`. Như vậy dù có debug hay không giá trị luôn là `0ABh`.

![image](https://hackmd.io/_uploads/BkS6x75kgx.png)

Sửa 1 số hàm với biến cho dễ đọc.

![image](https://github.com/user-attachments/assets/5578b20c-b5df-4fdd-9418-418e5a88cbc8)

Chương trình copy 100 byte của `flag_buffer`. Nhưng khi check thì `flag_buffer` có 18 byte. Còn lại là của các biến khác.

=> flag có 18 ký tự. Số còn lại là do chương trình tự mã hóa.

**Đoạn cần chú ý tiếp là hàm `sub_401400()`**

![image](https://hackmd.io/_uploads/H1vDbX5klx.png)

Hàm này kiểm tra khoảng cách giữa 2 hàm. Nếu ta patch sai thì đoạn này ta sẽ sai.

Ngoài ra còn tìm từng byte của hàm `sub_401330`. Nếu có `0xcc` thì thoát for (`0x55 ^ 153 = 0xcc`). Em đã kiểm tra byte của nó và không có `oxcc`.

Vì mục đích của ta là không để nó phát hiên debug nên mặc định là chạy đến khi i = v1.

=> Sửa return -> `return 48879`.

![image](https://hackmd.io/_uploads/rJ5Of79kxe.png)

Ta sửa đoạn `sub eax, [ebp+var_4]` thành `sub eax, [ebp+var_8]`.

**Trở về `toplevel`.**

![image](https://github.com/user-attachments/assets/c9ae4496-f074-476d-936f-7707790943e7)

đoạn dưới là `flag_buffer[i] ^ 1`. Mã hóa 17 byte cùa `flag` .Tạm thời bỏ qua.

kiểm tra biến `unk` và hàm `sub`.

![image](https://hackmd.io/_uploads/r1vYDZGgxx.png)

![image](https://github.com/user-attachments/assets/c09e3899-26a7-4e8c-a0cf-0237566b30f2)

Ta sẽ nhìn qua từng hàm `sub`.

-Hàm 1:

![image](https://github.com/user-attachments/assets/3034ca24-685b-4b69-8bfd-c9e78e8f95a2)

Hàm này mã hóa biến `unk` và thậm chí vượt qua cả buffer của nó. Ta sẽ xem qua buffer.

![image](https://github.com/user-attachments/assets/427b335c-18f6-4c83-8b2d-ea7cf9c81284)

![image](https://github.com/user-attachments/assets/94468402-86b9-4a2f-aaa1-278d7c60d708)

Nó ở dưới `flag_buffer`. Khi em chuyển `align` thành `data` thì nó có 1000 byte đều = 0.

Có thao tác với các biến `antidebug` ở trên.

Ta không cần quan tâm về thuật toán của nó. Chỉ cần biết nó mã hóa các byte ở dưới `flag`.

**Quay lại:**

![image](https://github.com/user-attachments/assets/2e02f8e3-dc71-4644-a806-8b487ff6b28f)

`unk[2n] ^ 28879.` Làm với 2 byte 1 lần.

- Hàm sub thứ 2:

![image](https://hackmd.io/_uploads/r1LhmQ5yge.png)

Hàm này gây `exception` để break debug. 

Để debug được hàm này ta sẽ sửa `int 3` và `2d` thành `nop`. Sau đó sửa jmp sao cho nhảy vào khối `_except`.

![image](https://github.com/user-attachments/assets/fd3b5a72-8f9c-4658-9e09-4f2841fdf78b)

Nó lại mã hóa tiếp các byte dưới. Ta kiểm tra nốt các hàm còn lại.

- Hàm 1 (sub_C91190):

![image](https://github.com/user-attachments/assets/7c3f6331-5a19-45aa-8b21-1936247eb760)

Vẫn là hàm mã hóa.

-Hàm 2 :

![image](https://hackmd.io/_uploads/BkFPSX5Jll.png)

Hàm này chứa cờ.

Ta xem thử `byte_404118`.

`byte_404118`: (100 byte)

`74 6F 69 35 4F 65 6D 32 32 79 42 32 71 55 68 31 6F`  (17 byte)

`5F DB CE C9 EF CE C9 FE 92 5F 10 27 BC 09 0E 17 BA 4D 18 0F BE AB 5F 9C 8E A9 89 98 8A 9D` (30 byte)

`8D D7 CC DC 8A A4 CE DF 8F 81 89 5F 69 37 1D 46 46 5F 5E 7D 8A F3 5F 59 01 57 67 06 41 78` 

`01 65 2D 7B 0E 57 03 68 5D 07 69 23 55 37 60 14 7E 1D 2F 62 5F 62 5F` (23 byte)

Hàm này so sánh 100 ký tự `flag_buffer` với dãy trên. Nếu bằng hết thì mới in ra cờ. Nếu không in ra số phần tử bằng nhau và trả về số đó.


Trước đó ở `toplevel` ta có:

![image](https://github.com/user-attachments/assets/c215866c-1212-4fe5-9a78-501d733de3c3)

. Để tìm 17 phần tử của flag thì ta xor 17 phần tử đầu của chuỗi trên với 1 được:

`75 6e 68 34 4e 64 6c 33 33 78 43 33 70 54 69 30 6e` = `unh4Ndl33xC3pTi0n`. 

Còn 1 byte nữa là `5F` không bị mã hóa khi chuyển sang ascii là `_`.

=> flag: `unh4Ndl33xC3pTi0n_`.

![image](https://github.com/user-attachments/assets/cfe4b4c1-5130-4b3d-bb15-463edc664a03)

Có vẻ do em patch sai các đoạn antidebug. Nhưng chung quy lại flag là thế ạ.

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

Đâu là vòng lặp so sánh từng byte. Ta `nop` các dữ liệu thừa là xong.

Em cũng tìm được hướng làm luôn.

![image](https://hackmd.io/_uploads/HJqBcvQxex.png)

![image](https://hackmd.io/_uploads/ByVP5DXgge.png)

So sánh 53 byte của biến `byte_4218b0` với với giá trị ở địa chỉ `var_78` trở xuống, khả năng là bufer.
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

mov 53 byte của 1 vùng nhớ vào biến `byte_` trên => Giá trị ở trên không còn ý nghĩa.

![image](https://hackmd.io/_uploads/SyzXQOXxgg.png)

Tăng index.

`buffer`:

`00 00 00 00 06 38 26 77 30 58 7E 42 2A 7F 3F 29 1A 21 36 37 1C 55 49 12 30 78 0C 28 30 30 37 1C 21 12 7E 52 2D 26 60 1A 24 2D 37 72 1C 45 44 43 37 2C 6C 7A 38` (53 byte). 

Đây mới là giá trị cần sử dụng.

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
- nhảy vào bksecc, encode flag bằng cách xor với bksec.
- tạo 1 buffer để so sánh với flag.

Giờ ta làm ngược lại như sau:
- buffer đã có 53 byte.
- xor với bksec.
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
![image](https://github.com/user-attachments/assets/b4427aac-e3a3-4cae-a54b-19bd610f6f3d)

flag: `BKSEC{e4sy_ch4ll_but_th3r3_must_b3_som3_ant1_debug??}`

![image](https://github.com/user-attachments/assets/c4e32a49-3a04-4263-b58f-a4601cac5226)
