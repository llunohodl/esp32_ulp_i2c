

/* ULP assembly files are passed through C preprocessor first, so include directives
   and C macros may be used in these files
 */
#include "soc/rtc_cntl_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"

	/* ADC1 channel 7, GPIO35 */
	.set adc_channel, 7

	/* Configure the number of ADC samples to average on each measurement.
	   For convenience, make it a power of 2. */
	.set adc_oversampling_factor_log, 2
	.set adc_oversampling_factor, (1 << adc_oversampling_factor_log)

	/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	/* Counter of measurements done */
	.global sample_counter
sample_counter:
	.long 0

	.global adc_res
adc_res:
	.long 0

	/* Code goes into .text section */
	.text
	.global performADC
performADC:
	/* increment sample counter */
	move r1, sample_counter
	ld r2, r1, 0
	add r2, r2, 1
	st r2, r1, 0

	/* do measurements using ADC */
	/* r0 will be used as accumulator */
	move r0, 0
	/* initialize the loop counter */
	stage_rst
measure:
	/* measure and add value to accumulator */
	adc r1, 0, adc_channel + 1
	add r0, r0, r1
	/* increment loop counter and check exit condition */
	stage_inc 1
	jumps measure, adc_oversampling_factor, lt

	/* divide accumulator by adc_oversampling_factor.
	   Since it is chosen as a power of two, use right shift */
	rsh r0, r0, adc_oversampling_factor_log
	/* averaged value is now in r0; store it into adc_res */
	move r1, adc_res
	st r0, r1, 0
	ret
