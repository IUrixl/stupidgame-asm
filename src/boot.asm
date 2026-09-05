org 0x7c00
bits 16

jmp short bootloader
nop

oem_name db "IUrixlLabs"

bytes_per_sector dw 512
sectors_per_cluster db 1
reserved_sectors dw 1
fat_count db 2
root_entries dw 224
total_sectors dw 2880
media_descriptor db 0xF0
sectors_per_fat dw 9
sectors_per_track dw 18
head_count dw 2
hidden_sectors dd 0
total_sectors_big dd 0

drive_number db 0
reserved db 0
boot_signature db 0x29
volume_id dd 0x12345678
volume_label db "STUPIDGAME  "
filesystem_type db "FAT12   "

; ----------
; BOOTLOADER
; ----------

;
; adress = segment * 16 + offset
;

bootloader:
	cli ;; inicializamos los registros

	xor ax, ax
	mov ds, ax
	mov es, ax

	mov ss, ax		;; restauramos stack
	mov sp, 0x7c00

	sti

	mov [drive_number], dl ; guardamos el dl en drive_number

	; solicitar root
	mov si, root_params
	call load_lba

	; solicitar fat
	mov si, fat_params
	call load_lba

	; cargar game bin
	game_name: db "GAME    BIN"
	mov si, game_name
	call load_file

	hang:
		jmp $

%include "src/utils/disk.asm"

root_params: ; parametros para cargar el root
	.sectors: dw 14
	.lba: dq 19
	.offset: dw 0x8000
	.segment: dw 0x0000

fat_params: ; parametros para cargar el fat
	.sectors: dw 9
	.lba: dq 1
	.offset: dw 0x9c00 ; justo donde acaba el root
	.segment: dw 0x0000


times 510 - ($ - $$) db 0
dw 0xAA55 ; firma!