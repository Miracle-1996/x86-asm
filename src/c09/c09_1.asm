         ;代码清单9-1
         ;文件名：c09_1.asm
         ;文件说明：用户程序 
         ;创建日期：2011-4-16 22:03
         
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04]
                    dd section.code.start   ;段地址[0x06] 
    
    realloc_tbl_len dw (header_end-realloc_begin)/4
                                            ;段重定位表项个数[0x0a]
    
    realloc_begin:
    ;段重定位表           
    code_segment    dd section.code.start   ;[0x0c]
    data_segment    dd section.data.start   ;[0x14]
    stack_segment   dd section.stack.start  ;[0x1c]
    
header_end:                
    
;===============================================================================
SECTION code align=16 vstart=0           ;定义代码段（16字节对齐） 
new_int_0x70:
      push ax
      push bx
      push cx
      push dx
      push es
      
  .w0:                                    
      mov al,0x0a                        ;阻断NMI。当然，通常是不必要的
      or al,0x80                          
      out 0x70,al
      ;154->0x71或者0x75是数据端口
      ;154->读rtc寄存器A,根据uip位的状态决定是等待更新周期结束还是继续往下执行
      in al,0x71                         ;读寄存器A
      ;160->test指令在功能上和and指令一样,逻辑与操作并根据结果设置相应的标志位
      ;160->test指令执行后,运算结果被丢弃
      test al,0x80                       ;测试第7位UIP 
      jnz .w0                            ;以上代码对于更新周期结束中断来说 
                                         ;是不必要的 
      xor al,al
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(秒)
      push ax

      mov al,2
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(分)
      push ax

      mov al,4
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(时)
      push ax

      mov al,0x0c                        ;寄存器C的索引。且开放NMI 
      out 0x70,al
      in al,0x71                         ;读一下RTC的寄存器C，否则只发生一次中断
                                         ;此处不考虑闹钟和周期性中断的情况 
      mov ax,0xb800
      mov es,ax

      ;155->cmos ram中保存的日期和时间通常是以二进制编码的十进制数
      pop ax
      call bcd_to_ascii
      mov bx,12*160 + 36*2               ;从屏幕上的12行36列开始显示

      mov [es:bx],ah
      mov [es:bx+2],al                   ;显示两位小时数字

      mov al,':'
      ;161->通过寄存器al中转是多余的,这两句可以直接写成
      ;161->mov byte [es:bx + 4],':'
      mov [es:bx+4],al                   ;显示分隔符':'
      not byte [es:bx+5]                 ;反转显示属性 

      pop ax
      call bcd_to_ascii
      mov [es:bx+6],ah
      mov [es:bx+8],al                   ;显示两位分钟数字

      mov al,':'
      mov [es:bx+10],al                  ;显示分隔符':'
      not byte [es:bx+11]                ;反转显示属性

      pop ax
      call bcd_to_ascii
      mov [es:bx+12],ah
      mov [es:bx+14],al                  ;显示两位小时数字
      
      ;162->8259芯片内部有一个8位中断服务寄存器,每一位都对应着一个中断输入引脚
      ;162->当中断处理过程开始时,8259芯片会将相应的位置1,表明正在服务从该引脚来的中断
      ;162->一旦响应了中断,8259中断控制器无法知道该中断什么时候才能处理结束
      ;162->同时,如果不清除相应的位,下次从同一个引脚出现的中断将得不到处理。
      ;162->在这种情况下,需要程序在中断处理过程的结尾,显式地对8259芯片编程来清除该标志,方法是向8259芯片发送中断结束命令
      ;162->中断结束命令的代码是0x20
      ;162->如果外部中断是8259主片处理的,那么,eoi命令仅发送给主片即可,端口号是0x20
      ;162->如果外部中断是由从片处理的,那么,eoi命令既要发往从片(端口号0xa0),也要发往主片
      mov al,0x20                        ;中断结束命令EOI 
      out 0xa0,al                        ;向从片发送 
      out 0x20,al                        ;向主片发送 

      pop es
      pop dx
      pop cx
      pop bx
      pop ax

      iret

;-------------------------------------------------------------------------------
bcd_to_ascii:                            ;BCD码转ASCII
                                         ;输入：AL=bcd码
                                         ;输出：AX=ascii
      mov ah,al                          ;分拆成两个数字 
      and al,0x0f                        ;仅保留低4位 
      add al,0x30                        ;转换成ASCII 

      shr ah,4                           ;逻辑右移4位 
      and ah,0x0f                        
      add ah,0x30

      ret

