delay:
	; 18,2 ticks == 1 sec
	; 55ms == 1 tick
	; ticks a esperar en SI
	push ax
	push bx
	push cx
	push dx 
	push di ; guardamos todos los valores para no joder otros procesos

	mov ah, 00h
	int 1ah

	mov [origin_time], dx ; parte baja del tiempo, los otros 16 bits nos la pelan

	delay_loop:
		int 1ah

		sub dx, [origin_time]
		cmp dx, si
		je end_delay
		jmp delay_loop

	end:
		pop di
		pop dx
		pop cx
		pop bx
		pop ax ; restauramos valores
		ret

origin_time dw 0