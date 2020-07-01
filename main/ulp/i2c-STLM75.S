/*
 * Demo of I2C ULP routines
 */

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"


.set STLM75_ADDR,0x4B // 7-bit address

.set STLM75_TEMP,0x00
.set STLM75_CONF,0x01

//SD = 1 shutdown
.set STLM75_CODE_OFF,0x01

//SD = 0 power on
.set STLM75_CODE_ON,0x00


/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	.global t_cur

t_cur: .long 0


	/* Code goes into .text section */
	.text

.global startSTLM
startSTLM:
	move r1,STLM75_ADDR
	push r1
	move r1,STLM75_CONF
	push r1
	move r1,STLM75_CODE_ON
	push r1
	psr
	jump write8
	add r3,r3,3 // remove 3 arguments from stack
	move r0,r2 // test for error in r2
	ret

.global stopSTLM
stopSTLM:
	// Read 16 bit result
	move r1,STLM75_ADDR
	push r1
	move r1,STLM75_TEMP
	push r1
	psr
	jump read16
	add r3,r3,2 // remove call parameters from stack
	move r1,r0 // save result
	move r0,r2 // test for error
	jumpr endSTLM,1,ge
	move r2,t_cur // store result
	st r1,r2,0
endSTLM:
	move r1,STLM75_ADDR
	push r1
	move r1,STLM75_CONF
	push r1
	move r1,STLM75_CODE_OFF
	push r1
	psr
	jump write8
	add r3,r3,3 // remove 4 arguments from stack
	move r0,r2 // test for error in r2
	ret