;-------------------------------------------------------------------------------
start:
      mov ax,[stack_segment]
      mov ss,ax
      mov sp,ss_pointer
      mov ax,[data_segment]
      mov ds,ax
      
      mov bx,init_msg                    ;显示初始信息 
      call put_string

      mov bx,inst_msg                    ;显示安装信息 
      call put_string
      
      ;158->在计算机启动期间,bios会初始化中断控制器
      ;158->将主片的中断号设为从0x08开始,将从片的中断号设为从0x70开始
      ;152->实模式下,每个中断在中断向量表中占2个字,分别是中断处理程序的偏移地址和段地址
      mov al,0x70
      mov bl,4
      mul bl                             ;计算0x70号中断在IVT中的偏移
      mov bx,ax                          

      ;152->标志寄存器有一个中断标志位IF,cli用于清除IF标志位,sti用于置位IF标志位
      ;153->中断随时可能发生,中断向量表的建立和初始化工作是由bios在计算机启动时负责完成
      ;158->当表项信息只修改了一部分时,如果发生0x70号中断,则会产生不可预料的问题
      cli                                ;防止改动期间发生新的0x70号中断

      push es
      mov ax,0x0000
      mov es,ax
      mov word [es:bx],new_int_0x70      ;偏移地址。
                                          
      mov word [es:bx+2],cs              ;段地址
      pop es
      ;158->设置rtc的工作状态,使它能够产生中断信号给8259中断控制器
      mov al,0x0b                        ;RTC寄存器B
      ;154->端口0x70的最高位(bit 7)是控制NMI中断的开关
      ;154->当它为0时,允许NMI中断到达处理器,为1时,则阻断所有的NMI信号,其他7个比特,即0-6位,则实际上用于指定cmos ram单元的索引号
      or al,0x80                         ;阻断NMI 
      ;154->cmos ram的访问需要通过两个端口进行
      ;154->0x70或者0x74是索引端口,用来指定cmos ram内的单元
      ;158->在访问rtc期间,最好是阻断NMI
      out 0x70,al
      mov al,0x12                        ;设置寄存器B，禁止周期性中断，开放更 
      out 0x71,al                        ;新结束后中断，BCD码，24小时制

      ;159->每次当中断实际发生时,可以在程序(中断处理过程)中读寄存器C的内容来检查中断的原因
      ;159->每当更新周期结束中断发生时,rtc就将它的第4位置1
      ;159->该寄存器还有一个特点,就是每次读取它后,所有内容自动清0
      ;159->而且,如果不读取它的话(换句话说,相应的位没有清0),同样的中断将不再产生
      mov al,0x0c
      out 0x70,al
      in al,0x71                         ;读RTC寄存器C，复位未决的中断状态

      ;159->正常情况下,8259是不会允许rtc中断的,所以,需要修改它内部的中断屏蔽控制器IMR
      ;159->IMR是一个8位寄存器,位x对应着中断输入引脚irx(0 <= x <= 7),相应的位是0时,允许中断,为1时,关掉中断
      ;152->8259芯片是可编程的,主片的端口号是0x20和0x21,从片的端口号是0xa0和0xa1
      in al,0xa1                         ;读8259从片的IMR寄存器 
      and al,0xfe                        ;清除bit 0(此位连接RTC)
      out 0xa1,al                        ;写回此寄存器 

      sti                                ;重新开放中断 

      mov bx,done_msg                    ;显示安装完成信息 
      call put_string

      mov bx,tips_msg                    ;显示提示信息
      call put_string
      
      mov cx,0xb800
      mov ds,cx
      mov byte [12*160 + 33*2],'@'       ;屏幕第12行，33列
       
 .idle:
      ;159->hlt指令使处理器停止执行指令,并处于停机状态,这将降低处理器的功耗
      hlt                                ;使CPU进入低功耗状态，直到用中断唤醒
      not byte [12*160 + 33*2+1]         ;反转显示属性 
      jmp .idle

;-------------------------------------------------------------------------------
put_string:                              ;显示串(0结尾)。
                                         ;输入：DS:BX=串地址
         mov cl,[bx]
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
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;高8位 
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位 
         mov bx,ax                       ;BX=代表光标位置的16位数

         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符 
         mov ax,bx                       ; 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         mov ax,0xb800
         mov es,ax
         shl bx,1
         mov [es:bx],cl

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor

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
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

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

;===============================================================================
SECTION data align=16 vstart=0

    init_msg       db 'Starting...',0x0d,0x0a,0
                   
    inst_msg       db 'Installing a new interrupt 70H...',0
    
    done_msg       db 'Done.',0x0d,0x0a,0

    tips_msg       db 'Clock is now working.',0
                   
;===============================================================================
SECTION stack align=16 vstart=0
           
                 resb 256
ss_pointer:
 
;===============================================================================
SECTION program_trail
program_end: