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

         ;创建数据段描述符，段的大小为4GB
         mov dword [ebx+0x08],0x0000ffff    ;基地址为0x00000000，向上扩展
         mov dword [ebx+0x0c],0x00cf9200    ;段界限为0xfffff，粒度为4KB，数据段描述符

         ;创建保护模式下初始代码段描述符
         mov dword [ebx+0x10],0x7c0001ff    ;基地址为0x00007c00，向上扩展
         mov dword [ebx+0x14],0x00409800    ;界限为0x001ff，粒度为字节，代码段描述符

         ;创建数据段描述符，实际用做第一个栈段
         mov dword [ebx+0x18],0x6c0007ff    ;基地址为0x00006c00，向上扩展
         mov dword [ebx+0x1c],0x00409200    ;界限为0x007ff，粒度为字节，数据段描述符

         ;创建数据段描述符，实际用做第二个栈段
         mov dword [ebx+0x20],0x7c00fffe    ;基地址为0x00007c00，向下扩展
         mov dword [ebx+0x24],0x00cf9600    ;界限为0xffffe，粒度为4KB，数据段描述符

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
         jmp 0x0010:flush
                                             
         [bits 32]                          
  flush:                                     
         mov eax,0x0008                     ;0000000000001_0_00B
         mov ds,eax                         ;DS设置到4GB数据段

         ;以下演示第一个栈段的操作
         mov eax,0x0018                     ;0000000000011_0_00B
         mov ss,eax                         ;SS设置到第一个栈段
         mov esp,0x800                      ;向上扩展的段，应将栈指针设置为段大小

         push dword 0x072e074d              ;字符'M'、'.'及其显示属性
         push dword 0x072e0750              ;字符'P'、'.'及其显示属性

         pop dword [0x0b8000]
         pop dword [0x0b8004]

         ;以下演示第二个栈段的操作
         mov eax,0x0020                     ;0000000000100_0_00B
         mov ss,eax                         ;SS设置到第二个栈段
         mov esp,0                          ;向下扩展的段，应将栈指针设置为0

         push dword 0x076b076f              ;字符'o'、'k'及其显示属性
         push dword 0x07200720              ;两个空白字符及其显示属性

         pop dword [0x0b8008]
         pop dword [0x0b800c]

         hlt

;-------------------------------------------------------------------------------
     pgdt             dw 0
                      dd 0x00007e00      ;GDT的物理地址
;-------------------------------------------------------------------------------                             
     times 510-($-$$) db 0
                      db 0x55,0xaa
