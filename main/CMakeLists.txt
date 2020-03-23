idf_component_register(SRCS "ulp_app.c"
                    INCLUDE_DIRS ""
                    REQUIRES soc nvs_flash ulp)
#
# ULP support additions to component CMakeLists.txt.
#
# 1. The ULP app name must be unique (if multiple components use ULP).
set(ULP_APP_NAME ulp_${COMPONENT_NAME})
#
# 2. Specify all assembly source files.
#    Files should be placed into a separate directory (in this case, ulp/),
#    which should not be added to COMPONENT_SRCS.
set(ULP_S_SOURCES "ulp/main.S" "ulp/i2c-bmp180.S" "ulp/i2c-util.S" "ulp/i2c.S" "ulp/stack.S" )
#
# 3. List all the component source files which include automatically
#    generated ULP export file, ${ulp_app_name}.h:
set(ULP_EXP_DEP_SRCS "ulp_app.c")

#
# 4. Call function to build ULP binary and embed in project using the argument
#    values above.
ulp_embed_binary(${ULP_APP_NAME} ${ULP_S_SOURCES} ${ULP_EXP_DEP_SRCS})
