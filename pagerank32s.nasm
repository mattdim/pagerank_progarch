section .data

epsilon1:		dd		0.1
zero:			dd		0.0
uno:			dd		1.0

section .bss

deltap			resd		1

section .text

global pagerank32s

extern get_block
extern free_block
extern calcolaRis
extern calcolaDeltaS

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

%macro	compRis	2
	mov	eax, %1
	push	eax
	mov	eax, %2
	push	eax
	push	eax
	call	calcolaRis
	add	esp, 8
%endmacro

%macro	calcolaDelta	4
	mov	eax, %1
	push	eax
	mov	eax, %2
	push	eax
	mov	eax, %3
	push	eax
	mov	eax, %4
	push	eax
	call	calcolaDeltaS
	add	esp, 16
%endmacro
	


epsilon		equ		8
n 		equ		12
matrix		equ		16

pr		equ 		4
temp		equ		8
UNROLL		equ		12
p		equ		16
result		equ		20
x		equ		24


pagerank32s:
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
		
		sub		esp, 24
		getmem		4, [ebp+n]
		mov		[ebp-pr], eax
		getmem		4, [ebp+n]
		mov		[ebp-temp], eax
		getmem		4, [ebp+n]
		mov		[ebp-result], eax
			
		mov		eax, [epsilon1]		
		mov	dword	[ebp-p], 4
		mov	dword	[ebp-UNROLL], 4
		
		

		;-------------------------------------------------------------
		; richiamo getblock per calcolare il puntatore al vettore d,
		; il risultato è contenuto in EAX
		;-------------------------------------------------------------




		movss		xmm0, [uno]
		cvtsi2ss	xmm1, [ebp+n]
		divss		xmm0, xmm1
		shufps		xmm0, xmm0, 0		; xmm0 = {1/n,..,1/n}
		mov		eax, [ebp+n]
		mov		ebx, [ebp-p]
		imul		ebx, [ebp-UNROLL]	; p*UNROLL
		xor		edx, edx
		div		ebx
		mov		ecx, eax		; ecx = (n/p*UNROLL)
		;imul		ecx, ebx		; ecx = p*UNROLL*(n/p*UNROLL)

		mov		esi, 0
	FORI1Q:	mov		eax, [ebp-pr]
		movups		[eax+esi], xmm0 	; pr[i..i+p-1] = 1/n
		movups		[eax+esi+16], xmm0
		movups		[eax+esi+32], xmm0
		movups		[eax+esi+48], xmm0	; pr[i+UNROLL-1...i+p*UNROLL-1]
		mov		edx, ebx
		imul		edx, 4			; p*UNROLL
		add		esi, edx
		imul		edx, ecx
		cmp		esi, edx
		jb		FORI1Q

		movss		xmm0, [uno]
		cvtsi2ss	xmm1, [ebp+n]
		divss		xmm0, xmm1
	FORI1R:	mov		eax, [ebp-pr]
		movss		[eax+esi], xmm0
		add		esi, 4
		mov		ecx, [ebp+n]
		imul		ecx, 4
		cmp		esi, ecx
		jb		FORI1R	
		

	WHILE:	getmem		4, [ebp+n]
		mov		[ebp-temp], eax		; inizializzo temp ad ogni ciclo
		mov		edi, 0	

	FORJ:	mov		esi, 0
		movss		xmm7, [zero]
		mov		eax, [ebp+n]
		;mov		ebx, [ebp-p]		
		mov		ebx, [ebp-UNROLL]
		xor		edx, edx
		div		ebx			; eax = x = n/(UNROLL)
		mov		[ebp-x], eax

		
	FORI2Q:	mov		ebx, [ebp-pr]		; pr*
		movups		xmm0, [ebx+esi]		; xmm0=pr[i..i+p-1]
		mov		ecx, [ebp+matrix]	; matrix*		
		mov		edx, [ebp+n]
		imul		edx, esi
		add		edx, edi		; i*n+j
		
		movss		xmm1, [ecx+edx]		; xmm1=matrix[i*n+j]
		mulss		xmm0, xmm1
		addss		xmm7, xmm0
		
		add		esi, 4
		mov 		ecx, [ebp+n]
		imul		ecx, 4
		cmp		esi, ecx
		jb		FORI2Q

		mov		edx, [ebp-temp]
		movss		[edx+edi], xmm7		
		
		add		edi, 4
		mov		eax, [ebp+n]
		imul		eax, 4
		cmp		edi, eax
		jb		FORJ
			
		calcolaDelta	[ebp-temp], [ebp-pr], [ebp+n], deltap
		mov		eax, [ebp-temp]
		mov		[ebp-pr], eax
		movss		xmm0, [deltap]
		movss		xmm1, [ebp+epsilon]
		comiss		xmm0, xmm1
		ja		WHILE

		mov		ecx, [ebp+n]		
	break:	compRis		[ebp-pr], ecx
		
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

		
		
		






						