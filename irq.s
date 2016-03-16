; ***********************************************************************
; *									*
; *			Interrupt Handler				*
; *									*
; ***********************************************************************

; Author:   William Nguyen
; Date:     18 October 2010
; Version:  1.0


; -----------------------------------------------------------------------
; The following code will be placed into the ".ospage" section, NOT into
; the ".text" section.  The GNU Linker will place the ".ospage" section at
; address 0x1000.

	.section .ospage, "awx" ; For "operating system" code

	.include "header-v3.s"	; Include definitions needed for this program


; -----------------------------------------------------------------------
; Interrupt handler

	.global irq_handler	 ; Make this label visible to other modules

	.extern irq_count
	.equ	Invert, 0b11111111	; Mask to turn LEDs on and off

irq_handler:				; This code runs in Interrupt mode
	; IRQ handler initialisation
	sub	lr, lr, #4		; Calculate the correct return address
	stmfd	sp!, {r0-r3, lr}	; Save registers to Interrupt mode stack

	ldr	r2, =iobase		; R2 = base of Microcontroller I/O space
	mov	r0, #0x06		; Timer will reach zero 250 increments after 6
	strb	r0, [r2, #timer_port]	; Reset timer port

	ldr	r1, =irq_count		; Load address of irq_count
	ldr	r0, [r1]		; Load value of counter
	add	r0, r0, #1		; Increment counter
	cmp	r0, #4			; If counter != 4,
	bne	save			; jump to save

	mov	r0, #0b00010000
	strb	r0, [r2, #portB]
	ldrb	r0, [r2, #portA]	; Read the current state of the LEDs
	eor	r0, r0, #Invert		; Invert the value
	strb	r0, [r2, #portA]	; Write the byte to Port A

	mov	r0, #0			; Reset counter
save:	str	r0, [r1]		; Save the counter to irq_count

	; Acknowledge interrupts
	ldrb	r0, [r2, #irq_status]	; Read the IRQ Status register into R0
	bic	r0, r0, #irq_timer	; Clear the IRQ for the timer
	strb	r0, [r2, #irq_status]	; Acknowledge the interrupt

	ldmfd	sp!, {r0-r3, pc}^	; Return to whatever the processor was
					; doing at the time of the interrupt by
					; restoring registers R0-R3 and CPSR

	.end
