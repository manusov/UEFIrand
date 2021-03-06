;===========================================================================;
;                                                                           ;
;     RDRAND INSTRUCTION GRAPHICS DEMO. UEFI X64 EDITION. MAIN MODULE.      ;
;                                                                           ;
;===========================================================================;

;---------------------------------------------------------------------------;
;                         OPTIONS AND EQUATIONS.                            ;
;---------------------------------------------------------------------------;
INCLUDE 'ASM\SYS\equ_api.inc'	  ; Equations for UEFI API
INCLUDE 'ASM\SYS\equ_errs.inc'	; Equations for UEFI errors messages
INCLUDE 'ASM\SYS\equ_chkp.inc'	; Equations for Port 80 use
INCLUDE 'ASM\SYS\equ_vars.inc'	; Equations for variables access

format pe64 dll efi
entry main

;---------------------------------------------------------------------------;
;                        CODE SECTION, HEADBLOCK.                           ;
;---------------------------------------------------------------------------;
section '.text' code executable readable
main:

;---------- EFI application must save registers ----------------------------;
		push	rbx rcx rdx rsi rdi rbp
		push	r8 r9 r10 r11 r12 r13 r14 r15

;---------- Send first checkpoint code to Port 80h -------------------------;
		CHK	001h

;---------- Initializing parameters ----------------------------------------;
		cld
		mov	r15,Global_Variables_Pool
		mov	word [_Sys_Bitmap+r15],0

;---------- Save context received from firmware or UEFI shell --------------;
		mov	[_EFI_Handle+r15],rcx
		mov	[_EFI_Table+r15],rdx
		
;---------- Send first message to screen -----------------------------------;
		mov	al,07h
		call	Output_Attribute
		mov	rsi,Msg_CRLF_2
		call	String_Write			; Make new string
		mov	rsi,String_Version
		call	String_Write			; "Name+Copyright"
		mov	rsi,Program_Vendor_Data_1
		call	String_Write_Bold		; "http"
		mov	rsi,Msg_Starting
		call	String_Write			; "Starting..."

;---------- Start Program Sequence execution -------------------------------;
; Checkpoints 002h-01Bh
		mov	rsi,Start_Program_Sequence
		call	Start_Stop_Sequencer
		jc	Bad_Config

;---------- Drawings with random numbers visualization ---------------------;

		call	Random_Visual

;---------- Conditionally save sysinfo-benchmarks screen to BMP file -------;
; Note check all RDX because need differentiate keyboard/mouse by RDX.63 bit
Next_Sequence:	cmp	rdx,00000014h		; UEFI key code = F10
		jne	Skip_Screen		; Go skip if not F10 key
		call	Save_Screen_to_BMP
Skip_Screen:

;---------- Exit Program Sequence execution --------------------------------;
; Checkpoints 070h-076h
		mov	rsi,Stop_Program_Sequence
ESeq_Cycle:	call	Start_Stop_Sequencer
		jnc	ESeq_Stop
		push	rsi
		mov	rsi,Msg_Error_2
		call	String_Write
		call	Input_Wait_Key	; Wait for key press
		mov	rsi,Msg_CRLF	; Next string
		call	String_Write		
		pop	rsi
		jmp	ESeq_Cycle
ESeq_Stop:
;---------- Send last message to screen, before program vendor data --------;
		call	Status_Msg_Write	; Results of F9=TXT, F10=BMP
		mov	rsi,Msg_Exit
		call	String_Write

;---------- Message with program vendor data and/or requirements -----------;
		mov	rsi,Program_Vendor_Data
		call	String_Write_Bold
		mov	rsi,Msg_CRLF
		call	String_Write		; Carriage Return, Line Feed

;---------- Send last checkpoint code to Port 80h, for normal termination --;
		CHK	07Ch

;---------- Exit, EFI application must restore registers -------------------;
Exit_1: 	pop	r15 r14 r13 r12 r11 r10 r9 r8
		pop	rbp rdi rsi rdx rcx rbx
		xor	rax,rax 	; RAX=EFI_STATUS=0
		retn			; Simple form of termination

;---------- Exit if errors detected during check configuration -------------;
; Checkpoint 07Dh = Termination of program by errors, begin message
; Here RBP=Offset of error message central string
Bad_Config:	CHK	07Dh
		mov	rsi,Msg_Error_2 	; "Press any key"
		call	String_Write
		call	Input_Wait_Key
		mov	rsi,Msg_CRLF
		call	String_Write		; Carriage Return, Line Feed
