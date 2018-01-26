; ---------------------------------------------------------
; Procedura "calcolaP2" con istruzioni SSE a 32 bit
; Calcoli con numeri a precisione singola.
; Ottimizzazioni con code-vectorization.
; ---------------------------------------------------------
; M. Di Mauro
; 19/01/2018
;

section .data

size:		dd		4.0
uno:		dd		1.0

section .bss

section .text

global calcolaP2s

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

c		equ		8
P1		equ		12
n		equ		16
p2		equ		4
p		equ		8
u		equ		12

calcolaP2s:

		;-----------------------------
		; sequenza di entrata
		;-----------------------------		
		push		ebp
		mov		ebp, esp
		push		ebx
		push		esi
		push		edi
		
		;------------------------------
		; Leggo i parametri in input
		;------------------------------
		
		mov		ecx, [ebp+n]
		imul		ecx, ecx
		getmem		4, ecx
		mov		ecx, [ebp+n]
		sub		esp, 12
		mov		[ebp-p2], eax		;salvo il puntatore p2* nello stack
		mov	dword	[ebp-p], 4		; salvo p=4 nello stack
		xor		edx, edx
		mov		eax, ecx
		div	dword	[ebp-p]
		mov		[ebp-u], eax		; salvo u=n/p nello stack
		
		mov		esi, 0
		movss		xmm0, [ebp+c]		
		shufps		xmm0, xmm0, 0		; xmm0 = {c,c,c,c}
		movss		xmm2, [uno]
		shufps		xmm2, xmm2, 0		; xmm2 = {1,1,1,1}
		subps		xmm2, xmm0		; xmm2 = {1-c,1-c,1-c,1-c}
		movss		xmm3, [uno]
		cvtsi2ss	xmm4, ecx
		divss		xmm3, xmm4
		shufps		xmm3, xmm3, 0		; xmm3 = {1/n,1/n,1/n,1/n}
		mulps		xmm2, xmm3		; xmm2 = {(1-c)*(1/n)....}
		
		movss		xmm3, [ebp+c]		; xmm3=c
		movss		xmm4, [uno]
		subss		xmm4, xmm3		; xmm4=1-c
		movss		xmm5, [uno]
		cvtsi2ss	xmm6, ecx
		divss		xmm5, xmm6		; xmm5=1/n
		mulss		xmm4, xmm5		; xmm4=(1-c)*(1/n)



	FORI:	mov		edi, 0
	FORJQ:	mov		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp+P1]
		movups		xmm1, [ebx+eax]		; xmm1 = P1(i,j) con j= j..j+p-1
		mulps		xmm1, xmm0		; xmm1 = P1(i,j)*ck con j=j..j+p-1 k=0..3
		addps		xmm1, xmm2		; xmm1 = P1(i,j)*c+(1-c)*(1/n)
		mov		ebx, [ebp-p2]
		movups		[ebx+eax], xmm1		; P2(i,j) = xmm1 con j= j..j+p-1

		mov		eax, [ebp-8]
		imul		eax, 4
		add		edi, eax		; j+=p
		mov		eax, [ebp-12]		; eax = u
		imul		eax, [ebp-8]		; u*p
		imul		eax, 4
		cmp		edi, eax		; j<u*p?
		jb		FORJQ

	FORJR:	mov		eax, esi		; ciclo resto
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp+P1]
		movss		xmm1, [ebx+eax]		; xmm1=P1[i*n+j]
		mulss		xmm1, xmm3		; xmm1=c*P1[i*n+j]
		addss		xmm1, xmm4		; xmm1=c*P1[i*n+j]+(1-c)*(1/n)
		mov		ebx, [ebp-4]
		movss		[ebx+eax], xmm1		; p2[i*n+j]=c*P1[i*n+j]+(1-c)*(1/n)
		
		add		edi, 4
		mov		eax, ecx
		imul		eax, 4
		cmp		edi, eax
		jb		FORJR
		
		add		esi, 4
		mov		eax, ecx
		imul		eax, 4
		cmp		esi, eax
		jb		FORI

		;-----------------------------
		; Sequenza di uscita
		;-----------------------------	
		mov		eax, [ebp-4]
		pop		edi
		pop		esi
		pop		ebx
		mov		esp, ebp
		pop		ebp
		ret		
		




		