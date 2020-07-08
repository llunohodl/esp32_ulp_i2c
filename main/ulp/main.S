/*
 * Demo of I2C ULP routines
 */

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"

//https://esp32.com/viewtopic.php?t=3050


#define GPIO_LED          12 // RTC_GPIO_12 == GPIO_2
#define GPIO_AON          14 // RTC_GPIO_14 == GPIO_13

#define GPIO_S0           15 // RTC_GPIO_15 == GPIO_12
#define GPIO_S1           16 // RTC_GPIO_16 == GPIO_14
#define GPIO_RLO          17 // RTC_GPIO_15 == GPIO_27

.macro save_dat from to offset
	move r2,\from
	ld r1,r2,0
	move r2,\to
	st r1,r2,\offset
.endm

.macro save_arch from to indx
    move r2,\indx			//Get "index" address
    ld r0,r2,0				//Load "index" value
    //r0 - index | r2 - addr index
	move r1,\to			    //Get "to" address
	add r1,r1,r0			//Addres for current data in r1
	//r0 - index | r1 - addr of cell | r2 - addr index
	add r0,r0,1				//Update index
	st 	r0,r2,0				//Save new index
	move r0,\from			//Load "from" address to r2
	//r0 - addr from | r1 - addr of cell
	ld 	r2,r0,0             //Load "from" value
	//r0 - addr from | r1 - addr of cell | r2 - value "from"
	st r2,r1,0              //Store "from" to array
.endm




.set mes_max,10

/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	.global stack
stack:
	.skip 100        //Stack depth 25
	.global stackEnd
stackEnd:
	.long 0

	.global r_hi, r_lo, v_hi, v_lo, mes_index, wake_count

r_hi: .long 0
r_lo: .long 0
v_hi: .long 0
v_lo: .long 0
mes_index: .long 0
wake_count: .long 0


	.global mes_arr
mes_arr:
	.fill 4*10*mes_max

	/* Code goes into .text section */
	.text
	.global entry
entry:
	move r3,stackEnd

	// GPIO2 LED ON
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_AON, 1, 0)

	// Wait 5ms for sensor computation
	move r2,5
	psr
	jump waitMs

	psr
	jump startVEML

	psr
	jump startSTLM

	//Select in 74HC4051
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_S0, 1, 0)
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_S1, 1, 0)
	//Select 390kOhm on high side
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_RLO, 1, 1)

	move r2,5
	psr
	jump waitMs

	psr
	jump performADC

	save_dat adc_res_1,r_hi,0
	save_dat adc_res_2,v_hi,0

	save_arch adc_res_1,mes_arr,mes_index
	save_arch adc_res_2,mes_arr,mes_index

	//Select 390||10kOhm on high side
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_RLO, 1, 0)

	move r2,5
	psr
	jump waitMs

	psr
	jump performADC

	save_dat adc_res_1,r_lo,0
	save_dat adc_res_2,v_lo,0

	save_arch adc_res_1,mes_arr,mes_index
	save_arch adc_res_2,mes_arr,mes_index


	// Wait 200ms for sensor computation
	move r2,210
	psr
	jump waitMs

	psr
	jump stopSTLM

	save_arch t_cur,mes_arr,mes_index //Save temperature

	psr
	jump stopVEML

	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_AON, 1, 1)

	//Save light
	save_arch l_clr,mes_arr,mes_index
    save_arch l_i,mes_arr,mes_index
	save_arch l_r,mes_arr,mes_index
	save_arch l_g,mes_arr,mes_index
	save_arch l_b,mes_arr,mes_index

    WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_LED, 1, 1)
	move r2,200
	psr
	jump waitMs
    WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + GPIO_LED, 1, 0)


	move r1,wake_count
	ld r0,r1,0
	sub r0,r0,1
	jump wake_up,eq //End measurment
	st r0,r1,0
	halt

	.global exit
exit:
	halt

	.global wake_up
wake_up:
	/* Check if the system can be woken up */
	READ_RTC_FIELD(RTC_CNTL_LOW_POWER_ST_REG, RTC_CNTL_RDY_FOR_WAKEUP)
	and r0, r0, 1
	jump exit, eq

	/* Wake up the SoC, end program */
	wake
	//WRITE_RTC_FIELD(RTC_CNTL_STATE0_REG, RTC_CNTL_ULP_CP_SLP_TIMER_EN, 0)
	halt

// Wait for r2 milliseconds
waitMs:
	wait 8000
	sub r2,r2,1
	jump doneWaitMs,eq
	jump waitMs
doneWaitMs:
	ret
