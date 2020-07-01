/*
 * Demo of I2C ULP routines
 */

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"



.set VEML3328_ADDR,0x10 // 7-bit address

.set VEML3328_COMMAND_CODE,0x00

//SD0/1 = 0 power on | IT = 1 = Integration time setting 200ms
.set VEML3328_CODE_OFF,(1<<15)|(1<<5)|(1<<0)

//SD0/1 =  1 shutdown (default) | IT = 1 = Integration time setting 100ms
.set VEML3328_CODE_ON,(1 << 4)



.set VEML3328_COMMAND_C,0x04
.set VEML3328_COMMAND_R,0x05
.set VEML3328_COMMAND_G,0x06
.set VEML3328_COMMAND_B,0x07
.set VEML3328_COMMAND_IR,0x08
.set VEML3328_COMMAND_ID,0x0C

/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	.global temp
temp:	.long 0

	.global l_clr, l_r, l_g, l_b, l_i

l_clr: .long 0
l_r: .long 0
l_g: .long 0
l_b: .long 0
l_i: .long 0


	/* Code goes into .text section */
	.text

.global startVEML
startVEML:
	move r1,VEML3328_ADDR
	push r1
	move r1,VEML3328_COMMAND_CODE
	push r1
	move r1,VEML3328_CODE_ON
	push r1
	psr
	jump write16
	add r3,r3,3 // remove 3 arguments from stack
	move r0,r2 // test for error in r2
	ret

.global stopVEML
stopVEML:
	// Read 16 bit result
	move r1,VEML3328_ADDR
	push r1
	move r1,VEML3328_COMMAND_C
	push r1
	psr
	jump read16
	add r3,r3,2 // remove call parameters from stack
	move r1,r0 // save result
	move r0,r2 // test for error
	jumpr readR,1,ge
	move r2,l_clr // store result
	st r1,r2,0
readR:
	// Read 16 bit result
	move r1,VEML3328_ADDR
	push r1
	move r1,VEML3328_COMMAND_R
	push r1
	psr
	jump read16
	add r3,r3,2 // remove call parameters from stack
	move r1,r0 // save result
	move r0,r2 // test for error
	jumpr readG,1,ge
	move r2,l_r // store result
	st r1,r2,0
readG:
	// Read 16 bit result
	move r1,VEML3328_ADDR
	push r1
	move r1,VEML3328_COMMAND_G
	push r1
	psr
	jump read16
	add r3,r3,2 // remove call parameters from stack
	move r1,r0 // save result
	move r0,r2 // test for error
	jumpr readB,1,ge
	move r2,l_g // store result
	st r1,r2,0
readB:
	// Read 16 bit result
	move r1,VEML3328_ADDR
	push r1
	move r1,VEML3328_COMMAND_B
	push r1
	psr
	jump read16
	add r3,r3,2 // remove call parameters from stack
	move r1,r0 // save result
	move r0,r2 // test for error
	jumpr readI,1,ge
	move r2,l_b // store result
	st r1,r2,0
readI:
	// Read 16 bit result
	move r1,VEML3328_ADDR
	push r1
	move r1,VEML3328_COMMAND_IR
	push r1
	psr
	jump read16
	add r3,r3,2 // remove call parameters from stack
	move r1,r0 // save result
	move r0,r2 // test for error
	jumpr endVEML3328,1,ge
	move r2,l_i // store result
	st r1,r2,0
endVEML3328:
	move r1,VEML3328_ADDR
	push r1
	move r1,VEML3328_COMMAND_CODE
	push r1
	move r1,VEML3328_CODE_OFF
	push r1
	psr
	jump write16
	add r3,r3,3 // remove 4 arguments from stack
	move r0,r2 // test for error in r2
	ret
