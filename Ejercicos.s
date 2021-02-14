;Archivo:	main.s
;dispositivo:	PIC16F887
;Autor:		Selvin Peralta 
;Compilador:	pic-as (v2.31), MPLABX V5.45
;
;Programa:	Sumador de 4 bits
;Hardware:
;
;Creado:	       09 feb, 2021
;Ultima modificacion:  13 feb, 2021

    
PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=XT		    //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON
 CONFIG MCLRE=OFF
 CONFIG CP=OFF
 CONFIG CPD=OFF
 
 CONFIG BOREN=OFF
 CONFIG IESO=OFF
 CONFIG FCMEN=OFF
 CONFIG LVP=ON
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 

;------------------------------
  PSECT udata_bank0 ;common memory
    cont:	DS  2 ;1 byte apartado
    ;cont_big:	DS  1;1 byte apartado
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
  
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código

;---------------configuración main------------------------------
  main: 
    bsf	    STATUS, 5   ;Banco  11
    bsf	    STATUS, 6
    clrf    ANSEL	;Cambio a Pines Digitales 
    clrf    ANSELH
    
    bsf	    STATUS, 5	;Banco 01
    bcf	    STATUS, 6
    movlw   0xF0	;Movemos la literal en hexadeciman a F
    movwf   TRISA	;Seleccionamos que los bits menos significativos del puerto A son salidas 
    movlw   0xF0
    movwf   TRISB	;Seleccionamos que los bits menos significativos del puerto B son salidas 
    movlw   01100000B
    movwf   TRISC       ;Seleccionamos que los bits menos significativos del puerto C son salidas 

    bcf	    STATUS, 5	;Banco 00
    bcf	    STATUS, 6
    movlw   0x00
    movwf   PORTA	;Valor incial 0 en puerto A
    movlw   0x00
    movwf   PORTB	;Valor incial 0 en puerto B
    movlw   0x00
    movwf   PORTC	;Valor incial 0 en puerto C
    
    
    banksel PORTA  
;-------------Loop principal---------------------
 loop: 
    btfsc   PORTA, 4	;Cuando no este presionado salta una fila 
    call    add_porta
    btfsc   PORTA, 5	;Revisar si no esta presionado sino sigue saltando 
    call    rest_porta
    
    btfsc   PORTB, 4	;Revisar cuando no este presionado sino sigue saltando 
    call    add_portb
    btfsc   PORTB, 5	;Revisar si no esta presionado Sino sigue saltando 
    call    rest_portb
    
    btfsc   PORTC, 5
    call    anti_suma
    
    btfsc   STATUS, 1	;Carry 
    bsf	    PORTC, 4
    
    btfss   STATUS, 1	;Carry 
    bcf	    PORTC, 4
    
    goto    loop    ;loop forever 
;------------sub rutinas----------------------------------
 add_porta:
    call    delay	;Antirebote con delay y el bit test file
    btfsc   PORTA, 4	;Revisa de nuevo si no esta presionado
    goto    $-1		;Ejecuta una linea atrás	        
    incf    PORTA	;Suma  1 al puerto
    return
 rest_porta:
    call    delay
    btfsc   PORTA, 5	;Revisa de nuevo si no esta presionado
    goto    $-1		;Ejecuta una linea atrás	        
    decf    PORTA	;Resta 1 al puerto 
    return
 add_portb:
    call    delay
    btfsc   PORTB, 4	;Revisa de nuevo si no esta presionado
    goto    $-1		;Ejecuta una linea atrás	        
    incf    PORTB       ;Suma 1 al puerto
    return
 rest_portb: 
    call    delay
    btfsc   PORTB, 5	;Revisa de nuevo si no esta presionado
    goto    $-1		;Ejecuta una linea atrás	        
    decf    PORTB	;Resta 1 al puerto
    return
;--------------------SUMA-------------------------------
anti_suma:
    call    delay       ;Para eliminar cualquier ruido 
    btfsc   PORTC, 5
    goto    anti_suma   ;Es utilizado como anti rebote para el Push Bottom del resultado 
    call    sumar
    return
    
sumar:
    movf    PORTA, w    ;
    addwf   PORTB, w
    movwf   PORTC
    return 
;------------------delays------------------------   
 delay:
    movlw	150		;valor incial
    movwf	cont
    decfsz	cont, 1	;decrementar
    goto	$-1		;ejecutar línea anterior
    return
    
end