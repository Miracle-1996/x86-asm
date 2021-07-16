         ;文件名：c13_app0.asm
         ;文件说明：用户程序 
         
;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;程序总长度#0x00
         
         head_len         dd header_end           ;程序头部的长度#0x04

         prgentry         dd start                ;程序入口#0x08
         code_seg         dd section.code.start   ;代码段位置#0x0c
         code_len         dd code_end             ;代码段长度#0x10

         data_seg         dd section.data.start   ;数据段位置#0x14
         data_len         dd data_end             ;数据段长度#0x18

         stack_seg        dd section.stack.start  ;栈段位置#0x1c
         stack_len        dd stack_end            ;栈段长度#0x20
             
header_end:

;===============================================================================
SECTION data vstart=0

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0

data_end:

;===============================================================================
SECTION stack vstart=0

        times 2048        db 0                    ;保留2KB的栈空间

stack_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0

start:
         mov eax,ds
         mov fs,eax

         ;mov eax,[stack_seg]
         ;mov ss,eax
         ;mov esp,stack_end

         ;mov eax,[data_seg]
         ;mov ds,eax

         ;用户程序要做的事情（省略）

         retf                                     ;将控制权返回到系统

code_end:

;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end:
