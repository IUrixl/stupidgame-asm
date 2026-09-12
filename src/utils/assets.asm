; libreria para cargar assets
; mucho de esto se parece a disk.asm, pero aqui buscamos cargar los assets en ciertos puntos
; de la memoria y ir incrementandolo y guardandolo en una lookup table


load_asset: ; ds:si = direccion al nombre del asset
	push es
	push eax
	push ebx
	push ecx

	mov word [assets.root_pos], 8000h
	mov ax, 0x0000
	mov es, ax

	; buscamos en el root el archivo
	root_lookup:
		mov cx, 11 ; queremos leer 11 caracteres

		cmp word [assets.root_pos], 9C00H
		je end_load_asset

		push si ; guardamos si por si lo perdemos
		mov di, [assets.root_pos] ; nos ponemos en el inico de la entrada
		repe cmpsb ; [ds:si] - [es:di] mas de lo mismo
		pop si
		je register_asset ; si tiene el nombre que buscamos entonces registramos el asset

		add word [assets.root_pos], 32
		jmp root_lookup
	
	register_asset:
		; vamos a guardar el cluster
		add word [assets.root_pos], 26 ; empieza en 26
		mov bx, [assets.root_pos]
		mov ax, [es:bx]
		mov [assets.cluster], ax

		; creamos la entrada en la tabla
		call table_new_entry

		; cargamos clusters
		call load_clusters

		jmp end_load_asset

	load_clusters:
		push ax
		push bx
		push cx
		push di
		push es

		.cluster_loop:
			call load_cluster

			mov ax, 0
			mov es, ax
			mov ax, 9c00h
			mov di, ax ; apuntamos al fat

			mov ax, [assets.cluster]
			mov bx, [assets.cluster]
			mov cx, [assets.cluster]

			shr bx, 1
			add ax, bx ; el por que de todo esto esta en src/utils/disk.asm

			add di, ax
			mov bx, [es:di] ; cargamos el valor de lfat

			; decidamos con que nos quedamos
			test cx, 1 ; es el cluster inicial par?
			jz .apply_cluster_mask

			; es impar.
			shr bx, 4
			jmp .process_next

			.apply_cluster_mask:
				and bx, 0xFFF ;; 12 bits encendidos
				jmp .process_next

			.process_next:
				cmp bx, 0xFF8 ; comprobamos si es el ultimo cluster
				jae load_clusters.end_cluster_iteration ; explicacion en src/utils/disk.asm

				mov [assets.cluster], bx; guardamos el siguiente cluster

				add word [assets.assets_offset], 512 
				jnc .cluster_loop
				; overflown
				add word [assets.assets_segment], 1000h
				jmp .cluster_loop

		.end_cluster_iteration:
		pop es
		pop di
		pop cx
		pop bx
		pop ax
		ret

	load_cluster:
		; lba
		mov bx, 33
		mov cx, [assets.cluster]
		sub cx, 2
		add bx, cx

		mov word [dap.lba], bx
		mov ax, [assets.assets_entry_segment]
		add ax, [assets.assets_segment]
		mov word [dap.destination_segment], ax
		mov ax, [assets.assets_offset]
		mov word [dap.destination_offset], ax

		push si
		mov dl, [drive_number]
		mov si, dap
		mov ah, 42h
		int 13h
		pop si
		ret

	table_new_entry:
		push es
		push di
		push ax
		push bx

		mov es, [assets.table_entry_segment] ; nos ponemos en el segmento de la tabla
		mov di, [assets.table_offset] ; nos ponemos en el offset

		; calculamos los valores que escribiremos en la tabla
		mov ax, [assets.assets_entry_segment] 
		add ax, [assets.assets_segment] ; calculamos en que segmento estamos ahora

		mov bx, [assets.assets_offset] ; cargamos el offset

		mov word [es:di], ax ; movemos el segment
		add di, 2
		mov word [es:di], bx ; movemos el offset

		; preparamos el table_offset para la siguiente
		add word [assets.table_offset], 4

		pop bx
		pop ax
		pop di
		pop es
		ret

	end_load_asset:
		pop ecx
		pop ebx
		pop eax
		pop es
		ret

dap:
	.size: db 0x10
	.reserved: db 0x00
	.sectors: dw 1
	.destination_offset: dw 0
	.destination_segment: dw 0
	.lba dq 0

assets:
	.cluster: dw 0
	.root_pos: dw 8000h

	.table_entry_segment: dw 0x2000
	.table_offset: dw 0x0000 ; son 4 bytes roñosos por entrada, no necesitamos segments
	
	.assets_entry_segment: dw 0x3000
	.assets_segment: dw 0x0000 ; estas variables las usaremos para sumarselas a las fijas
	.assets_offset: dw 0x0000 ; las modificaremos cuando escribamos un asset, asi ya sabemos donde va empieza el siguiente