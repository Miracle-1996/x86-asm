         ;代码清单5-1 
         ;文件名：c05_mbr.asm
         ;文件说明：硬盘主引导扇区代码
         ;创建日期：2011-3-31 21:15 
         
         mov ax,0xb800                 ;指向文本模式的显示缓冲区
                                       ;49->文本模式下显存的起始物理地址是0xB8000
         mov es,ax                     ;49->访问内存可以使用段寄存器DS，但这不是强制性的，也可以使用ES。
                                       ;22->ES是附加段(Extra Segment)寄存器。
                                       ;49->Intel处理器不允许将一个立即数传送到段寄存器，它只允许这样的指令:
                                       ;49->mov 段寄存器，通用寄存器
                                       ;49->mov 段寄存器，内存单元
         ;以下显示字符串"Label offset:"
         mov byte [es:0x00],'L'
         mov byte [es:0x01],0x07       ;字符属性0x07可以解释为黑底白字，无闪烁，无加亮
         mov byte [es:0x02],'a'
         mov byte [es:0x03],0x07
         mov byte [es:0x04],'b'
         mov byte [es:0x05],0x07
         mov byte [es:0x06],'e'
         mov byte [es:0x07],0x07
         mov byte [es:0x08],'l'
         mov byte [es:0x09],0x07
         mov byte [es:0x0a],' '
         mov byte [es:0x0b],0x07
         mov byte [es:0x0c],"o"
         mov byte [es:0x0d],0x07
         mov byte [es:0x0e],'f'
         mov byte [es:0x0f],0x07
         mov byte [es:0x10],'f'
         mov byte [es:0x11],0x07
         mov byte [es:0x12],'s'
         mov byte [es:0x13],0x07
         mov byte [es:0x14],'e'
         mov byte [es:0x15],0x07
         mov byte [es:0x16],'t'
         mov byte [es:0x17],0x07
         mov byte [es:0x18],':'
         mov byte [es:0x19],0x07

         mov ax,number                 ;取得标号number的偏移地址
                                       ;58->传送到寄存器ax的值是在源程序编译时确定的，在编译阶段，编译器会将标号number转换成立即数
         mov bx,10

         ;设置数据段的基地址
         mov cx,cs
         mov ds,cx                     ;59->数据段和代码段都指向同一个段

                                       ;59->8086处理器提供了除法指令div，它可以做两种类型的除法。
                                       ;59->第一种类型是用16位的二进制数除以8位的二进制数。
                                       ;59->在这种情况下，被除数必须在寄存器ax中，除数可以由8位的通用寄存器或者内存单元提供
                                       ;59->指令执行后，商在寄存器al中，余数在寄存器ah中

                                       ;60->第二种类型是用32位的二进制数除以16位的二进制数。
                                       ;60->在这种情况下，因为16位的处理器无法直接提供32位的被除数，故要求被除数的高16位在dx中，低16位在ax中
                                       ;60->除数可以由16位的通用寄存器或者内存单元提供
                                       ;60->指令执行后，商在寄存器ax中，余数在寄存器dx中
         ;求个位上的数字
         mov dx,0                      
         div bx
         mov [0x7c00+number+0x00],dl   ;保存个位上的数字

         ;求十位上的数字
         xor dx,dx
         div bx
         mov [0x7c00+number+0x01],dl   ;保存十位上的数字

         ;求百位上的数字
         xor dx,dx
         div bx
         mov [0x7c00+number+0x02],dl   ;保存百位上的数字

         ;求千位上的数字
         xor dx,dx
         div bx
         mov [0x7c00+number+0x03],dl   ;保存千位上的数字

         ;求万位上的数字 
         xor dx,dx
         div bx
         mov [0x7c00+number+0x04],dl   ;保存万位上的数字

         ;以下用十进制显示标号的偏移地址
         mov al,[0x7c00+number+0x04]
         add al,0x30
         mov [es:0x1a],al
         mov byte [es:0x1b],0x04
         
         mov al,[0x7c00+number+0x03]
         add al,0x30
         mov [es:0x1c],al
         mov byte [es:0x1d],0x04
         
         mov al,[0x7c00+number+0x02]
         add al,0x30
         mov [es:0x1e],al
         mov byte [es:0x1f],0x04

         mov al,[0x7c00+number+0x01]
         add al,0x30
         mov [es:0x20],al
         mov byte [es:0x21],0x04

         mov al,[0x7c00+number+0x00]
         add al,0x30
         mov [es:0x22],al
         mov byte [es:0x23],0x04
         
         mov byte [es:0x24],'D'
         mov byte [es:0x25],0x07
          
   infi: jmp near infi                 ;无限循环
                                       ;64->jmp是转移指令，用于使处理器脱离当前的执行序列，转移到特定的地方执行，关键字near表示目标位置依然在当前代码段内。
                                       ;65->对应的机器指令为E9FDFF，操作码0xE9，操作数0xFDFF
                                       ;65->编译器是这么做的:用标号(目标位置)处的汇编地址减去当前指令的汇编地址，再减去当前指令的长度，就得到jmp near infi指令的实际操作数
                                       ;65->在指令执行阶段，处理器用指令指针寄存器ip的内容加上该指令的操作数，再加上该指令的长度，就得到了要转移的实际偏移地址，同时CS寄存器的内容不变。
      
  number db 0,0,0,0,0                  ;59->伪指令db(declare byte)声明字节数据，声明超过一个以上的数据，各个操作数之间必须以逗号隔开。
                                       ;59->和指令不同，对于在程序中声明的数值，在编译阶段，编译器会在它们被声明的汇编地址处原样保留。
  
  times 203 db 0                       ;66->伪指令times可用于重复它后面的指令若干次。
            db 0x55,0xaa               ;66->计算机的设计者们决定，一个有效的主引导扇区，其最后两个字节的数据必须是0x55和0xAA。