
## send MiconV2 watchdog disable cmd
/source/micro-evtd -s 0003

#if that succeeded setup LCD/LEDS via MiconV2
if [ $? -eq 0 ]; then

  ##clear alert leds if any set power led
  /source/micro-evtd -s 0250090f96,02520000ac,02510d00a0

  ## set lcd display to installer message
  /source/micro-evtd -s 20905465726173746174696f6e207838362044656269616e20496e7374616c6c6572,0025,013220,013aff

  ##clear alert leds if any set power led
  /source/micro-evtd -s 0250090f96,02520000ac,02510d00a0

  ##try changing the lcd color
  /source/micro-evtd -s 02500007,02510006

  exit 0

fi

## send MiconV3 get version command
/source/micro-evtd -s3 "VER_GET"

#if that succeeded setup LCD/LEDS via MiconV3
if [ $? -eq 0 ]; then

  ## diable startup watchdog if present
  /source/micro-evtd -s3 "BOOT_END"

  ## Set Power LED to on
  /source/micro-evtd -s3 "LED_ON 0"

  ## set LCD message
  /source/micro-evtd -s3 "LCD_PUTS 0 Terastation x86","LCD_PUTS 1 Debian Installer"

  exit 0
fi

exit 0