;---------- Restore state for error branch ---------------------------------;
; Checkpoints 070h-075h (skip 76h)
		mov	rsi,Stop_Program_Sequence
ESeq_Cycle_1:	call	Start_Stop_Sequencer
		jnc	ESeq_Stop_1
		mov	rsi,Msg_CRLF
		call	String_Write		; Carriage Return, Line Feed
		jmp	ESeq_Cycle_1
ESeq_Stop_1:
;---------- Message with program vendor data and/or requirements -----------;
		mov	rsi,Msg_CRLF		; Next string
		call	String_Write		
		mov	rsi,Program_Vendor_Data
		call	String_Write_Bold
		mov	rsi,Msg_CRLF
		call	String_Write		; Carriage Return, Line Feed

;---------- Checkpoint 07Fh = Termination program by errors, exit to OS ----;
		CHK	07Fh

;---------- Go to exit point -----------------------------------------------;
		jmp	Exit_1

;---------------------------------------------------------------------------;
;                CODE SECTION, EXTERNAL MODULES CONNECT.                    ;
;---------------------------------------------------------------------------;
INCLUDE 'ASM\SYS\sequence.inc'	; Subroutine for control sequences execution

INCLUDE 'ASM\SYS\chk_cpuf.inc'	; Config verify handler: CPU features
INCLUDE 'ASM\SYS\chk_clk.inc'	; Config verify handler: Measure CPU Clock
INCLUDE 'ASM\SYS\chk_uefi.inc'	; Config verify handler: UEFI firmware cfg.
INCLUDE 'ASM\SYS\chk_mem.inc'	; Config verify handler: Free memory size
INCLUDE 'ASM\SYS\chk_acpi.inc'	; Config verify handler: ACPI detect
INCLUDE 'ASM\SYS\ld_cfg.inc'	; Loader handler: Load configuration file
INCLUDE 'ASM\SYS\chk_gvai.inc'	; Config verify handler: Get Video adp. info
INCLUDE 'ASM\SYS\chk_gvmi.inc'	; Config verify handler: Get Video mode info
INCLUDE 'ASM\SYS\chk_vflt.inc'	; Config verify handler: Check VRAM flat mode
INCLUDE 'ASM\SYS\chk_pci.inc'	; Config verify handler: Check PCI bus present
INCLUDE 'ASM\SYS\chk_avga.inc'	; Config verify handler: Check active Video
INCLUDE 'ASM\SYS\chk_bar.inc'	; Config verify handler: Check Video RAM BAR
INCLUDE 'ASM\SYS\chk_agp.inc'	; Config verify handler: Check AGP present
INCLUDE 'ASM\SYS\chk_pcie.inc'	; Config verify handler: Check PCIe present
INCLUDE 'ASM\SYS\chk_mtrr.inc'	; Config verify handler: Check MTRR present

INCLUDE 'ASM\SYS\set_agp.inc'	; Set context handler: AGP Fast Write
INCLUDE 'ASM\SYS\set_pcie.inc'	; Set context handler: PCIe Packet Size
INCLUDE 'ASM\SYS\set_mtrr.inc'	; Set context handler: MTRR for video memory
INCLUDE 'ASM\SYS\set_sse.inc'	; Set context handler: SSE enable
INCLUDE 'ASM\SYS\set_mous.inc'	; Set context handler: Detect mouse
INCLUDE 'ASM\SYS\set_game.inc'	; Set context handler: Game parameters
INCLUDE 'ASM\SYS\set_wait.inc'	; Wait user press any key for messages view
INCLUDE 'ASM\SYS\set_vmod.inc'	; Set context handler: graphics video mode

INCLUDE 'ASM\SYS\res_vmod.inc'	; Restore context handler: Text video mode
INCLUDE 'ASM\SYS\res_sse.inc'	; Restore context handler: SSE enable
INCLUDE 'ASM\SYS\res_mtrr.inc'	; Restore context handler: MTRR for v. memory
INCLUDE 'ASM\SYS\res_pcie.inc'	; Restore context handler: PCIe Packet Size
INCLUDE 'ASM\SYS\res_agp.inc'	; Restore context handler: AGP Fast Write
INCLUDE 'ASM\SYS\sv_cfg.inc'	; Saver handler: Save configuration file
INCLUDE 'ASM\SYS\res_mem.inc'	; Restore context handler: Memory requested

