section .data
    ; Entrées de test pour le calcul du Hash
    entree_test_1 db 'mehdi', 0
    entree_test_2 db 'esgi', 0
    entree_test_3 db 'google', 0

    ; Calcul des longueurs des entrées
    entree_test_1_longueur equ $ - entree_test_1
    entree_test_2_longueur equ $ - entree_test_2
    entree_test_3_longueur equ $ - entree_test_3

    ; Constantes et tables nécessaires pour l'algorithme de Hash
    INIT_A equ 0x67452301
    INIT_B equ 0xEFCDAB89
    INIT_C equ 0x98BADCFE
    INIT_D equ 0x10325476

    VALEURS_ROTATION db 7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21

    TABLEAU_T dd 0xD76AA478, 0xE8C7B756, 0x242070DB, 0xC1BDCEEE, 0xF57C0FAF, 0x4787C62A, 0xA8304613, 0xFD469501, \
                0x698098D8, 0x8B44F7AF, 0xFFFF5BB1, 0x895CD7BE, 0x6B901122, 0xFD987193, 0xA679438E, 0x49B40821, \
                0xF61E2562, 0xC040B340, 0x265E5A51, 0xE9B6C7AA, 0xD62F105D, 0x02441453, 0xD8A1E681, 0xE7D3FBC8, \
                0x21E1CDE6, 0xC33707D6, 0xF4D50D87, 0x455A14ED, 0xA9E3E905, 0xFCEFA3F8, 0x676F02D9, 0x8D2A4C8A, \
                0xFFFA3942, 0x8771F681, 0x6D9D6122, 0xFDE5380C, 0xA4BEEA44, 0x4BDECFA9, 0xF6BB4B60, 0xBEBFBC70, \
                0x289B7EC6, 0xEAA127FA, 0xD4EF3085, 0x04881D05, 0xD9D4D039, 0xE6DB99E5, 0x1FA27CF8, 0xC4AC5665, \
                0xF4292244, 0x432AFF97, 0xAB9423A7, 0xFC93A039, 0x655B59C3, 0x8F0CCC92, 0xFFEFF47D, 0x85845DD1, \
                0x6FA87E4F, 0xFE2CE6E0, 0xA3014314, 0x4E0811A1, 0xF7537E82, 0xBD3AF235, 0x2AD7D2BB, 0xEB86D391

    TABLEAU_INDEX_TAMPON dw 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 4, 24, 44, 0, 20, 40, 60, 16, 36, 56, 12, 32, 52, 8, 28, 48, 20, 32, 44, 56, 4, 16, 28, 40, 52, 0, 12, 24, 36, 48, 60, 8, 0, 28, 56, 20, 48, 12, 40, 4, 32, 60, 24, 52, 16, 44, 8, 36

section .bss
    tampon_sortie resb 16  ; Tampon pour le résultat du Hash (128 bits = 16 octets)
    octets_fin times 128 db 0
    longueur_message dq 0
    nombre_blocs dq 0
    numero_blocs_octets_fin dq 0
    hash_a dq 0
    hash_b dq 0
    hash_c dq 0
    hash_d dq 0

section .text
    global _start

_start:
    ; Initialiser les entrées de test
    mov rsi, entree_test_1
    mov cx, entree_test_1_longueur
    lea rdi, [tampon_sortie]
    call compute_hash

    ; Sortie du programme
    mov rax, 60  ; syscall: exit
    xor rdi, rdi ; status 0
    syscall

compute_hash:
    cld ; Effacer le drapeau de direction

    ; Sauvegarde des registres
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    push    rdi

    mov     [longueur_message], cx ; Stocker la longueur du message

    ; Calcul du nombre de blocs de 64 octets
    mov     rbx, rcx
    shr     rbx, 6
    mov     [numero_blocs_octets_fin], rbx
    mov     [nombre_blocs], rbx
    inc     qword [nombre_blocs] ; Incrémenter le nombre de blocs

    ; Copier les octets restants
    shl     rbx, 6
    add     rsi, rbx
    and     cx, 0x3f
    mov     rdi, octets_fin
    rep movsb ; Répéter la copie de cx octets de rsi vers rdi

    ; Ajouter le bit 1 à la fin du message
    mov     al, 0x80
    stosb ; Stocker al à l'adresse de rdi

    ; Remplir avec des bits 0 jusqu'à 56 octets restants
    sub     cx, 55
    neg     cx
    jge     add_padding
    add     cx, 64
    inc     qword [nombre_blocs]
