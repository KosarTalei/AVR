.INCLUDE "M32DEF.INC"
.ORG 0x0 
	JMP Main						;location for reset
.ORG 0x02
	JMP INT0_Handler				;location for Interrup0: start, timer
.ORG 0x04 
	JMP INT1_Handler				;location for Interrup1: full
.ORG 0x06
	JMP INT2_Handler				;location for Interrup2: empty
.ORG 0X100
Main :
	LDI R16 , HIGH(RAMEND)			;stack initialize
	OUT SPH , R16
	LDI R16 , LOW(RAMEND)
	OUT SPH , R16

	LDI R16 , 0x00					;make PINA as input ->T(FULL)
	OUT DDRA , R16
	LDI R16 , 0x00					;make PINC as input ->B(EMPTY)
	OUT DDRC , R16
	LDI R16 , 0xFF					;make PORTB as output ->P(RUN)
	OUT DDRB , R16
	LDI R16 , 0xFF					;make PORTD as output ->L(BLINK)
	OUT DDRD , R16

	LDI R24 , 0					    ; counter for total time: timer 999
	LDI R25 , 0                     ; counter for blinker (values up to 2) f=0.5 hz -> each 2s blink
	LDI R26 , 0                     ; counter for delay -> each 10s -> 1s idle
	LDI R27 , 0                     ; system idle state  ( 0 -> system is running , 1 -> system is idle)	
				
	;load timer with 999 (F = 1 KHZ)
	LDI R20,0XE7				; load low 8bits of 999
	LDI R21,3					; high 8 bits
	OUT OCR1AH , R21				
	OUT OCR1AL , R20	
	LDI R20,0x09
	OUT TCCR0,R20				;	start timer, CTC mode, no prescaler

	SBI PORTB , 1					;pull-up activated INT0
	SBI PORTA , 1					;pull-up activated INT1
	SBI PORTC , 1					;pull-up activated INT2
	LDI R16 , (1<<INT0)				;enable INT0
	OUT GICR , R16
	SEI								;enable Interrupts
Here :
	JMP Here						;jmp to Here and wait for the next action

INT0_Handler :						;If INT0 actived , start pumping, B is off, L is on
     
	CLI								; disable all interrupts globally
	PUSH R16
	PUSH R17
	PUSH R18

	INC R26								 ; increase delay_time
	LDI R16,10
	CP R26 , R16
	breq continue_delay					;each 10s -> 1s delay
	LDI R17,1
    CP R27 , R17
	brne run							; we are at running state
	LDI R16 , 1							;idel state
	OUT PORTB , R16						; so turn on pump
	LDI R27 , 0							;0 -> system is running
	
	run:
		INC R24								 ;  increase total_time
		INC R25								 ;  increase blinking_time
	
		LDI R16,2
		CP R25 , R16
		brne handler_end
		LDI R25 , 0							; less than 2s so blink counter set to 0(restart)
		LDI R16,1
		IN R17,PIND							; read from PORTD
		EOR R17,R16							; NOT the PORTD -> connected to Light
		OUT PORTD,R17						;make blink
		jmp handler_end
    
	continue_delay:							;every 10s -> turn off pump
		LDI R27 , 1							;idel state
		LDI R16,0
		OUT PORTB,R16						; turn off P
		RCALL DELAY_1s						; 1s idel
		LDI R26 , 0							;reset delay counter

	; end section for interrupt0
	handler_end:
		POP R16
		POP R17
		POP R18
		SEI								; Ennable interrupt globally

INT1_Handler :						; pump is full  -> T is on: PORTA=1, L is off: PORTD=0
	LDI R24 , 0					    ; counter for total time: timer 999
	LDI R25 , 0                     ; counter for blinker (values up to 2) f=0.5 hz -> each 2s change
	LDI R26 , 0                     ; counter for delay -> each 10s -> 1s idle
	LDI R27 , 0                     ; system idle state  ( 0 -> system is running , 1 -> system is idle)	

	PUSH R16
	PUSH R17
	LDI R16,1
	OUT PORTA,R16
	LDI R17,0
	OUT PORTD,R17					; L off
	IN R17,TIMSK					;Disable timer0 INT
	ANDI R17,0XFF^(1<<TOIE0)		;TOIE0=0
	OUT TIMSK,R17

	CALL DELAY_2s					;delay for 2s
	LDI R16,1						;then B ON
	OUT PORTC,R16
	LDI R17,(1<<TOIE0)				;enable timer0
	OUT TIMSK,R17
	SEI
	POP R16
	POP R17
	RETI
INT2_Handler :						; pump is empty -> blink is off -> PORTD=0, start pumping -> PORTB=1
									; timer set to 999, enable timer
	;load timer with 999 (F = 1 KHZ)
	LDI R20,0XE7				; load low 8bits of 999
	LDI R21,3					; high 8 bits
	OUT OCR1AH , R21				
	OUT OCR1AL , R20	
	LDI R20,0x09
	OUT TCCR0,R20				;	start timer, CTC mode, no prescaler

	PUSH R16
	PUSH R17
	LDI R16,1
	OUT PORTB,R16					;start pumping
	LDI R17,0
	OUT PORTD,R17					;blink light is off
	LDI R16 , (1<<INT0)				;Enable timer: INT0 to pump
	OUT GICR , R16
	SEI
	POP R16
	POP R17
	RETI

DELAY_1s	 :                      ; F = 1 KHz
	PUSH R20
	PUSH R19
	LDI R20 , 0X00				
	OUT TCNT1H , R20				;Temp = 0
	OUT TCNT1L , R20				;TCNT1H = 0 , TCNT1L = Temp 

	LDI R20 , HIGH(1000-1)
	OUT OCR1AH , R20		
	LDI R20 , LOW(1000-1)			
	OUT OCR1AL , R20				;OCR1AL = Temp

	LDI R20 , 0X00
	OUT TCCR1A , R20				;WGM1 1:10 = 00
	LDI R20 , 0X09
	OUT TCCR1B , R20				;WGM1 3:12 = 01 , Timer1 , CTC mode , CS = 1

DELAY_2s	 :                      ; F = 1 KHz
	PUSH R20
	PUSH R19
	LDI R20 , 0X00				
	OUT TCNT1H , R20				;Temp = 0
	OUT TCNT1L , R20				;TCNT1H = 0 , TCNT1L = Temp 

	LDI R20 , HIGH(2000-1)
	OUT OCR1AH , R20		
	LDI R20 , LOW(2000-1)			
	OUT OCR1AL , R20				;OCR1AL = Temp

	LDI R20 , 0X00
	OUT TCCR1A , R20				;WGM1 1:10 = 00
	LDI R20 , 0X09
	OUT TCCR1B , R20				;WGM1 3:12 = 01 , Timer1 , CTC mode , CS = 1

AGAIN :
	IN R20 , TIFR					;Read TIFR
	SBRS R20 , OCF1A				;If OCF1A is set skip next instruction
	RJMP AGAIN
	LDI R20 , 1<<OCF1A
	OUT TIFR , R20					;Clear OCF1A flag
	LDI R19 , 0
	OUT TCCR1A , R19				;Stop Timer
	OUT TCCR1B , R19
	POP R19
	POP R20
	RET