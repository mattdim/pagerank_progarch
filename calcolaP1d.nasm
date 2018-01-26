; ---------------------------------------------------------
; Procedura "calcolaP1" con istruzioni SSE a 32 bit
; Calcoli con numeri a precisione doppia.
; ---------------------------------------------------------
; M. Di Mauro
; 23/01/2018
;

section .data

uno:		dq		1.0
zero:		dq		0.0 

section .bss

section .text

global calcolaP1d

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
p		equ		8
UNROLL		equ		12
x		equ		16
;x		equ		24


calcolaP1d:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		ebp							; salva il Base Pointer
		mov		ebp, esp						; il Base Pointer punta al Record di Attivazione corrente
		push		ebx							; salva i registri da preservare
		push		esi
		push		edi

		mov		ecx, [ebp+n]

		;-------------------------------------------------------------
		; richiamo getblock per calcolare il puntatore alla matrice P1,
		; il risultato è contenuto in EAX
		;-------------------------------------------------------------
		imul		ecx, ecx						;n*n
		call		getmem 8,ecx						; la size è di 8 byte perchè si lavora con numeri a 64b
		mov		ecx, [ebp+n]						; ecx = n
		

		sub		esp, 16
		mov		[ebp-4], eax		; salvo p1*
		mov	dword	[ebp-p], 2		; salvo p = 2 perchè si lavora a 64b con sse a 128b
		mov	dword	[ebp-UNROLL], 4		; salvo UNROLL
		;mov	qword	[ebp-d], 0		; salvo di (64b)
		mov	dword	[ebp-x],0		; salvo x = n/(p*UNROLL)
		

		mov		esi, 0
	FORI:	movsd		xmm7, [zero]		; di=0
		mov		edi, 0
		mov		eax, ecx
		mov		ebx, [ebp-UNROLL]
		xor		edx, edx
		div	dword	ebx
		mov		[ebp-x], eax		; x =  n/(UNROLL)
	FORJQ1: mov		eax, esi
		imul		eax, ecx			
		add		eax, edi
		mov		ebx, [ebp+G]
		movsd		xmm0,[ebx+eax] 		; xmm0=g[i*n+j]
		movsd		xmm1,[ebx+eax+8] 	; xmm1=g[i*n+j+1]
		movsd		xmm2,[ebx+eax+16]
		movsd		xmm3,[ebx+eax+24]	; xmm3=g[i*n+j+UNROLL-1]
		movsd		xmm4, [zero]		; xmm4 -> variabile temporanea
		movsd		xmm5, [uno]
		comisd		xmm0, xmm5		; g[i*n+j]=1?
		jne		T1
		addsd		xmm4, xmm5		; di++
	T1:	comisd		xmm1, xmm5		; g[i*n+j+1]=1?
		jne		T2
		addsd		xmm4, xmm5
	T2:	comisd		xmm2, xmm5		; g[i*n+j+2]=1?
		jne		T3
		addsd		xmm4, xmm5
	T3:	comisd		xmm3, xmm5		; g[i*n+j+UNROLL-1]=1?
		jne		CONT
		addsd		xmm4, xmm5
	CONT:	addsd		xmm7, xmm4		; di += temp
		mov		eax, [ebp-UNROLL]
		imul		eax, 8
		add		edi, eax		; j+=UNROLL
		dec	dword	[ebp-x]
		cmp	dword	[ebp-x], 0		; x>0?
		jg		FORJQ1
	
			
	FORJR1: mov 		eax, esi
		imul		eax, ecx
		add		eax, edi						
		movsd		xmm1, [ebx+eax]
		comisd		xmm1, [zero]						; if(g[i][j]==1)
		je		CONT1
		addsd		xmm7, [uno]			; di++
	CONT1:	add		edi, 8
		mov		edx, ecx
		imul		edx, 8							; n*size
		cmp		edi, edx						; j<n?


		mov		edi, 0
		comisd		xmm7, [zero]			; di=0?
		jne		ELSE
		


		movsd		xmm4, [uno]
		cvtsi2sd	xmm5, ecx
	test:	divsd		xmm4, xmm5		; xmm4=1/n
	test1:	shufpd		xmm4, xmm4, 0		; xmm4={1/n,1/n}

	test2:	mov		eax, ecx
		mov		ebx, [ebp-p]
		imul		ebx, [ebp-UNROLL]
		xor		edx, edx
		div	dword	ebx
		mov		[ebp-x], eax		; x =  n/(p*UNROLL)

	FORJ2Q: mov		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp-4]
		movupd		[ebx+eax], xmm4		; {p1[i+n*j..j+p-1]}=xmm4
		movupd		[ebx+eax+16], xmm4
		movupd		[ebx+eax+32], xmm4
		movupd		[ebx+eax+48], xmm4	; {p1[i+n*j+UNROLL-1...j+p*UNROLL-1}=xmm4
		
	test3:	mov		eax, [ebp-UNROLL]
		mov		ebx, [ebp-p]
		imul		eax, ebx
		imul		eax, 8
		add		edi, eax		; j+= p*UNROLL
		mov		eax, [ebp-x]
		dec		eax
		mov		[ebp-x], eax		; x--
		cmp		eax, 0			; x>0?
		jg		FORJ2Q
		

		movsd		xmm0, [uno]
		cvtsi2sd	xmm1, ecx
		divsd		xmm0, xmm1	
	FORJ2R: mov 		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		edx, [ebp-4]
		movsd		[edx+eax], xmm0		; p[i][j] = 1/n
		add		edi, 8
		mov		eax, ecx
		imul		eax, 8			; n*size
		cmp		edi, eax
		jb		FORJ2R
		jmp		CONT2
		
	ELSE:	movsd		xmm0, xmm7
		shufpd		xmm0, xmm0, 0		; xmm0={di,di}

		mov		eax, ecx
		mov		ebx, [ebp-p]
		imul		ebx, [ebp-UNROLL]
		xor		edx, edx
		div	dword	ebx
		mov		[ebp-x], eax		; x =  n/(p*UNROLL)

	FORJ3Q:	mov		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp-4]
		mov		edx, [ebp+G]
		movups		xmm1, [edx+eax]		; xmm1={g[i+n*j..j+p-1]}
		movups		xmm2, [edx+eax+16]
		movups		xmm3, [edx+eax+32]
		movups		xmm4, [edx+eax+48]	; xmm4={g[i+n*j+UNROLL..j+p*UNROLL-1]}
		divpd		xmm1, xmm0
		divpd		xmm2, xmm0
		divpd		xmm3, xmm0
		divpd		xmm4, xmm0	
		movupd		[ebx+eax], xmm1		; {p1[i+n*j..j+p-1]}=xmm1
		movupd		[ebx+eax+16], xmm2
		movupd		[ebx+eax+32], xmm3
		movupd		[ebx+eax+48], xmm4	; {p1[i+n*j+UNROLL-1...j+p*UNROLL-1}=xmm4

		mov		eax, [ebp-UNROLL]
		mov		ebx, [ebp-p]
		imul		eax, ebx
		imul		eax, 8
		add		edi, eax		; j+= p*UNROLL
		mov		eax, [ebp-x]
		dec		eax
		mov		[ebp-x], eax		; x--
		cmp		eax, 0			; x>0?
		jg		FORJ3Q
		

	FORJ3R: mov 		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp-4]
		mov		edx, [ebp+G]
		movsd		xmm1, [edx+eax]
		divsd		xmm1, xmm7
		movsd		[ebx+eax], xmm1		; p[i][j] = g[i][j]/di
		add		edi, 8
		mov		eax, ecx
		imul		eax, 8			; n*size
		cmp		edi, eax
		jb		FORJ3R
	
	CONT2:	add		esi, 8
		mov		edx, ecx
		imul		edx, 8							; n*size
		cmp		esi, edx						; i<n?
		jb		FORI
	
		; in eax c'è il puntatore alla matrice p1 e lo restituisco	
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------
		
		mov	eax, [ebp-4]
		pop	edi									; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, ebp								; ripristina lo Stack Pointer
		pop	ebp									; ripristina il Base Pointer
		ret										; torna alla funzione C chiamante







		
