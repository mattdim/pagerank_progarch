; ---------------------------------------------------------
; Procedura "calcolaP1" con istruzioni SSE a 32 bit
; Calcoli con numeri a precisione singola.
; ---------------------------------------------------------
; M. Di Mauro
; 20/01/2018
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
p		equ		8
UNROLL		equ		12
d		equ		16
x		equ		20

calcolaP1s:
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
		call		getmem 4,ecx
		mov		ecx, [ebp+n]						; ecx = n
		
		sub		esp, 20
		mov		[ebp-4], eax		; salvo p1*
		mov	dword	[ebp-p], 4		; salvo p
		mov	dword	[ebp-UNROLL], 4		; salvo UNROLL
		mov	dword	[ebp-d], 0		; salvo di
		mov	dword	[ebp-x],0		; salvo x = n/(p*UNROLL)

		mov		esi, 0
	FORI:	mov	dword	[ebp-d], 0		; di=0
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
		movss		xmm0,[ebx+eax] 		; xmm0=g[i*n+j]
		movss		xmm1,[ebx+eax+4] 	; xmm1=g[i*n+j+1]
		movss		xmm2,[ebx+eax+8]
		movss		xmm3,[ebx+eax+12]	; xmm2=g[i*n+j+UNROLL-1]
		mov		edx, 0
		comiss		xmm0, [uno]		; g[i*n+j]=1?
		jne		T1
	test:	inc		edx			; di++
	T1:	comiss		xmm1, [uno]		; g[i*n+j+1]=1?
		jne		T2
		inc		edx
	T2:	comiss		xmm2, [uno]		; g[i*n+j+2]=1?
		jne		T3
		inc		edx	
	T3:	comiss		xmm3, [uno]		; g[i*n+j+UNROLL-1]=1?
		jne		CONT
		inc		edx
	CONT:	add		[ebp-d], edx
		mov		eax, [ebp-UNROLL]
		imul		eax, 4
		add		edi, eax		; j+=UNROLL
		dec	dword	[ebp-x]
		cmp	dword	[ebp-x], 0		; x>0?
		jg		FORJQ1
	
			
	FORJR1: mov 		eax, esi
		imul		eax, ecx
		add		eax, edi						
		mov		edx, [ebx+eax]
		cmp		edx, 0							; if(g[i][j]==1)
		je		CONT1
		mov		eax, [ebp-d]
		inc		eax
		mov		[ebp-d], eax						; di++
	CONT1:	add		edi, 4
		mov		edx, ecx
		imul		edx, 4							; n*size
		cmp		edi, edx						; j<n?
		jb		FORJR1
		
		mov		eax, [ebp-d]
		mov		edi, 0
		cmp		eax, 0			; di=0?
		jne		ELSE
		
		movss		xmm4, [uno]
		cvtsi2ss	xmm5, ecx
		divss		xmm4, xmm5		; xmm4=1/n
		shufps		xmm4, xmm4, 0		; xmm4={1/n,..,1/n}

		mov		eax, ecx
		mov		ebx, [ebp-p]
		imul		ebx, [ebp-UNROLL]
		xor		edx, edx
		div	dword	ebx
		mov		[ebp-x], eax		; x =  n/(p*UNROLL)


	FORJ2Q: mov		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp-4]
		movups		[ebx+eax], xmm4		; {p1[i+n*j..j+p-1]}=xmm4
		movups		[ebx+eax+16], xmm4
		movups		[ebx+eax+32], xmm4
		movups		[ebx+eax+48], xmm4	; {p1[i+n*j+UNROLL-1...j+p*UNROLL-1}=xmm4
		
	test1:	mov		eax, [ebp-UNROLL]
		mov		ebx, [ebp-p]
		imul		eax, ebx
		imul		eax, 4
		add		edi, eax		; j+= p*UNROLL
		mov		eax, [ebp-x]
		dec		eax
		mov		[ebp-x], eax		; x--
		cmp		eax, 0			; x>0?
		jg		FORJ2Q
		
		movss		xmm0, [uno]
		cvtsi2ss	xmm1, ecx
		divss		xmm0, xmm1	
	FORJ2R: mov 		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		edx, [ebp-4]
		movss		[edx+eax], xmm0		; p[i][j] = 1/n
		add		edi, 4
		mov		eax, ecx
		imul		eax, 4			; n*size
		cmp		edi, eax
		jb		FORJ2R
		jmp		CONT2
		
	ELSE:	cvtsi2ss	xmm0, [ebp-d]
		shufps		xmm0, xmm0, 0		; xmm0={di,..,di}

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
		divps		xmm1, xmm0
		divps		xmm2, xmm0
		divps		xmm3, xmm0
		divps		xmm4, xmm0	
		movups		[ebx+eax], xmm1		; {p1[i+n*j..j+p-1]}=xmm1
		movups		[ebx+eax+16], xmm2
		movups		[ebx+eax+32], xmm3
		movups		[ebx+eax+48], xmm4	; {p1[i+n*j+UNROLL-1...j+p*UNROLL-1}=xmm4
		
	test2:	mov		eax, [ebp-UNROLL]
		mov		ebx, [ebp-p]
		imul		eax, ebx
		imul		eax, 4
		add		edi, eax		; j+= p*UNROLL
		mov		eax, [ebp-x]
		dec		eax
		mov		[ebp-x], eax		; x--
		cmp		eax, 0			; x>0?
		jg		FORJ3Q

		cvtsi2ss	xmm5, [ebp-d]	
	FORJ3R: mov 		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp-4]
		mov		edx, [ebp+G]
		movss		xmm1, [edx+eax]
		divss		xmm1, xmm5
		movss		[ebx+eax], xmm1		; p[i][j] = g[i][j]/di
	test3:	add		edi, 4
		mov		eax, ecx
		imul		eax, 4			; n*size
		cmp		edi, eax
		jb		FORJ3R
	
	CONT2:	add		esi, 4
		mov		edx, ecx
		imul		edx, 4							; n*size
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


		
























	