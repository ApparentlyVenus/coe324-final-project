;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

            ORG RAMStart
; Insert here your data definition.
Data        DS.B  1
Password_v  DC.B  7
Password_t  DC.B  'E','n','t','e','r','P','a','s','s','w','o','r','d'

; code section
            ORG   ROMStart
Entry:
_Startup:
            LDS   #RAMEnd+1       ; initialize the stack pointer
mainLoop:
            MOVB  #$F0, DDRB  ; LED INIT
            MOVB  #$02, PUCR  ; DIP SWITCH INIT
            
            MOVB  #$FE, DDRP  ; IRQ INIT
            MOVB  #$C0, INTCR
            
            MOVB  #$C7, MCCTL ; MCCNT INIT
            MOVW  #62500, MCCNT
            
            MOVB  #$10, MODRR ; LCD INIT
            MOVB  #$38, DDRM
            MOVB  #$52, SPI0CR1
            MOVB  #$10, SPI0CR2
            MOVB  #$00, SPI0BR
             
            LDAA  #%00110011
            JSR   SENDINST
            LDAA  #%00110010
            JSR   SENDINST
            LDAA  #%00101000
            JSR   SENDINST
            LDAA  #%00001000
            JSR   SENDINST
            LDAA  #%00000001
            JSR   SENDINST
            LDAA  #%00000110
            JSR   SENDINST
            LDAA  #%00001110
            
            LDAA  #'E'  ; WRITE FIRST LINE
            JSR   SENDDATA
            LDAA  #'n'
            JSR   SENDDATA
            LDAA  #'n'
            JSR   SENDDATA
            LDAA  #'t'
            JSR   SENDDATA
            LDAA  #'e'
            JSR   SENDDATA
            LDAA  #'r'
            JSR   SENDDATA
            
            LDAA  #%11000000  ; MOVE CURSOR TO SECOND LINE
            JSR   SENDINST 
            
            LDAA  #'P'  ; WRITE SECOND LINE
            JSR   SENDDATA
            LDAA  #'a'
            JSR   SENDDATA
            LDAA  #'s'
            JSR   SENDDATA
            LDAA  #'s'
            JSR   SENDDATA
            LDAA  #'w'
            JSR   SENDDATA
            LDAA  #'o'
            JSR   SENDDATA
            LDAA  #'r'
            JSR   SENDDATA
            LDAA  #'d'
            JSR   SENDDATA
            
                        
PASS_CHECK:  

CYCLE:      MOVB  #$80, MCFLG
            MOVW  #62500, MCCNT
            TST   Counter_1
            LBEQ  DECREMENT2
            DEC   Counter_1
            RTI  
DE2:        TST   Counter_2
            LBEQ  REFRESH
            DEC   Counter_2
            RTI
REFRESH:    MOVB  #20, Counter_1
            MOVB  #40, Counter_2
            RTI
            
TASK1:      TST   Counter_1
            LBEQ  TASK2

TASK2:      TST   Counter_2
            LBEQ  TASK1

TASK4:

SENDSPI:    STAA  SPI0DR
            BRCLR SPI0SR, #$20, *
            MOVB  SPI0DR, Data ; to reset SPI0DR (Data is a variable)
            MOVB  SPI0SR, Data ; to reset SPI0SR
            RTS

SENDINST:   TAB ; transfer initial value of ‘a’ to ‘b’ to save its value
            RORA ; since the LCD operates in 4-bit mode, we must
            ; send the 4 MSB
            RORA ; significant bits first, rotate ‘a’ to the right 4 times
            RORA
            RORA
            ORAA  #%10000000 ; LCD requires a Latch (rising edge? falling edge)
            ; on the EN,
            ANDA  #%10001111 ; to capture the data sent, here ‘EN’ =1
            JSR   SENDSPI
            ANDA  #%00001111 ; then ‘EN’ =0
            JSR   SENDSPI
            JSR   DELAY
            TBA ; transfer the value of ‘a’ stored in ‘b’ to start
            ; working on the LSB
            ORAA  #%10000000 ; same as before, we need to make a Latch
            ; on pin ‘EN’
            ANDA  #%10001111
            JSR   SENDSPI
            ANDA  #%00001111
            JSR   SENDSPI
            JSR   DELAY
            RTS
 
SENDDATA:   TAB ; transfer initial value of ‘a’ to ‘b’ to save its value
            RORA ; since the LCD operates in 4-bit mode, we must
            ; send the 4 MSB
            RORA ; significant bits first, rotate ‘a’ to the right 4 times
            RORA
            RORA
            ORAA  #%11000000 ; LCD requires a Latch (rising edge? falling edge)
            ; on the EN,
            ANDA  #%11001111 ; to capture the data sent, here ‘EN’ =1
            JSR   SENDSPI
            ANDA  #%01001111 ; then ‘EN’ =0
            JSR   SENDSPI
            JSR   DELAY
            TBA ; transfer the value of ‘a’ stored in ‘b’ to start
            ; working on the LSB
            ORAA  #%11000000 ; same as before, we need to make a Latch
            ; on pin ‘EN’
            ANDA  #%11001111
            JSR   SENDSPI
            ANDA  #%01001111
            JSR   SENDSPI
            JSR   DELAY
            RTS
          
DELAY       LDX #4250 ; Load X register with value N to set up a delay loop
AGAIN       PSHB ; Push register B onto the stack
            PULB ; Pull register B from the stack
            PSHB ; Push register B onto the stack
            PULB ; Pull register B from the stack
            PSHB ; Push register B onto the stack
            PULB ; Pull register B from the stack
            DEX ; Decrement X register (count down the delay loop)
            BNE   AGAIN ; If X is not zero, branch back to AGAIN (continue loop)
            RTS ; Return from the subroutine to the main program

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
            
            ORG   $FFF2
            DC.W  TASK4
            
            ORG   $FFCA
            DC.W  CYCLE
