;; codigo documentado para revisiones futuras xd, es un mierdero

load_lba: ; usado para cargar estructuras sabiendo el tamaño y el sector inicial
	push eax
	push bx

	mov bx, [si] ; cargamos los sectores (word)
	mov word [dap.sectors], bx

	mov eax, [si + 2] ; cargamos la primera parte de lba (qword) en dword
	mov dword [dap.lba], eax
	mov eax, [si + 6] ; la otra parte de lba
	mov dword [dap.lba + 4], eax

	mov bx, [si + 10] ; cargamos offset (word)
	mov word [dap.destination_offset], bx

	mov bx, [si + 12] ; cargamos segment (word)
	mov word [dap.destination_segment], bx

	push si ; guardamos temporalmente

	mov si, dap
	mov ah, 42h
	; dl ya contiene drive_number
	int 13h

	pop si
	pop bx
	pop eax

	ret

	dap:
		.size: db 0x10
		.reserved: db 0x00
		.sectors: dw 0
		.destination_offset: dw 0
		.destination_segment: dw 0
		.lba: dq 0

load_file: ; ds:si = dirrecion al nombre
	; el root empieza 0000:8000
	; el fat empieza 0000:9c00
	; el package se carga en 0000:AE00
	push ax
	push bx
	push cx

	; reiniciamos root_pos
	mov word [root_pos], 8000h

	; buscamos en el root
	mov ax, 0000h
	mov es, ax ; lo ponemos en 0 por que el fat esta en 0
	root_lookup:
		mov cx, 11 ; 11 caracteres a leer

		cmp word [root_pos], 9C00h
		je end_load_file

		push si ; guardamos si por si falla la busqueda
		mov di, [root_pos]
		repe cmpsb ; [ds:si] - [es:di]
		pop si ; restauramos si para la siguiente iteracion
		je init_file

		add word [root_pos], 32
		jmp root_lookup


	init_file:
		; cogemos el cluster inicial
		add word [root_pos], 26
		mov bx, [root_pos] ; desreferenciamos root_pos
		mov ax, [bx] ; desreferenciamos bx
		mov [cluster], ax
		; cargamos cluster en posicion temporal
		mov word [package_segment], 0x0000
		mov word [package_offset], 0xAE00
		call load_cluster

		; tenemos nuestro package en 0xAE00
		; 3 bytes -> firma
		; 2 bytes -> segment
		; 2 bytes -> offset
		; 1 byte -> run (saltar cuando cargue?)
		; si se ejecuta, se salta a la direccion puesta por el package sumando el offset de 8 bytes totales (saltando la cabecera)

		; guardamos los datos del package
		mov ax, [0xAE00 + 3]
		mov word [package_segment], ax
		mov word [package_entry_segment], ax
		mov ax, [0xAE00 + 5]
		mov word [package_offset], ax
		mov word [package_entry_offset], ax ; porque? lee en la zona de datos despues de la end_load_file si tanta curiosidad tienes paleto.
		mov al, [0xAE00 + 7]
		mov byte [should_run], al

		call clear_package ; limpiamos memoria ocupada por la primera carga

		; cargamos todos los clusters, desde el 1, hasta el ultimo en la memoria especificada
		call load_clusters

		jmp end_load_file

	load_clusters: ;; ESTA FUNCION ESTA MUY DOCUMENTADA DEBIDO A SU COMPLEJIDAD TECNICA Y POR QUE FAT12 ES UNA PUTA MIERDA Y TOCA MUCHO LA POLLA
		; vamos a por el siguiente cluster 
		; offset en el fat = cluster + cluster / 2
		push ax
		push bx
		push cx
		push di
		push es

		.cluster_loop:
			; cargamos el cluster actual antes de buscar el siguiente
			call load_cluster ; magia? no, el package_segment y package_offset ya han sido dados en el init file al leer el package

			mov ax, 0
			mov es, ax
			mov ax, 9C00h
			mov di, ax ; apuntamos al fat

			mov ax, [cluster]
			mov bx, [cluster]
			mov cx, [cluster] ; muchos movs, pero necesarios

			shr bx, 1 ; los cluster son unsigned, moviendolos un bit a la derecha lo dividimos por 2
			add ax, bx ; tenemos el offset del cluster en ax, si lo sumamos a la posicion donde tenemos el fat obtenemos el siguiente cluster

			add di, ax ; sumamos el offset al fat
			mov bx, [es:di] ; cargamos el valor leido, son 16 bits de los cuales solo nos interesan 12

			test cx, 1 ; si cluster inicial es par aplicaremos mascara, si es impar desplazamiento, tenemos que quedarnos con 12 bits de los 16 que hemos sacado del fat
			jz .apply_cluster_mask

			; esto se ejecuta si es impar
			; debemos borrar los ultimos 4 bits, los deslpazamos, asi nos quedamos con los primeros 4 bits vacios y los otros 12 con el cluster
			shr bx, 4
			jmp .process_next

			.apply_cluster_mask:
				and bx, 0xFFF ;; 0xFFF son 12 bits encendidos, es la mascara, asi quitamos los 4 primeros bits y nos quedamos con 4 vacios y 12 con el cluster jeje 
				jmp .process_next

			; aqui ya se deben haber aplicado las transformaciones al cluster guardado en bx
			.process_next:
				; ahora procesaremos si debemos seguir en el bucle o romper
				; para eso debemos ver si el valor (unsigned) del cluster es mayor a 0xFF8, ya que de 0xFF8 a 0xFFF estan reservados para el end of chain de fat
				cmp bx, 0xFF8
				jae end_cluster_iteration ; jae es jump if above or equal, asi acabamos ya la carga del archivo

				; si aun queda por cargar
				mov [cluster], bx ; movemos el valor a cluster

				add word [package_offset], 512 ; sumamos 512 bytes a la posicion de package_offset
				jnc .cluster_loop ; si no hay overflow seguimos
				; si hay overflow
				add word [package_segment], 1000h
				jmp .cluster_loop ; volvemos a cargar

		end_cluster_iteration:
			pop es
			pop di
			pop cx
			pop bx
			pop ax

		ret

	load_cluster:
		; calculamos lba
		mov bx, 33
		mov cx, [cluster]
		sub cx, 2
		add bx, cx

		mov word [dap.lba], bx
		mov word [dap.sectors], 1
		mov ax, [package_segment]
		mov word [dap.destination_segment], ax
		mov ax, [package_offset]
		mov word [dap.destination_offset], ax

		push si
		mov dl, [drive_number]
		mov si, dap
		mov ah, 42h
		int 13h
		pop si

		ret

	clear_package:
		push di
		push bx

		mov bx, 512
		mov di, 0xAE00

		.clear_loop:
			; vamos a escribir 512 bytes en 0 desde 0xAE00 para limpiar el package
			mov word [di], 0
			inc di ; incrementamos memoria
			dec bx ; decrementamos contador
			cmp bx, 0
			jne .clear_loop

		pop bx
		pop di
		ret

	end_load_file:
		pop cx
		pop bx
		pop ax

		; volvemos al inicio o saltamos al paquete cargado?
		cmp byte [should_run], 1
		je .far_jump

		ret ; si no hay que moverse a ningun lado volvemos al lugar de inicio

		.far_jump:
			mov ax, [package_entry_segment]
			mov bx, [package_entry_offset]
			add bx, 8 ; saltamos el package y vamos al codigo

			push ax
			push bx
			retf

		;; datos!
		should_run: db 0
		cluster: dw 0
		root_pos: dw 8000h
		package_entry_offset: dw 0 ; en esencia es el primer offset, ya que el offset se ira incrementando al cargar clusters
		package_entry_segment: dw 0 ; lo mismo que el entry offset
		package_offset: dw 0
		package_segment: dw 0