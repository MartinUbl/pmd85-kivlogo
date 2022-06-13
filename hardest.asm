	cpu     8080		; programujeme pro procesor i8080 (PMD 85 procesor je s nim plne kompatibilni)
	relaxed on			; relaxovany rezim - abychom mohli pouzit vsechny konstrukce

BEEP equ 88A6H			; rutina pro pipani
sirka equ 48			; sirka sprite
vyska equ 36			; vyska sprite
citaddr equ 2100H		; adresa citace radek
imgaddr equ 2104H		; adresa ulozeneho kurzoru v obrazku
lineaddr equ 2108H		; adresa citace radek pro vykresleni matice spritu
perline equ 6			; pocet spritu na radek
linecount equ 6			; pocet radek spritu v matici
logoline EQU 0D600H		; radka kam se vykresluje logo KIVu
logopos EQU 0D612H		; pozice v pameti, kam se vykresluje logo KIVu
textpos EQU 0DF0EH		; pozice kam se zacne vykreslovat text
linecnt EQU 01400H		; pocet bodu k vymazani

	org     2000H
               
	nop					; par NOPu pro dobry pocit a offset v programu, abychom preskocili loader kod
	nop
	nop
	nop
	nop
	nop
	nop

	lxi h,0C000H		; zacatek videopameti
	shld imgaddr		; ulozeni kurzoru
	mvi a,linecount		; do akumulatoru ulozime pocet radek k vykresleni
	lxi h,lineaddr		; nacteme adresu citace radek
	stax h				; ulozime do pameti
	
	mvi b,perline		; v "b" je citac obrazku v radku (snizujici se)

hardest
	lhld imgaddr		; nacteme kurzor
	lxi d,logo			; nacteme adresu obrazku
	push b				; ulozime "b" na zasobnik, "vykresli" bude tento registr menit 
	call vykresli		; vykreslime obrazek matice
	
	lxi h,zvuktab		; nacteme tabulku zvuku
	call BEEP			; zavolame pipaci rutinu monitoru
	
	lhld imgaddr		; nacteme adresu kurzoru
	mvi b,0				; nulovani horni casti registroveho paru
	mvi c,sirka/6		; dolni cast obsahuje offset radku - dalsi obrazek se bude vykreslovat o tolik dal
	dad b				; pricteme do HL registry BC (16-bit scitani)
	shld imgaddr		; ulozime novy kurzor
	pop b				; obnovime registr "b" (citac obrazku na radek)
	dcr b				; dekrementujeme
	jnz hardest			; pokud jsme jeste nedosahli konce radku, opakujeme
	
	mvi d,vyska			; do "d" ulozime vysku obrazku
	mvi c,64+2*sirka/6	; do "c" ulozime zbytek, ktery je potreba k odrolovani
	mvi b,0				; do "b" ulozime 0 (horni cast paru BC)
	dad b				; pricteme do HL obsah BC
decloop
	mvi c,64			; do "c" ulozime 64 - pocet bajtu na jednu radku displeje
	mvi b,0				; "b" vynulujeme (registrovy par BC)
	dad b				; pricteme do HL obsah BC
	dcr d				; dekrementujeme "d" (vyska obrazku)
	jnz decloop			; pokud jsme odrolovali cely obrazek, koncime, jinak rolujeme dal
	shld imgaddr		; ulozime novy kurzor
	
	lxi h,lineaddr		; do HL nacteme adresu citace radek
	ldax h				; nacteme citac radek do akumulatoru
	dcr a				; dekrementujeme akumulator (citac radek)
	jz printlogo		; pokud jsme dosahli konce obrazku, koncime vykreslovani
	stax h				; ulozime citac radek do pameti

	mvi b,perline		; resetujeme citac obrazku v radku
	jmp hardest			; opakujeme vykreslovani na nove radce

printlogo
	lxi h,logoline		; do HL nacteme zacatek obrazove pameti k vycisteni
	lxi b,linecnt		; do "b" nacteme pocet bajtu k vynulovani
	mvi a,0				; vynulujeme akumulator
clearloop
	mvi m,00H			; vynulujeme videopamet na adrese HL (vycistime bod)
	inx h				; inkrementujeme kurzor videopameti
	dcx b				; dekrementujeme citac bajtu k vynulovani
	cmp b				; nasledujici instrukce overuji, zda jsme cely 16bit citac vynulovali; pokud ne, opakujeme cisteni
	jnz clearloop
	cmp c
	jnz clearloop

	lxi h,logopos		; nacteme adresu videopameti pozice loga
	lxi d,kiv			; nacteme adresu obrazku KIVu
	call vykresli		; vykreslime
	lxi h,logopos+sirka/6	; posuneme kurzor na dalsi kus videopameti za logem
	lxi d,kiv2			; nacteme adresu druhe casti loga
	call vykresli		; vykreslime
	
	lxi h,textpos		; nacteme adresu videopameti kam budeme davat text
	lxi d,kivtext1		; nacteme adresu prvni casti textu
	call vykresli		; vykreslime
	lxi h,textpos+sirka/6	; posuneme kurzor dal
	lxi d,kivtext2		; nacteme adresu druhe casti textu
	call vykresli		; vykreslime
	lxi h,textpos+2*sirka/6	; posuneme kurzor dal
	lxi d,kivtext3		; nacteme adresu treti casti textu
	call vykresli		; vykreslime
	
