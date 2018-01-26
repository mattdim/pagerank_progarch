


section .data

zero:		dd		0.0


section .bss

section .text

global calcolaDeltaS

extern get_block
extern free_block

%macro	getmem	2
	mov	eax, %1
	push	eax
	mov	eax, %2
	push	eax
	call	get_block
	add	esp, 8
%endmacro

%macro	fremem	1
	push	%1
	call	free_block
	add	esp, 4
%endmacro

delta		equ		8
n		equ		12
pr		equ		16
temp		equ		20

p		equ 		4


calcolaDeltaS:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		ebp							; salva il Base Pointer
		mov		ebp, esp						; il Base Pointer punta al Record di Attivazione corrente
		push		ebx							; salva i registri da preservare
		push		esi
		push		edi

		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
		
		mov		ecx, [ebp+n]
		sub		esp, 4	
		mov	dword	[ebp-p], 4
		
		
		mov		eax, [ebp+delta]
		movss		xmm0, [zero]
		movss		[eax], xmm0				
			
		
		xor 		esi, esi			; i=0
	FORIQ: 	mov 		ebx, [ebp+pr]        	
		movups 		xmm0, [ebx+esi]			; pr[i]
		mov 		ebx, [ebp+temp]				
		movups		xmm1, [ebx+esi]			; temp[i]
		
		subps		xmm0, xmm1
		movups		xmm5, xmm0
		psrld		xmm5, 31			; shift a dx di 31, prendo il segno
		pslld		xmm5, 31			; shift a sx di 31
		xorps		xmm0, xmm5			; cambio di segno i negativi

		movups		xmm7, xmm0			; xmm7 = d[0..3]
		haddps		xmm7, xmm7			; xmm7 = {d0+d1, d2+d3, d0+d1, d2+d3}
		haddps		xmm7, xmm7			; xmm7 = {d0+d1+d2+d3,..x4}
		mov		eax, [ebp+delta]		
	prova3:	movss		xmm6, [eax]		
		addss		xmm6, xmm7		; delta+= somma parziale
		movss		[eax], xmm6		
		
		mov 		eax, ecx
		xor 		edx, edx
		mov 		ebx, [ebp-p]
		div 		dword ebx			; eax = n/p
		imul		ebx, 4
		imul		eax, ebx
		add		esi, ebx
		cmp		esi, eax		
		jb 		FORIQ
		
		
	FORIR:	mov	 	ebx, [ebp+pr]
		movss		xmm0,[ebx+esi]
		mov 		ebx, [ebp+temp]
		movss		xmm1, [ebx+esi]
		subss		xmm0, xmm1
		movss		xmm2, xmm0
		psrld		xmm2, 31			; shift a dx di 31, prendo il segno
		pslld		xmm2, 31			; shift a sx di 31
		xorps		xmm0, xmm2			; cambio di segno i negativi

	CONT:	mov		eax, [ebp+delta]
		movss		xmm6, [eax]
		addss		xmm6, xmm0
		movss		[eax], xmm6
		add		esi, 4
		mov		eax, ecx
		imul		eax, 4	
		cmp		esi, ecx
		jb 		FORIR	
		

		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------
		
		

		pop	edi									; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, ebp								; ripristina lo Stack Pointer
		pop	ebp									; ripristina il Base Pointer
		ret										; torna alla funzione C chiamante
