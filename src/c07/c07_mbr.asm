         ;代码清单7-1
         ;文件名：c07_mbr.asm
         ;文件说明：硬盘主引导扇区代码
         ;创建日期：2011-4-13 18:02
         
         jmp near start
	
 message db '1+2+3+...+100='    ;98->nasm支持这样的做法,在编译阶段,编译器将把它们拆开,以形成一个个单独的字节
        
 start:
         mov ax,0x7c0           ;设置数据段的段基地址 
         mov ds,ax

         mov ax,0xb800          ;设置附加段基址到显示缓冲区
         mov es,ax

         ;以下显示字符串 
         mov si,message          
         mov di,0
         mov cx,start-message
     @g:
         mov al,[si]
         mov [es:di],al
         inc di
         mov byte [es:di],0x07
         inc di
         inc si
         loop @g

         ;以下计算1到100的和 
         xor ax,ax
         mov cx,1
     @f:
         add ax,cx
         inc cx
         cmp cx,100             ;91->cmp指令在功能上和sub指令相同,唯一不同之处在于,cmp指令仅仅根据计算的结果设置相应的标志位,而不保留计算结果
                                ;91->cmp指令将会影响到CF、OF、SF、ZF、AF和PF标志位
         jle @f                 ;91->less or equal

         ;以下计算累加和的每个数位 
         xor cx,cx              ;设置堆栈段的段基地址
         ;100->定义栈需要两个连续的步骤:即初始化段寄存器ss和栈指针sp的内容
         mov ss,cx
         mov sp,cx

         mov bx,10
         xor cx,cx
     @d:
         inc cx
         xor dx,dx
         div bx
         or dl,0x30
         push dx                ;102->push指令只接受16位的操作数
         cmp ax,0
         jne @d

         ;以下显示各个数位 
     @a:
         pop dx
         mov [es:di],dl
         inc di
         mov byte [es:di],0x07
         inc di
         loop @a
       
         jmp near $ 
       

times 510-($-$$) db 0
                 db 0x55,0xaa