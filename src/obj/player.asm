player:
	.pos_x: dw 0
	.pos_y: dw 0

	player_update:
		push ax

		.keyboard:
			;; keycodes en https://www.fountainware.com/EXPL/bios_key_codes.htm
			
			.key_w:
				mov al, 0x11
				call get_key_state

				cmp al, 1
				jne .key_s

				sub word [player.pos_y], 1

			.key_s:
				mov al, 0x1f
				call get_key_state

				cmp al, 1
				jne .key_a

				add word [player.pos_y], 1

			.key_a:
				mov al, 0x1e
				call get_key_state

				cmp al, 1
				jne .key_d

				sub word [player.pos_x], 1

			.key_d:
				mov al, 0x20
				call get_key_state

				cmp al, 1
				jne .end_keyboard

				add word [player.pos_x], 1

		; end of the keyboard jump
		.end_keyboard:

		pop ax
		ret

	;; voy a intentar que los metodos del jugador sean privados todos para poder usar nombres mas generales y llamarlos con player.funcion
	player_render:
		mov ax, [player.pos_x] ; offset x
		mov bx, [player.pos_y] ; offset y
		mov dl, 0 ; asset id
		call render_sprite
		ret