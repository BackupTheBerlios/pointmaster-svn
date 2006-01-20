pm-tv.exe /check:*.pvt
if errorlevel=0 then goto exit
cls
echo error segment
:exit
exit