/* ULP I2C bit bang BMP-180 Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include <stdio.h>
#include <math.h>
#include "esp_sleep.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/sens_reg.h"
#include "soc/soc.h"
#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "driver/adc.h"
#include "esp32/ulp.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "sdkconfig.h"


#include "ulp_main.h"

#define LOG_LOCAL_LEVEL ESP_LOG_INFO
#include <esp_log.h>
static const char *TAG = "APP";

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");


const gpio_num_t gpio_led = GPIO_NUM_2;
const gpio_num_t gpio_aon = GPIO_NUM_13;

const gpio_num_t gpio_s0 = GPIO_NUM_12;
const gpio_num_t gpio_s1 = GPIO_NUM_14;
const gpio_num_t gpio_rlo = GPIO_NUM_27;

const gpio_num_t gpio_scl = GPIO_NUM_32;
const gpio_num_t gpio_sda = GPIO_NUM_33;

static void init_ulp_program()
{
    rtc_gpio_init(gpio_led);
    rtc_gpio_set_direction(gpio_led, RTC_GPIO_MODE_OUTPUT_ONLY);
    rtc_gpio_init(gpio_aon);
    rtc_gpio_set_direction(gpio_aon, RTC_GPIO_MODE_OUTPUT_ONLY);

    rtc_gpio_init(gpio_s0);
    rtc_gpio_set_direction(gpio_s0, RTC_GPIO_MODE_OUTPUT_ONLY);
    rtc_gpio_init(gpio_s1);
    rtc_gpio_set_direction(gpio_s1, RTC_GPIO_MODE_OUTPUT_ONLY);
    rtc_gpio_init(gpio_rlo);
    rtc_gpio_set_direction(gpio_rlo, RTC_GPIO_MODE_OUTPUT_ONLY);


    rtc_gpio_init(gpio_scl);
    rtc_gpio_set_direction(gpio_scl, RTC_GPIO_MODE_INPUT_ONLY); //RTC_GPIO_MODE_INPUT_OUTPUT
    rtc_gpio_init(gpio_sda);
    rtc_gpio_set_direction(gpio_sda, RTC_GPIO_MODE_INPUT_ONLY);

    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    esp_deep_sleep_disable_rom_logging(); // suppress boot messages

    /* Configure ADC channel */
    /* Note: when changing channel here, also change 'adc_channel' constant
       in adc.S */
    adc1_config_channel_atten(ADC1_CHANNEL_6, ADC_ATTEN_DB_11);
    adc1_config_channel_atten(ADC1_CHANNEL_7, ADC_ATTEN_DB_11);
    adc1_config_width(ADC_WIDTH_BIT_12);
    adc1_ulp_enable();

    /* Disconnect GPIO12 and GPIO15 to remove current drain through
     * pullup/pulldown resistors.
     * GPIO12 may be pulled high to select flash voltage.
     */
    rtc_gpio_isolate(GPIO_NUM_12);
    rtc_gpio_isolate(GPIO_NUM_15);

    /* Set ULP wake up period to T = 20ms.
     * Minimum pulse width has to be T * (ulp_debounce_counter + 1) = 80ms.
     */
    ulp_set_wakeup_period(0, 1000000);

    /* Start the program */
    err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);

}

#define l_clr ((uint16_t)ulp_l_clr)
#define l_r ((uint16_t)ulp_l_r)
#define l_g ((uint16_t)ulp_l_g)
#define l_b ((uint16_t)ulp_l_b)
#define l_i ((uint16_t)ulp_l_i)
#define t_cur ((uint16_t)ulp_t_cur)
#define r_hi ((uint16_t)ulp_r_hi)
#define r_lo ((uint16_t)ulp_r_lo)
#define v_hi ((uint16_t)ulp_v_hi)
#define v_lo ((uint16_t)ulp_v_lo)
extern uint32_t ulp_mes_index;
extern uint32_t ulp_wake_count;


static void print_status(){
    ESP_LOGI(TAG,"Rhi %d Vhi %d",r_hi,v_hi);
    ESP_LOGI(TAG,"Rlo %d Vlo %d",r_lo,v_lo);

    int16_t tm=t_cur;
    tm>>=7;
    if(tm&(1 << 8)){
        tm |= 0xff00;
    }
    tm*=5;
    ESP_LOGI(TAG, "T: %0.1f", ((float )tm) / 10.0);

    ESP_LOGI(TAG, "C: %06d IR: %06d", l_clr, l_i);
    ESP_LOGI(TAG, "R: %06d G: %06d B: %06d", l_r, l_g,l_b);


    for(int i=0;i<(uint16_t)ulp_mes_index;i++){
        ESP_LOGI(TAG, "mes[%02d] = %d", i,(uint16_t)(&ulp_mes_arr)[i]);
    }
    ESP_LOGI(TAG, "index = %d", (uint16_t)ulp_mes_index);

}

void app_main()
{
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();
    if (cause != ESP_SLEEP_WAKEUP_ULP) {
        printf("Not ULP wakeup, initializing ULP\n");
        init_ulp_program();
    } else {

    	printf("ULP wakeup, printing status\n");
        print_status();
    }

    printf("Entering deep sleep\n\n");

    ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup() );
    ulp_mes_index = 0;
    ulp_wake_count = 4;
    esp_deep_sleep_start();
}
