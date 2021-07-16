        mov ax,0x2000
        mov ds,ax

        mov eax,0xffff
        mov dl,[eax]

        mov edx,[eax]

        cli
        hlt
                             
        times 510-($-$$) db 0
                         db 0x55,0xaa
