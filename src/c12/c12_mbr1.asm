         ;在保护模式下对字符串进行排序的程序
         ;计算GDT所在的逻辑段地址
         mov eax,[cs:pgdt+0x7c00+0x02]      ;GDT的32位线性基地址 
         xor edx,edx
         mov ebx,16
         div ebx                            ;分解成16位逻辑地址 

         mov ds,eax                         ;令DS指向该段以进行操作
         mov ebx,edx                        ;段内起始偏移地址 

         ;创建0#描述符，它是空描述符，这是处理器的要求
         mov dword [ebx+0x00],0x00000000
         mov dword [ebx+0x04],0x00000000

         ;创建1#描述符，这是一个数据段，对应0~4GB的线性地址空间
         mov dword [ebx+0x08],0x0000ffff    ;基地址为0，段界限为0xfffff
         mov dword [ebx+0x0c],0x00cf9200    ;粒度为4KB，存储器段描述符

         ;创建保护模式下初始代码段描述符
         mov dword [ebx+0x10],0x7c0001ff    ;基地址为0x00007c00，512字节
         mov dword [ebx+0x14],0x00409800    ;粒度为字节，代码段描述符

         ;创建以上代码段的别名描述符
         mov dword [ebx+0x18],0x7c0001ff    ;基地址为0x00007c00，512字节
         mov dword [ebx+0x1c],0x00409200    ;粒度为字节，数据段描述符

         ;创建数据段描述符，实际用做栈段
         mov dword [ebx+0x20],0x6c0007ff    ;基地址为0x00006c00，向上扩展
         mov dword [ebx+0x24],0x00409200    ;界限为0x007ff，粒度为字节，数据段描述符

         ;初始化描述符表寄存器GDTR
         mov word [cs: pgdt+0x7c00],39      ;描述符表的界限
 
         lgdt [cs: pgdt+0x7c00]
      
         in al,0x92                         ;南桥芯片内的端口 
         or al,0000_0010B
         out 0x92,al                        ;打开A20

         cli                                ;中断机制尚未工作

         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;设置PE位
      
         ;以下进入保护模式... ...
         jmp 0x0010:flush                   ;0000000000010_0_00B
                                             
         [bits 32]                          
  flush:                                     
         mov eax,0x0008                     ;0000000000001_0_00B
         mov es,eax                         ;加载数据段(0..4GB)选择子
         mov fs,eax                         ;可省略，程序内未使用FS
         mov gs,eax                         ;可省略，程序内未使用GS

         mov dword [es:0x0b8000],0x072e0750 ;字符'P'、'.'及其显示属性
         mov dword [es:0x0b8004],0x072e074d ;字符'M'、'.'及其显示属性
         mov dword [es:0x0b8008],0x07200720 ;两个空白字符及其显示属性
         mov dword [es:0x0b800c],0x076b076f ;字符'o'、'k'及其显示属性

         mov eax,0x0018                     ;0000000000011_0_00B
         mov ds,eax                         ;加载与代码段重叠的数据段选择子

         mov eax,0x0020                     ;0000000000100_0_00
         mov ss,eax                         ;加载栈段的选择子
         mov esp,0x800                      ;初始化esp为段界限+1

         ;开始冒泡排序
         mov ecx,pgdt-string-1              ;遍历次数=串长度-1
  @@1:
         push ecx                           ;32位操作尺寸下的loop使用ecx
         xor bx,bx                          ;32位操作尺寸下，偏移量可以是16位，
  @@2:                                      ;也可以是后面的32位
         mov ax,[string+bx]
         cmp ah,al                          ;ah中存放的是源字的高字节
         jge @@3
         xchg al,ah
         mov [string+bx],ax
  @@3:
         inc bx
         loop @@2
         pop ecx
         loop @@1

         mov ecx,pgdt-string
         xor ebx,ebx                        ;偏移地址是32位的情况
  @@4:                                      ;32位的偏移具有更大的灵活性
         mov ah,0x07
         mov al,[string+ebx]
         mov [es:0xb80a0+ebx*2],ax          ;演示0~4GB寻址。
         inc ebx
         loop @@4

         hlt

;-------------------------------------------------------------------------------
     string           db 's0ke4or92xap3fv8giuzjcy5l1m7hd6bnqtw.'
;-------------------------------------------------------------------------------
     pgdt             dw 0
                      dd 0x00007e00      ;GDT的物理地址
;-------------------------------------------------------------------------------                             
     times 510-($-$$) db 0
                      db 0x55,0xaa
