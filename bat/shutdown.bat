因为楼主的批处理名字是shutdown.bat,所以当批处理的内容是shutdown -s -t 200时调用的是shutdown.bat本身而不是系统的shutdown.exe,
不信你新建一个批处理,命名为test.bat,内容为test,打开就可以看到效果,所以只需要改个别的名字就行了!

所以创建shutdown.bat写 shutdown.exe /f /p即可解决，如果直接写shutdown /f /p会调用shutdown.bat本身而不是shutdown.exe
