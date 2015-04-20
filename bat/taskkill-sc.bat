rem stop u8 services

sc stop UFNET
sc stop U8TaskService
sc stop UFReportService
sc stop U8DispatchService
sc stop U8KeyManagePool
sc stop U8MPool
sc stop U8SCMPool
sc stop U8WebPool
sc stop U8SLReportService
sc stop UTUService
sc stop Apache4TurboCRM70
sc stop TurboCRM70
sc stop 'memcached Server'

rem kill u8 process

taskkill.exe /F /T /IM U8* /IM UFIDA* /IM Android* /IM XYNT* /IM SQL* /IM fdl* /IM java* /IM daemon* /IM httpd* /IM memcac* /IM ddsvr* /IM bgtasksvr* /IM AsLdr* /IM ServerNT*

pause 