add_padding:
    xor     eax, eax
    rep stosb ; Remplir avec des 0

    ; Ajouter la longueur du message en bits à la fin
    mov     rax, [longueur_message]
    shl     rax, 3
    mov     rcx, 8
store_message_len:
    stosb
    shr     rax, 8
    dec     rcx
    jnz     store_message_len

    ; Initialiser les valeurs de hachage
    pop     rdi
    mov     rax, INIT_A
    mov     [hash_a], rax
    mov     rax, INIT_B
    mov     [hash_b], rax
    mov     rax, INIT_C
    mov     [hash_c], rax
    mov     rax, INIT_D
    mov     [hash_d], rax

block_loop:
    push    rcx
    cmp     cx, [numero_blocs_octets_fin]
    jne     backup_abcd
    mov     rsi, octets_fin ; Utiliser les octets finaux pour les derniers blocs
backup_abcd:
    ; Sauvegarder les valeurs actuelles des variables de hachage
    push    qword [hash_d]
    push    qword [hash_c]
    push    qword [hash_b]
    push    qword [hash_a]
    xor     rcx, rcx
    xor     rax, rax
main_loop:
    push    rcx
    mov     ax, cx
    shr     ax, 4 ; Diviser cx par 16
    test    al, al
    jz      pass0
    cmp     al, 1
    je      pass1
    cmp     al, 2
    je      pass2

    ; Pass3
    mov     rax, [hash_c]
    mov     rbx, [hash_d]
    not     rbx
    or      rbx, [hash_b]
    xor     rax, rbx
    jmp     do_rotate

pass0:
    ; Transformation F
    mov     rax, [hash_b]
    mov     rbx, rax
    and     rax, [hash_c]
    not     rbx
    and     rbx, [hash_d]
    or      rax, rbx
    jmp     do_rotate

pass1:
    ; Transformation G
    mov     rax, [hash_d]
    mov     rdx, rax
    and     rax, [hash_b]
    not     rdx
    and     rdx, [hash_c]
    or      rax, rdx
    jmp     do_rotate

pass2:
    ; Transformation H
    mov     rax, [hash_b]
    xor     rax, [hash_c]
    xor     rax, [hash_d]

do_rotate:
    ; Ajout de diverses constantes et valeurs
    add     rax, [hash_a]
    mov     bx, cx
    shl     bx, 1
    mov     bx, [TABLEAU_INDEX_TAMPON + rbx]
    add     rax, [rsi + rbx]
    mov     bx, cx
    shl     bx, 2
    add     rax, dword [TABLEAU_T + rbx]
    mov     bx, cx
    ror     bx, 2
    shr     bl, 2
    rol     bx, 2
    mov     cl, [VALEURS_ROTATION + rbx]
    rol     rax, cl
    add     rax, [hash_b]

    ; Mise à jour des valeurs de hachage
    push    rax
    push    qword [hash_b]
    push    qword [hash_c]
    push    qword [hash_d]
    pop     qword [hash_a]
    pop     qword [hash_d]
    pop     qword [hash_c]
    pop     qword [hash_b]
    pop     rcx
    inc     cx
    cmp     cx, 64
    jb      main_loop

    ; Ajouter aux valeurs originales
    pop     rax
    add     [hash_a], rax
    pop     rax
    add     [hash_b], rax
    pop     rax
    add     [hash_c], rax
    pop     rax
    add     [hash_d], rax

    ; Avancer les pointeurs
    add     rsi, 64
    pop     rcx
    inc     cx
    cmp     cx, [nombre_blocs]
    jne     block_loop

    ; Stocker le résultat final
    mov     cx, 4
    mov     rsi, hash_a
    pop     rdi
    rep movsq ; Copier les résultats finaux dans le tampon de sortie
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret
