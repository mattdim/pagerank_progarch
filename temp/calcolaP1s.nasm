; ---------------------------------------------------------
; Procedura "calcolaP1" con istruzioni SSE a 32 bit
; Calcoli con numeri a precisione singola.
; ---------------------------------------------------------
; M. Di Mauro
; 12/01/2018
;


section .data

size:		dd		4.0
uno:		dd		1.0 

section .bss

section .text

global calcolaP1s

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

G		equ		8
n		equ		12

calcolaP1s:
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
		mov		ebx, [ebp+G]
		mov		ecx, [ebp+n]

		;-------------------------------------------------------------
		; richiamo getblock per calcolare il puntatore alla matrice P1,
		; il risultato è contenuto in EAX
		;-------------------------------------------------------------
		imul		ecx, ecx						;n*n
		call		getmem 4,ecx
		mov		ecx, [ebp+n]						; ecx = n
		
		sub		esp, 8							; riservo 8 bytes per 2 variabili a 32b
		mov		[ebp-8], eax						; salvo il puntatore a P
		mov	dword	[ebp-4], 0						; di


		mov		eax, 1
		movd		xmm0, eax
		movd		xmm1, ecx
		divss		xmm0, xmm1						; xmm0 = 1/n
		mov 		esi, 0							; i=0
	FORI:	mov 		edi, 0							; j=0
		mov	dword	[ebp-4], 0						; di=0
	FORJ:	mov 		eax, esi
		imul		eax, ecx
		add		eax, edi						
		mov		edx, [ebx+eax]
		cmp		edx, 0							; if(g[i][j]==1)
		je		CONT
		mov		eax, [ebp-4]
		inc		eax
		mov		[ebp-4], eax						; di++
	CONT:	add		edi, 4
		mov		edx, ecx
		imul		edx, 4							; n*size
		cmp		edi, edx						; j<n?
		jb		FORJ
		mov		eax, [ebp-4]
		cmp		eax, 0							; if(di==0)
		jne		ELSE
		mov		edi, 0
	FORJ2:	mov 		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		edx, [ebp-8]
		movss		[edx+eax], xmm0						; p[i][j] = 1/n
		add		edi, 4
		mov		eax, ecx
		imul		eax, 4							; n*size
		cmp		edi, eax
		jb		FORJ2
		jmp		CONT2
	ELSE:	mov		edi, 0
	FORJ3:	mov 		eax, esi
		imul		eax, ecx
		add		eax, edi
		cvtsi2ss	xmm1, [ebp-4]
		movss		xmm2, [ebx+eax]
		divss		xmm2, xmm1						; g[i][j]/di
		mov		edx, [ebp-8]
		movss		[edx+eax], xmm2						; p[i][j] = g[i][j]/di
		add		edi, 4
		mov		eax, ecx
		imul		eax, 4							; n*size
		cmp		edi, eax
		jb		FORJ3
	CONT2:	add		esi, 4
		mov		edx, ecx
		imul		edx, 4							; n*size
		cmp		esi, edx						; i<n?
		jb		FORI

		; in eax c'è il puntatore alla matrice p1 e lo restituisco	
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------
		
		mov 		eax, [ebp-8]						; restituisco *p

		pop	edi									; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, ebp								; ripristina lo Stack Pointer
		pop	ebp									; ripristina il Base Pointer
		ret										; torna alla funzione C chiamante
