

/* ULP assembly files are passed through C preprocessor first, so include directives
   and C macros may be used in these files
 */
#include "soc/rtc_cntl_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"

/* ADC1 channel 7, GPIO35 */
.set adc_ch1, 7
/* ADC1 channel 6, GPIO34 */
.set adc_ch2, 6

/* Configure the number of ADC samples to average on each measurement.
   For convenience, make it a power of 2. */
.set adc_oversampling_factor_log, 4
.set adc_oversampling_factor, (1 << adc_oversampling_factor_log)

	/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	.global adc_res_1,adc_res_2
adc_res_1: .long 0
adc_res_2: .long 0

	/* Code goes into .text section */
	.text
	.global performADC
performADC:

	/* do measurements using ADC */
	/* r1/r2 will be used as accumulators */
	move r1, 0
	move r2, 0
	/* initialize the loop counter */
	stage_rst
measure:
	/* measure and add value to accumulator */
	adc r0, 0, adc_ch1 + 1
	add r1, r1, r0
	adc r0, 0, adc_ch2 + 1
	add r2, r2, r0
	/* increment loop counter and check exit condition */
	stage_inc 1
	jumps measure, adc_oversampling_factor, lt

	/* divide accumulators by adc_oversampling_factor.
	   Since it is chosen as a power of two, use right shift */
	rsh r1, r1, adc_oversampling_factor_log
	rsh r2, r2, adc_oversampling_factor_log
	/* averaged value is now in r1/r2; store it into adc_res_1 */
	move r0, adc_res_1
	st r1, r0, 0
	move r0, adc_res_2
	st r2, r0, 0
	ret
