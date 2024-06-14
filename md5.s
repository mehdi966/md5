section .data
    MD5_INIT_VALUES dd 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
    PADDING db 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    SINE_TABLE dd 0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501, \
                0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, \
                0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8, \
                0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a, \
                0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, \
                0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665, \
                0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1, \
                0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391

section .bss
    msg resb 64  ; Buffer pour le message
    state resd 4 ; A, B, C, D
    count resq 1 ; Nombre de bits, modulo 2^64
    buffer resd 16 ; Buffer de 512 bits pour les blocs de message

section .text
    global _start

_start:
    ; Initialiser le contexte MD5
    mov eax, [MD5_INIT_VALUES]
    mov [state], eax
    mov eax, [MD5_INIT_VALUES + 4]
    mov [state + 4], eax
    mov eax, [MD5_INIT_VALUES + 8]
    mov [state + 8], eax
    mov eax, [MD5_INIT_VALUES + 12]
    mov [state + 12], eax

    ; Exemple de message : 'abcd'
    mov byte [msg], 'a'
    mov byte [msg + 1], 'b'
    mov byte [msg + 2], 'c'
    mov byte [msg + 3], 'd'
    xor rax, rax
    mov byte [msg + 4], al  ; Terminer la chaîne avec un caractère nul

    ; Longueur du message en bits
    mov rax, 32
    mov [count], rax

    ; Padding du message
    mov rax, [count]
    and rax, 63
    sub rax, 56
    js .pad_done
    lea rdi, [msg + rax]
    lea rsi, [PADDING]
    mov rcx, 64 - rax
    rep movsb

.pad_done:
    ; Ajouter la longueur originale du message (en bits) à la fin du message
    mov rax, [count]
    shl rax, 3
    mov ecx, eax
    mov [msg + 56], ecx
    shr rax, 32
    mov ecx, eax
    mov [msg + 60], ecx

    ; Traitement des blocs
    mov rdi, msg
    call md5_transform

    ; Finalisation et affichage
    call print_hash

    ; Sortie
    mov eax, 60  ; syscall: exit
    xor edi, edi ; status 0
    syscall

md5_transform:
    ; Initialisation des variables
    push rbx
    push rbp
    push rsi
    push rdi

    ; Charger le message dans des registres
    mov rsi, rdi
    mov edi, 16
    call md5_decode

    ; Sauvegarder l'état
    mov eax, [state]
    mov ebx, [state + 4]
    mov ecx, [state + 8]
    mov edx, [state + 12]

    ; Première passe de transformation
    ; F(x, y, z) = (x & y) | (~x & z)
    ; a = b + ((a + F(b, c, d) + x[k] + t[i]) <<< s)
    mov esi, eax
    mov edi, ebx
    and esi, edi
    mov edi, eax
    not edi
    and edi, ecx
    or esi, edi
    add esi, eax
    add esi, dword [buffer]
    add esi, dword [SINE_TABLE]
    rol esi, 7
    add esi, ebx
    mov eax, esi

    ; Ajoutez toutes les transformations restantes ici

    ; Mise à jour des valeurs de l'état
    add [state], eax
    add [state + 4], ebx
    add [state + 8], ecx
    add [state + 12], edx

    ; Libérer la pile
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret

md5_decode:
    ; Convertir les 64 octets du message en mots de 32 bits
    mov rcx, 16
    lea rdi, [buffer]
    lea rsi, [msg]
.decode_loop:
    mov eax, dword [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    loop .decode_loop
    ret

print_hash:
    ; Convertir et afficher l'état MD5 (A, B, C, D)
    mov rsi, state
    mov rdi, 4
.print_loop:
    mov eax, [rsi]
    call print_hex
    add rsi, 4
    dec rdi
    jnz .print_loop
    ret

print_hex:
    ; Convertir eax en hexadécimal et afficher
    push rbx
    push rcx
    push rdx
    mov rcx, 8
.print_hex_loop:
    rol eax, 4
    mov bl, al
    and bl, 0x0F
    cmp bl, 10
    jl .num
    add bl, 87 ; Convertir en 'a'-'f'
    jmp .print
.num:
    add bl, 48 ; Convertir en '0'-'9'
.print:
    mov rdx, 1
    mov rsi, rsp
    mov [rsp-1], bl
    sub rsp, 1
    mov rdi, 1
    mov eax, 0x01
    syscall
    add rsp, 1
    loop .print_hex_loop
    pop rdx
    pop rcx
    pop rbx
    ret
