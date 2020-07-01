/*
 * Demo of I2C ULP routines
 */

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"


#define GPIO_LED          12 // RTC_GPIO_12 == GPIO_2
#define GPIO_AON          14 // RTC_GPIO_14 == GPIO_13
#define GPIO_S0           15 // RTC_GPIO_15 == GPIO_12
#define GPIO_S1           16 // RTC_GPIO_16 == GPIO_14


/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	.global stack
stack:
	.skip 100
	.global stackEnd
stackEnd:
	.long 0


	/* Code goes into .text section */
	.text
	.global entry
entry:
	move r3,stackEnd

	// GPIO2 LED ON
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_AON, 1, 0)
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_LED, 1, 1)
	// Wait 5ms for sensor computation
	move r2,10
	psr
	jump waitMs
    WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_LED, 1, 0)

	psr
	jump startVEML


	// Wait 150ms for sensor computation
	move r2,210
	psr
	jump waitMs

	psr
	jump stopVEML

	// GPIO2 LED OFF

	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_AON, 1, 1)



	/* Wake up the SoC, end program */
	wake
	halt

// Wait for r2 milliseconds
waitMs:
	wait 8000
	sub r2,r2,1
	jump doneWaitMs,eq
	jump waitMs
doneWaitMs:
	ret
