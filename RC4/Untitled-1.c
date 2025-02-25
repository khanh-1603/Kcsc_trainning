# include <stdio.h>
# include <stdlib.h>
# include <string.h>

void dao(int *a, int *b){
    int d;
    d=*a;
    *a=*b;
    *b=d;
}

void ksa(int s[256],char k[256], int len){   // tạo và hoán vị s-box
    int i=0,j=0;
    for(i=0;i<256;i++){                     // tạo mảng s-box
        s[i]=i;
    }
    for(i=0;i<256;i++){                    // hoán vị s-box theo key
        j=(j + s[i] + k[i % len]) % 256;
        dao(&s[i],&s[j]);
    }
    return;
}

void prga(int s[256],unsigned char k[256], int len){    //tạo keystream
    int i=0, j=0, t, n=0;     
    for(n;n<len;n++){
    i=(i + 1) % 256;
    j=(j + s[i]) % 256;
    dao(&s[i],&s[j]);
    t=(s[i] + s[j]) % 256;
    k[n]=s[t];
    }
    return;
}

void remove_newline(char* str) {
    int len = strlen(str);
    if (str[len - 1] == '\n') {
        str[len - 1] = '\0';
    }
}

int main()
{
    printf("Nhap key:");
    char k[256];
    fgets(k,sizeof(k),stdin);
    remove_newline(k);
    int k_len = strlen(k);
    int s[256],i;
    printf("Nhap text:");
    char tx[10000];
    fgets(tx,sizeof(tx),stdin);
    remove_newline(tx);
    int tx_len = strlen(tx);
    ksa(s,k,k_len);                  
    unsigned char k2[256];
    prga(s,k2, tx_len);              
    printf("RC4: ");
    for(i=0;i<tx_len;i++){
        printf("%02x",tx[i] ^ k2[i]);    // xor keystream với plain text
    }
    return 0;
}