loop jmp loop			; nekonecna smycka - koncime program

; vykreslovaci rutina
; Vstup: HL - adresa do videopameti, kam zacit vykreslovat
;		 DE - adresa obrazku
; Meni: vsechny registry
vykresli
	mvi a,vyska		; do akumulatoru nacteme vysku obrazku
	lxi b,citaddr	; nacteme adresu citace radku
	stax b			; ulozime do pameti
	mvi b,sirka/6	; do "b" ulozime pocet bajtu na radku; (6 bodu v jednom bajtu)
opakuj
	ldax d			; nacteme do akumulatoru bod spritu z pameti
	mov m,a			; presuneme ho do HL (adresa nekde ve videopameti)
	inx h			; inkrementujeme HL (dalsi bod videopameti)
	inx d			; inkrementujeme DE (dalsi bod obrazku)
	dcr b			; dekrementujeme "b" (pocet bajtu na radek)
	jnz opakuj		; opakujeme, pokud jsme nedosli na konec radku
	
	mvi c,64 - sirka/6	; nacteme do "c" zbytek do konce obrazovky
	mvi b,0			; do "b" nacteme 0 (registrovy par)
	dad b			; HL zvysime o hodnotu BC (posuneme se ve videopameti na dalsi radek)
	
	lxi b,citaddr	; do BC nacteme adresu citace radek
	ldax b			; nacteme do akumulatoru citac radek
	dcr a			; dekrementujeme
	rz				; pokud jsme dosli na nulu, vracime se - mame vykresleni
	stax b			; jinak ulozime citac radek
	
	mvi b,sirka/6	; resetujeme citac bodu na radek
	jmp opakuj		; a opakujeme
	
; dummy obrazek pro zarovnani a test
dummy
	db 0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,14,0,0,0,0,0,0,0,30,0,0,0,0,0,0,0,62,0,0,0,0,0
	db 0,0,62,3,0,0,0,0,0,0,62,7,0,0,0,0,0,0,62,15,0,0,0,0,0,0,62,63,0,0,0,0,0,0,62,63,1,0,0,0
	db 0,0,30,60,1,0,0,0,0,0,30,60,9,0,0,0,0,0,30,60,25,0,0,0,0,0,30,60,57,0,0,0,0,0,30,60,57,1,0,0
	db 0,0,30,60,57,0,0,0,0,0,30,60,25,0,0,0,0,0,30,60,9,0,0,0,0,0,30,60,1,0,0,0,0,0,30,56,0,0,0,0
	db 0,0,30,0,0,0,0,0,0,0,62,0,0,0,0,0,0,0,62,3,0,0,0,0,0,0,62,1,0,0,0,0,0,0,62,0,0,0,0,0
	db 0,0,30,0,0,0,0,0,0,0,14,0,0,0,0,0,5,1,2,0,0,0,0,0,5,1,0,0,0,0,0,0,4,1,0,0,0,0,0,0
	db 40,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,17,0,0,0,0,0,0,0
	db 17,0,0,0,0,0,0,0

; hardest button to button
logo
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,62,0,0,0,0,0,0,0,39,1,0,0,0
	db 0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,35,1,0,0,0,0,0,0,62,0,0,0,0,0,0,0,8,0,0,0,0
	db 0,0,0,8,0,0,0,0,0,24,0,8,0,0,0,0,0,48,1,30,0,0,0,0,63,1,50,27,0,0,0,0,8,0,30,56,0,0,0,0
	db 63,1,0,40,0,60,7,0,8,0,0,40,0,51,24,0,8,0,0,40,49,4,35,0,8,60,15,8,9,9,5,1,8,3,48,8,4,9,13,2
	db 40,1,32,9,2,10,21,6,8,3,48,8,2,10,21,4,8,63,63,8,1,54,34,4,8,63,63,63,57,61,33,4,8,63,63,20,5,30,32,4
	db 8,63,63,20,51,63,32,4,8,63,63,50,9,51,35,4,8,63,63,34,6,19,30,4,40,63,63,39,34,34,17,6,40,63,63,37,36,2,14,2
	db 60,63,63,37,40,2,4,1,60,63,63,1,48,5,35,1,52,62,31,1,16,55,24,1,48,1,32,3,16,60,7,1,16,1,32,2,40,0,32,2
	db 0,0,0,0,0,0,0,0

