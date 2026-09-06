; libreria que contiene todas las funciones que necesito para dibujar en mi pantalla

render_sprite: ;ax = offset_x ; bh = offset_y, ; bl = asset_id
	; vamos a buscar el sprite asset_id en la tabla para coger segment y offset
	push cx ; guardamos cx por que lo vamos a usar como ayudante todo el rato
	call get_asset_position
	call load_header
	
	mov word [graphics.rendering_offx], ax
	
	push ax ; guardamos el offset x
	mov al, bh
	mov ah, 0

	mov word [graphics.rendering_offy], ax ; lo guardamos como word, por que aun que el maximo del pixel sea 200 y por tanto un byte, el offset
	pop ax ; restauramos offset x          | puede hacer que se ponga el sprite en y 200, simplemente no se renderizara, pero la posicion del sprite sera esa

	call sprite

	pop cx
	ret

	sprite:
		; aqui se hace el algoritmo de renderizando mediante la funcion helper general "pixel" descrita abajo
		push ax
		push bx
		push cx
		push dx
		push es
		push di

		mov ax, [graphics.rendering_segment]
		mov es, ax ; posicionamos el segment
		mov ax, [graphics.rendering_offset]
		mov di, ax ; posicionames el offset
		add di, 7 ; saltamos el header

		mov cx, 0 ; contador x respecto el widht
		mov dx, 0 ; contador y
		.plot:
			cmp word cx, [graphics.rendering_width]
			jnge .process_plot

			add dx, 1 ; sumamos uno a y 
			mov cx, 0 ; reseteamos x
			cmp word dx, [graphics.rendering_height]
			jnge .process_plot

			; ya esta todo dibujado
			jmp .end_plot

			; aqui es donde calculamos 
			.process_plot:
				; leemos valor del pixel
				mov al, [es:di]
				mov [graphics.rendering_pixel], al ; guardamos el pixel

				cmp byte [graphics.rendering_pixel], 255
				je .prepare_next ; el 255 lo hemos reservado para pixeles transparentes, los saltamos

				; calculo de posicion de pixel
				mov ax, cx
				add ax, [graphics.rendering_offx] ; le sumamos el offset x del sprite

				mov bx, dx
				add bl, [graphics.rendering_offy] ; le sumamos el offset y del sprite

				cmp ax, 320 ; como empezamos en x 0, cuando llega a 319 ya se dibujan 320 pixeles, asi que...
				jge .prepare_next
				cmp ax, 0
				jl .prepare_next ; comprobamos que se pueda dibujar en pantalla

				cmp bx, 200 ; lo mismo que la x
				jge .prepare_next
				cmp bx, 0
				jl .prepare_next

				; si seguimos aqui es que podemos dibujar el pixel, preparamos todo para la llamada
				; tenemos que mover la y a bh y el pixel a bl
				push ax
				mov ax, bx ; movemos y a ax
				mov bh, al
				mov bl, [graphics.rendering_pixel] ; movemos el color
				pop ax ; restauramos ax con el valor

				call pixel ;ax = x ; bh = y; bl = color :)

				; se prepara el sigguiente
			.prepare_next:
				add di, 1 ; avanzamos el offset
				add cx, 1 ; avanzamos el recorrido
				jmp .plot
			
		.end_plot:
			pop di
			pop es
			pop dx
			pop cx
			pop bx
			pop ax
			ret

	get_asset_position:
		push es
		push di

		push ax
		mov ax, 0x2000
		mov es, ax
		pop ax ; ponemos es apuntando al segmento de la tabla

		; calculamos offset
		mov cl, bl
		mov ch, 0
		imul cx, cx, 4
		mov di, cx ; movemos offset a di

		mov cx, [es:di]
		mov word [graphics.rendering_segment], cx ; leemos los primeros 2 bytes, nos dan el segment (si tienes dudas de pq lee src/utils/assets.asm)

		add di, 2
		mov cx, [es:di]
		mov word [graphics.rendering_offset], cx ; leemos los segundos 2 bytes, nos dan el offset

		pop di
		pop es
		ret

	load_header:
		; en teoria todos los assets tendran una cabecera de 7 bytes, siendo los 3 primeros una firma (magic), y los otros 4, ancho y altura, dividido en 2 bytes
		push es
		push di

		mov es, [graphics.rendering_segment]
		mov di, [graphics.rendering_offset]

		add di, 3; vamos a saltarnos la firma
		mov cx, [es:di]
		mov word [graphics.rendering_width], cx

		add di, 2; saltamos el ancho y vamos a por el alto
		mov cx, [es:di]
		mov word [graphics.rendering_height], cx

		pop di
		pop es
		ret


pixel: ;ax = x ; bh = y; bl = color :)
	push cx ; guardamos cx ya que en cx guardaremos la y * 320 (para el offset del VGA es = (y*320)+x)
	push es
	push di ; los guardamos pq los usaremos ahora para mover el byte al buffer de VGA

	mov cl, bh ; lo movemos a cx pa hacer la multiplicacion, por que aun que y sea un byte, el numero que necesitamos es un word
	mov ch, 0

	imul cx, cx, 320 ; multiplicamos por 320

	add ax, cx

	mov es, [graphics.vga_segment]
	mov di, ax

	mov [es:di], bl

	pop di
	pop es
	pop cx
	ret

set_mode: ; esto es mas que nada para limpiar game.asm un poquito
	mov ah, 0x00
	mov al, 0x13
	int 0x10
	ret

graphics:
	; informacion para los assets
	.rendering_offset: dw 0
	.rendering_segment: dw 0

	; informacion del sprite
	.rendering_width: dw 0
	.rendering_height: dw 0
	.rendering_offx: dw 0
	.rendering_offy: dw 0

	.rendering_pixel: db 0

	.vga_segment: dw 0xA000