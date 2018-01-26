; ---------------------------------------------------------
; Procedura "calcolaP2" con istruzioni SSE a 32 bit
; Calcoli con numeri a precisione doppia.
; Ottimizzazioni con code-vectorization.
; ---------------------------------------------------------
; M. Di Mauro
; 23/01/2018
;

section .data

uno:		dq		1.0

section .bss

section .text

global calcolaP2d

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
P1		equ		16
n		equ		20


calcolaP2d:

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
		mov		[ebp-4], eax		;salvo il puntatore p2* nello stack
		mov	dword	[ebp-8], 2		; salvo p=2 nello stack
		xor		edx, edx
		mov		eax, ecx
		div	dword	[ebp-8]
		mov		[ebp-12], eax		; salvo u=n/p nello stack

		mov		esi, 0
		movsd		xmm0, [ebp+c]		
		shufpd		xmm0, xmm0, 0		; xmm0 = {c,c}
		movsd		xmm2, [uno]
		shufpd		xmm2, xmm2, 0		; xmm2 = {1,1}
		subpd		xmm2, xmm0		; xmm2 = {1-c,1-c}
		movsd		xmm3, [uno]
		cvtsi2sd	xmm4, ecx
		divsd		xmm3, xmm4
		shufpd		xmm3, xmm3, 0		; xmm3 = {1/n,1/n}
		mulpd		xmm2, xmm3		; xmm2 = {1-c)*(1/n)....}

		movsd		xmm3, [ebp+c]		; xmm3=c
		movsd		xmm4, [uno]
		subsd		xmm4, xmm4		; xmm4=1-c
		movsd		xmm5, [uno]
		cvtsi2sd	xmm6, ecx
		divsd		xmm5, xmm6		; xmm5=1/n
		mulsd		xmm4, xmm6		; xmm4=(1-c)*(1/n)

	FORI:	mov		edi, 0
	FORJQ:	mov		eax, esi
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp+P1]
		movupd		xmm1, [ebx+eax]		; xmm1 = P1(i,j) con j= j..j+p-1
		mulpd		xmm1, xmm0		; xmm1 = P1(i,j)*ck con j=j..j+p-1 k=0..3
		addpd		xmm1, xmm2		; xmm1 = P1(i,j)*c+(1-c)*(1/n)
		mov		ebx, [ebp-4]
		movupd		[ebx+eax], xmm1		; P2(i,j) = xmm1 con j= j..j+p-1
		
		mov		eax, [ebp-8]
		imul		eax, 8
		add		edi, eax		; j+=p
		mov		eax, [ebp-12]		; eax = u
		imul		eax, [ebp-8]		; u*p
		imul		eax, 8
		cmp		edi, eax		; j<u*p?
		jb		FORJQ

	FORJR:	mov		eax, esi		; ciclo resto
		imul		eax, ecx
		add		eax, edi
		mov		ebx, [ebp+P1]
		movsd		xmm1, [ebx+eax]		; xmm1=P1[i*n+j]
		mulsd		xmm1, xmm3		; xmm1=c*P1[i*n+j]
		addsd		xmm1, xmm4		; xmm1=c*P1[i*n+j]+(1-c)*(1/n)
		mov		ebx, [ebp-4]
		movsd		[ebx+eax], xmm1		; p2[i*n+j]=c*P1[i*n+j]+(1-c)*(1/n)
		
		add		edi, 8
		mov		eax, ecx
		imul		eax, 8
		cmp		edi, eax
		jb		FORJR
		
		add		esi, 8
		mov		eax, ecx
		imul		eax, 8
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


		