INCLUDE 'ASM\SYS\lib_acpi.inc'	; Library for ACPI tables interpreting
INCLUDE 'ASM\SYS\lib_pci.inc'	; Library for PCI regs. operations support
INCLUDE 'ASM\SYS\lib_agp.inc'	; Library for AGP operations support
INCLUDE 'ASM\SYS\lib_pcie.inc'	; Library for PCI Express operations support
INCLUDE 'ASM\SYS\lib_text.inc'	; Library for built text strings support
INCLUDE 'ASM\SYS\lib_inp.inc'	; Library for keyboard and mouse support
INCLUDE 'ASM\SYS\lib_out.inc'	; Library for UEFI simple text output support
INCLUDE 'ASM\SYS\lib_mem.inc'	; Library for UEFI memory info and allocate
INCLUDE 'ASM\SYS\lib_file.inc'	; Library for UEFI file operations support
INCLUDE 'ASM\SYS\lib_beep.inc'	; Library for sound generation by PC speaker
INCLUDE 'ASM\SYS\lib_tsc.inc'	; Library for timings and delays by TSC
INCLUDE 'ASM\SYS\lib_rtc.inc'	; Library for get date and time
INCLUDE 'ASM\SYS\lib_msg.inc'	; Library for errors and complete messages
INCLUDE 'ASM\SYS\lib_stxt.inc'	; Library for save report as TXT file
INCLUDE 'ASM\SYS\lib_sbmp.inc'	; Library for save screen image as BMP file
INCLUDE 'ASM\SYS\lib_efi.inc'	; Library for use EFI service routines

INCLUDE 'ASM\RAND\randbox.inc'	; Draw box with random numbers visualization

INCLUDE 'ASM\DRAW\scrcopy.inc'	; Screen data copy from RAM to Video RAM
INCLUDE 'ASM\DRAW\fastupdt.inc' ; Fast update transit buf and Video RAM
INCLUDE 'ASM\DRAW\drawbenc.inc' ; Special draw box, used for benchmarks
INCLUDE 'ASM\DRAW\drawbox.inc'	; Draw box, operation in the transit buffer
INCLUDE 'ASM\DRAW\drawchar.inc' ; Draw char, operation in the transit buffer
INCLUDE 'ASM\DRAW\drawsprt.inc' ; Draw and Get sprite, op. in the trans. buf.
INCLUDE 'ASM\DRAW\bmp2sprt.inc' ; Convert BMP format to sprite
INCLUDE 'ASM\DRAW\drawmous.inc' ; Draw mouse cursor, op. in the trans. buf.
INCLUDE 'ASM\DRAW\shiftbox.inc' ; Copy in the private buffer, for line fall

INCLUDE 'ASM\BLT\bltbenc.inc'	; Special draw box, used for BLT benchmarks

INCLUDE 'ASM\DUMP\regdump.inc'	; Write debug dump: CPU registers RAX-R15
INCLUDE 'ASM\DUMP\memdump.inc'	; Write debug dump: Memory 256 bytes at RSI

;---------------------------------------------------------------------------;
;                 DATA SECTION, EXTERNAL MODULES CONNECT.                   ;
;---------------------------------------------------------------------------;
section '.data' data readable writeable

INCLUDE 'ASM\NAMES\names_r.inc' ; Copyright and names for RDRAND

INCLUDE 'ASM\SYS\dat_efi.inc'	; Constants for UEFI support, GUIDs
INCLUDE 'ASM\SYS\dat_strn.inc'	; Text strings for program start and exit
INCLUDE 'ASM\SYS\dat_msg.inc'	; Text strings: errors and complete messages
INCLUDE 'ASM\SYS\dat_cpu.inc'	; Constants for CPU identification
INCLUDE 'ASM\SYS\dat_seq.inc'	; Tables for sequences execution
INCLUDE 'ASM\SYS\dat_cfg.inc'	; Tables for interpreting config file
INCLUDE 'ASM\SYS\dat_rtc.inc'	; Tables for built date and time strings
INCLUDE 'ASM\SYS\dat_stxt.inc'	; Tables for save report to TXT file
INCLUDE 'ASM\SYS\dat_sbmp.inc'	; Tables for save screen image to BMP file

INCLUDE 'ASM\RAND\dat_istr.inc' ; Test flow information strings

INCLUDE 'ASM\DRAW\dat_draw.inc' ; Video control variables and tables

INCLUDE 'ASM\DUMP\dat_dump.inc' ; Data for write debug dump

INCLUDE 'ASM\SYS\dat_vars.inc'	; Constants and variables, last for (?) data

;---------------------------------------------------------------------------;
;                       RELOCATION ELEMENTS SECTION.                        ;
;---------------------------------------------------------------------------;
section '.reloc' fixups data discardable
