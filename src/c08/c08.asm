         ;代码清单8-2
         ;文件名：c08.asm
         ;文件说明：用户程序 
         ;创建日期：2011-5-5 18:17
         
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04]
                    dd section.code_1.start ;段地址[0x06] 
    
    realloc_tbl_len dw (header_end-code_1_segment)/4
                                            ;段重定位表项个数[0x0a]
    
    ;段重定位表           
    code_1_segment  dd section.code_1.start ;[0x0c]
    code_2_segment  dd section.code_2.start ;[0x10]
    data_1_segment  dd section.data_1.start ;[0x14]
    data_2_segment  dd section.data_2.start ;[0x18]
    stack_segment   dd section.stack.start  ;[0x1c]
    
    header_end:                
    
;===============================================================================
SECTION code_1 align=16 vstart=0         ;定义代码段1（16字节对齐） 
put_string:                              ;显示串(0结尾)。
                                         ;输入：DS:BX=串地址
         ;142->循环从ds:bx中取得单个字符,判断它是否为0
         ;142->不为0则调用另一个过程put_char,为0则返回主程序
         mov cl,[bx]
         ;142->通过or指令来促成标志的产生
         or cl,cl                        ;cl=0 ?
         jz .exit                        ;是的，返回主程序 
         call put_char
         inc bx                          ;下一个字符 
         jmp put_string

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;显示一个字符
                                         ;输入：cl=字符ascii
         push ax
         push bx
         push cx
         push dx
         push ds
         push es

         ;以下取当前光标位置
         ;142->光标在屏幕上的位置保存在显卡内部的两个光标寄存器中,每个寄存器是8位的,合起来形成一个16位的数值
         ;143->显卡的操作非常复杂,内部的寄存器也不是一般地多。为了不过多占用主机的I/O空间,很多寄存器只能通过索引寄存器间接访问
         ;143->索引寄存器的端口号是0x3d4,可以向它写入一个值,用来指定内部的某个寄存器
         ;143->两个8位的光标寄存器,其索引值分别是0x0e和0x0f,分别用于提供光标位置的高8位和低8位
         ;143->通过数据端口0x3d5进行读写
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         ;144->操作0x0e号寄存器
         mov dx,0x3d5
         in al,dx                        ;高8位 
         mov ah,al
         ;144->通过数据端口0x3d5从0x0e号端口读取1字节的数据,并传送到寄存器ah

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位 
         mov bx,ax                       ;BX=代表光标位置的16位数

         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符 
         ;144->如果是回车符0x0d,将光标移动到当前行的行首
         ;144->floor(x / 80) * 80
         mov ax,bx                       ;此句略显多余，但去掉后还得改书，麻烦 
         mov bl,80                       
         div bl
         ;144->ax = al * r / m8
         ;144->dx:ax = ax * r / m16
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符 
         add bx,80
         ;145->如果光标原先就在屏幕最后一行,需要滚屏
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         mov ax,0xb800
         mov es,ax
         ;145->一个字符在显存中对应两个字节
         ;145->光标位置×2得到字符在显存中的偏移地址
         shl bx,1
         mov [es:bx],cl
         ;145->在写入其他内容之前,显存里全是黑底白字的空白字符,所以不需要重写黑底白字的属性

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor
         ;145->滚动屏幕内容,实质上就是将屏幕上第2-25行的内容整体往上提1行
         ;145->最后用黑底白字的空白字符填充第25行,使这一行什么也不显示
         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840                     ;清除屏幕最底一行
         mov cx,80
 .cls:
         ;146->使用黑底白字的空白字符循环写入这一行
         mov word[es:bx],0x0720
         add bx,2
         loop .cls
         ;146->滚屏之后,光标应当位于最后一行的第1列,其数值为1920
         mov bx,1920

 .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh
         out dx,al
         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         mov al,bl
         out dx,al

         pop es
         pop ds
         pop dx
         pop cx
         pop bx
         pop ax

         ret

;-------------------------------------------------------------------------------
  start:
         ;初始执行时，DS和ES指向用户程序头部段
         mov ax,[stack_segment]           ;设置到用户程序自己的堆栈 
         mov ss,ax
         mov sp,stack_end
         
         mov ax,[data_1_segment]          ;设置到用户程序自己的数据段
         mov ds,ax

         mov bx,msg0
         call put_string                  ;显示第一段信息 

         ;146->使用retf指令模拟段间返回,实现段间转移
         push word [es:code_2_segment]
         ;102->就8086处理器来说,压入栈的内容必须是字
         ;146->8086处理器不能在栈中压入立即数
         mov ax,begin
         push ax                          ;可以直接push begin,80386+
         
         retf                             ;转移到代码段2执行 
         
  continue:
         mov ax,[es:data_2_segment]       ;段寄存器DS切换到数据段2 
         mov ds,ax
         
         mov bx,msg1
         call put_string                  ;显示第二段信息 

         jmp $ 

;===============================================================================
SECTION code_2 align=16 vstart=0          ;定义代码段2（16字节对齐）

  begin:
         push word [es:code_1_segment]
         mov ax,continue
         push ax                          ;可以直接push continue,80386+
         
         retf                             ;转移到代码段1接着执行 
         
;===============================================================================
SECTION data_1 align=16 vstart=0

    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a
         db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
         db '     xor dx,dx',0x0d,0x0a
         db '     xor ax,ax',0x0d,0x0a
         db '     xor cx,cx',0x0d,0x0a
         db '  @@:',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     add ax,cx',0x0d,0x0a
         db '     adc dx,0',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     cmp cx,1000',0x0d,0x0a
         db '     jle @@',0x0d,0x0a
         db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
         db 0

;===============================================================================
SECTION data_2 align=16 vstart=0

    msg1 db '  The above contents is written by LeeChung. '
         db '2011-05-06'
         db 0

;===============================================================================
SECTION stack align=16 vstart=0
        
         ;140->伪指令resb的意思是从当前位置开始,保留指定数量的字节,但不初始化它们的值
         ;141->栈段stack的定义中有"vstart=0子句",保留的256字节,其汇编地址分别是0-255
         ;141->标号stack_end处的汇编地址实际上是256
         resb 256

stack_end:  

;===============================================================================
SECTION trail align=16
program_end: