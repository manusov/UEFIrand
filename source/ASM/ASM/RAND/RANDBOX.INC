;===========================================================================;
;                                                                           ;
;                  RANDOM NUMBERS VISUALIZATION SUBROUTINE.                 ;
;                                                                           ;
;===========================================================================;

;---------- Get system information sequence execution -------------------;
; INPUT:   R15 = Pointer to global variables pool, flat 64-bit address   ;
; OUTPUT:  RDX = EFI key code, after program interrupted by key press    ;
;          Registers corrupted, exclude R15=Saved                        ;
;------------------------------------------------------------------------;
Random_Visual:
;--- Blank transit buffer, draw frame, write strings ---
		call	Blank_Transit
		mov	rsi,String_Info_1
		mov	rdi,13*4	; RDI=Palette element
		mov	bx,[_Video_Xsize+r15]
		sub	bx,37*8		; BX=String base X, string 33+2 chars
		mov	dx,8		; DX=String base Y
		call	Local_Inf_String
		mov	rsi,String_Version	; RSI=String pointer
		mov	rdi,14*4  		; RDI=Palette element
		mov	bx,8			; BX=Xbase, pixels
		mov	dx,8			; DX=Ybase, pixels
		call	Local_Inf_String
		mov	rsi,Program_Vendor_Data	; RSI=String pointer
		mov	rdi,13*4  		; RDI=Palette element
		add	dx,16
		call	Local_Inf_String
		call	Screen_Copy

;--- Prepare for visualization cycle ---
		mov	rcx,[_Vmem_Base+r15]
		movzx	rax, word [_Video_Xsize+r15]
		shr	rax,1			; X/2 is X center of screen
		sub	rax,256			; X center - 256
		shl	rax,2			; Because 4 bytes per pixel
		add	rcx,rax
		movzx	rax,word [_Video_Ysize+r15]
		shr	rax,1			; Y/2 is Y center of screen
		sub	rax,256
		movzx	rsi,word [_Video_Xbytes+r15]
		mov	rbx,rsi
		mul	rbx
		add	rcx,rax			

;--- Visualization cycle ---
Visual_Cycle:
		rdrand	rbx
		jnc	Visual_Cycle		; Wait random number ready
		
		mov	rbp,Video_R_Width
		xor	edx,edx
		mov	al,bl
		call	Local_Palette_1		; Prepare Red Color
		shr	rbx,8
		mov	al,bl
		call	Local_Palette_1		; Prepare Green Color
		shr	rbx,8
		mov	al,bl
		call	Local_Palette_1		; Prepare Blue Color
		mov	edi,edx			; EDI = Pixel value
		shr	rbx,8
		mov	rax,rbx
		and	rbx,01FFh
		shl	rbx,2			; RAX = X random coordinate
		shr	rax,9
		and	rax,01FFh
		imul	rsi
		add	rbx,rax
;--- Write pixel ---
		mov	[rcx+rbx],edi
;--- Check input, cycle if no keys pressed ---
		call	Input_Check_Key
		jc	Visual_Cycle
;--- Exit ---
		ret

;---------- Local subroutines ----------------------------------------------;

;--- Write one string ------------------------------------;
; INPUT:   R15=Pointer to global variables pool           ;
;          RSI = String source pointer                    ;
;          RDI = Palette element pointer                  ;
;          BX  = Start X position, pixels                 ;
;          DX  = Start Y position, pixels                 ;
;          Global variables                               ;
; OUTPUT:  None                                           ;
;          Transit buffer and video memory updated        ;
;---------------------------------------------------------;
Local_Inf_String:
;--- Color, front and back ---
		mov	rcx,Runtime_Palette_256
		mov	eax,[rcx+rdi]
		mov	ebp,[rcx+00*4]
;--- Geometry ---
		mov	ecx,80001008h	; ECX.31=Mode, CH=Font Y, CL=Font X
;--- Draw ---
		jmp	Draw_String	; Update transit buffer
