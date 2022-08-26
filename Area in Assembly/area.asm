segment .data
l1: dd 2.0
segment .text
    global area
    extern printf
area:
    push ebx
    push esi
    push edi
    push ebp

    sub esp, 4
    mov byte [esp], '%'
    mov byte [esp + 1], 'f'
    mov byte [esp + 2], 10
    mov byte [esp + 3], 0

    ; [esp] ~ [esp + 3]: printf format (local variable) - ("%f" , 10 , 0)
    ;
    ; [esp + 4]:   previous ebx
    ; [esp + 8]:   previous esi
    ; [esp + 12]:  previous edi
    ; [esp + 16]:  previous ebp
    ;
    ; [esp + 20]:   return address
    ;
    ; [esp + 24]:  number of points - 32_bit signed int
    ; [esp + 28]:  32_bit floating point array
    
    ; ebx:        main loop iterator (array index) - i
    ; ebp:        number of points
    ; esi:        coordiantes array
    ; edi:        tmp

    mov ebp, dword [esp + 24]
    mov ebx, 0  ;i
    mov esi, dword [esp + 28]
    mov edi, 0

    fldz ; setting area to zero (st0 = area)

    main_loop: ; iterating over arrays (from 0 to n)

        mov edi,ebx
        shl edi,4 ;i*16
        fld dword [esi + edi]    ; loading x1 = array[i][0]

        mov edi,ebx
        inc edi ;i+1

        mov eax,edi
        xor edx,edx
        div ebp ;(i+1)%n
        mov edi,edx

        shl edi,4   ;[(i+1)%n]*16
        add edi,8   ;([(i+1)%n]*16)+8  
        fld dword [esi + edi] ; loading y2 = array[(i+1)%n][1]

        fmulp st1 ; calculating (x1 * y2)

        mov edi,ebx
        shl edi,4 ;i*16
        add edi,8
        fld dword [esi + edi]    ; loading y1 = array[i][1]

        mov edi,ebx
        inc edi

        mov eax,edi
        xor edx,edx
        div ebp
        mov edi,edx

        shl edi,4   ;(i+1)%n*16  
        fld dword [esi + edi] ; loading x2 = x[(i+1)%n][0]
        fmulp st1 ; calculating (y1 * x2)

        fsubp st1  ; calculating (x1 * y2) - (y1 * x2)

        faddp st1 ; area += (x1 * xn) - (yn * y1)

        inc ebx ;i++
        cmp ebx, ebp
        jl main_loop    ;i < n

    ftst    ;area,0
    jl iflable
    jmp elselable
    iflable:
        fchs    ;-area
    elselable:
        fld dword [l1]  ;st0 = 2.0
        fdivp st1 ;area / 2.0
        fabs

    endlable:
    ; output is already in st0
    add esp, 4 ; clearing local variables from stack
    pop ebp
    pop edi
    pop esi
    pop ebx

    ret