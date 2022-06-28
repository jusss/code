#!/usr/bin/env python
# -*- coding: utf-8 -*-
# unzip-gbk.py
# python2 gbk.py MP3.zip

import os
import sys
import zipfile

print u"正在处理压缩文件 %s" % sys.argv[1].decode('utf-8')
print
file = zipfile.ZipFile(sys.argv[1], "r")
for gbkname in file.namelist():
    utf8name = gbkname.decode('gbk')
    print u"正在提取 %s" % utf8name
    pathname = os.path.dirname(utf8name)
    if not os.path.exists(pathname) and pathname != "":
        os.makedirs(pathname)
    if not os.path.exists(utf8name):
        data = file.read(gbkname)
        outfile = open(utf8name, "w")
        outfile.write(data)
        outfile.close()
file.close()

