section .data

zero:		dd		0.0

section .bss

section .text

global calcolaRis

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

pr		equ		16
n		equ		12

UNROLL		equ		4
p		equ		8
result		equ		12
norma		equ		16

calcolaRis:
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
		
		getmem		4, [ebp+n]
		sub		esp, 16
		mov		[ebp-result], eax
		mov	dword	[ebp-p], 4
		mov	dword	[ebp-UNROLL], 4
		movss		xmm0, [zero]
		movss		[ebp-norma], xmm0

		mov		eax, [ebp+n]		
		mov		ebx, [ebp-p]
		xor		edx, edx
		imul		ebx, [ebp-UNROLL]		; p*UNROLL
		div		ebx				; n/(p*UNROLL)
		imul		ebx, 4
		mov		edi, [ebp+n]
		imul		edi, 4
		mov		edx, [ebp+pr]
		
		mov		esi, 0
	FORI1Q:	movups		xmm1, [edx+esi]
		movups		xmm2, [edx+esi+16]	
		movups		xmm3, [edx+esi+32]		
		movups		xmm4, [edx+esi+48]
		addps		xmm1, xmm2
		addps		xmm3, xmm4
		addps		xmm1, xmm3
		haddps		xmm1, xmm1
		haddps		xmm1, xmm1
		movss		xmm7, [ebp-norma]
		addss		xmm7, xmm1
		movss		[ebp-norma], xmm7
		dec		eax				; x-- dove x = numero di parallelizzazioni possibili
		add		esi, ebx
		cmp		eax, 0
		jg		FORI1Q

	FORI1R:	movss		xmm1, [edx+esi]
		movss		xmm7, [ebp-norma]
		addss		xmm7, xmm1
		movss		[ebp-norma], xmm7
		add		esi, 4
		cmp		esi, edi
		jb		FORI1R

		mov		esi, 0
		movss		xmm0, [ebp-norma]
		shufps		xmm0, xmm0, 0	
		mov		ecx, [ebp-result]
		mov		eax, [ebp+n]		
		mov		ebx, [ebp-p]
		xor		edx, edx
		imul		ebx, [ebp-UNROLL]		; p*UNROLL
		div		ebx				; n/(p*UNROLL)
		imul		ebx, 4
		mov		edi, [ebp+n]
		imul		edi, 4
		mov		edx, [ebp+pr]

		
		
	FORIQ:	movups		xmm1, [edx+esi]
		divps		xmm1, xmm0			; pr[i..i+p-1]/norma
		movups		[ecx+esi], xmm1	
		
		movups		xmm2, [edx+esi+16]
		divps		xmm2, xmm0			; pr[i..i+p-1]/norma
		movups		[ecx+esi+16], xmm2	
		
		movups		xmm3, [edx+esi+32]
		divps		xmm3, xmm0			; pr[i..i+p-1]/norma
		movups		[ecx+esi+32], xmm3	
		
		movups		xmm4, [edx+esi+48]
		divps		xmm4, xmm0			; pr[i..i+p-1]/norma
		movups		[ecx+esi+48], xmm4	

		dec		eax				; x-- dove x = numero di parallelizzazioni possibili
		add		esi, ebx
		cmp		eax, 0
		jg		FORIQ

		movss		xmm0, [ebp-norma]
	FORIR:	movss		xmm1, [edx+esi]
		divss		xmm1, xmm0
		movss		[ecx+esi], xmm1
		add		esi, 4
		cmp		esi, edi
		jb		FORIR
		

		mov		eax, [ebp-result]
		
		; in eax c'è il puntatore al vettore risultato e lo restituisco	
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------
		

		pop	edi									; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, ebp								; ripristina lo Stack Pointer
		pop	ebp									; ripristina il Base Pointer
		ret										; torna alla funzione C chiamante
		