; logo KIV - cast 1
kiv
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,52,3,62,60,51,3,30
	db 0,38,1,28,48,32,1,12,0,35,1,14,48,32,1,12,32,33,1,7,48,32,1,12,48,32,33,3,48,32,1,12,24,32,49,1,48,0,3,6
	db 12,32,57,0,48,0,3,6,6,32,29,0,48,0,3,6,3,32,15,0,48,0,3,6,3,32,15,0,48,0,6,3,6,32,29,0,48,0,6,3
	db 12,32,57,0,48,0,6,3,24,32,49,1,48,0,6,3,48,32,33,3,48,0,44,1,32,33,1,7,48,0,44,1,0,35,1,14,48,0,44,1
	db 0,38,1,28,48,0,56,0,0,52,3,62,60,3,56,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	
; logo KIV - cast 2
kiv2
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0
	db 3,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,12,0,0,0,0,0,0,0,24,0,0,0,0,0,0,0,48,0,0,0,0,0,0,0
	db 32,1,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,3,0,0,0,0,0,0
	db 32,1,0,0,0,0,0,0,48,0,0,0,0,0,0,0,24,0,0,0,0,0,0,0,12,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0
	db 3,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0
	
; text - cast 1
kivtext1
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,36,8,31,47,35,3,1,0,36,8,4,33,36,4,1,0
	db 20,20,4,33,40,36,2,0,20,20,4,33,40,36,2,0,12,20,4,39,40,35,2,0,20,34,4,33,40,17,4,0,20,62,4,33,40,50,7,0
	db 36,34,4,33,36,20,4,0,36,34,4,47,35,20,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 36,40,39,51,9,34,60,37,36,41,16,20,26,35,16,36,36,41,16,20,26,19,17,36,36,42,16,20,42,18,17,36,36,42,19,52,41,18,17,36
	db 36,42,16,52,8,10,18,36,36,44,16,20,9,58,19,36,36,44,16,20,10,10,18,36,36,40,32,19,10,10,18,36,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,9,0,0,0,0,16,0,0,6,0,16,0,34,42,14,14,32,55,16,0,34,34,18,17,38,0,40,0,34,34,18,17,41,0
	db 40,0,34,20,18,17,33,0,40,0,20,8,14,17,33,3,4,1,20,8,2,17,33,0,60,1,20,8,2,17,33,0,4,1,8,8,2,17,41,0
	db 4,1,8,8,2,14,38,7

; text - cast 2
kivtext2
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 20,4,0,0,0,0,0,0,20,4,0,0,0,0,0,0,18,4,0,0,0,0,0,0,34,2,0,0,0,0,0,0,1,1,0,0,0,0,0,0
	db 2,1,0,0,0,0,0,0,2,1,0,0,0,0,0,0,4,1,0,0,0,0,0,0,4,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,1,0,0,0,0,0,0,32,0,0,0,0,0,0,23,4,48,55,51,36,34,10,49,36,0,17,8,37,38,10,49,36,0,17,8,36,38,42
	db 17,37,0,17,8,36,42,42,17,37,0,49,9,60,42,26,17,37,0,17,8,36,42,42,17,38,0,17,8,36,50,42,17,38,0,17,8,37,50,10
	db 17,36,0,49,51,36,34,10

; text - cast 3
kivtext3
	db 0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,14,0,0,0,0,0,0,0,30,0,0,0,0,0,0,0,62,0,0,0,0,0
	db 0,0,62,3,0,0,0,0,0,0,62,7,0,0,0,0,0,0,62,15,0,0,0,0,0,0,62,63,0,0,0,0,0,0,62,63,1,0,0,0
	db 0,0,30,60,1,0,0,0,0,0,30,60,9,0,0,0,0,0,30,60,25,0,0,0,0,0,30,60,57,0,0,0,0,0,30,60,57,1,0,0
	db 0,0,30,60,57,0,0,0,0,0,30,60,25,0,0,0,0,0,30,60,9,0,0,0,0,0,30,60,1,0,0,0,0,0,30,56,0,0,0,0
	db 0,0,30,0,0,0,0,0,0,0,62,0,0,0,0,0,0,0,62,3,0,0,0,0,0,0,62,1,0,0,0,0,0,0,62,0,0,0,0,0
	db 0,0,30,0,0,0,0,0,0,0,14,0,0,0,0,0,5,1,2,0,0,0,0,0,5,1,0,0,0,0,0,0,4,1,0,0,0,0,0,0
	db 40,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,17,0,0,0,0,0,0,0
	db 17,0,0,0,0,0,0,0
	
; zvukova tabulka pro rutinu BEEP
zvuktab
	db 1,5,0,5,1,5,0,5,1,5,0,5,1,5,0,5,1,5,0,5,1,5,0,5,1,5,0,5,1,5,0,5,1,5,0,5
	db 0,107
	db 255
