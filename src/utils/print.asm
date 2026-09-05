print:
	; la direccion del mensaje esta en SI
	mov ah, 0x0E
	mov al, [si]
	int 10h

	inc si
	cmp byte [si], 0
	jne print

	mov al, 0x0D
	int 10h

	mov al, 0x0A
	int 10h

	ret