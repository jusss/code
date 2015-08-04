#!/usr/bin/env python3

### usage: gbk2utf8.py gbk-file utf8-file
### the size of gbk-file shouldn't be bigger than memory's size, if it's not then maybe it will case error or slowly

import sys
original_file_name = sys.argv[1]
original_file_encoding = 'gb18030'
new_file_name = sys.argv[2]
new_file_encoding = 'utf-8'

b1=open(original_file_name,'rb')
a1=b1.read().decode(original_file_encoding, 'ignore')

a2=open(new_file_name,'a',encoding=new_file_encoding)
a2.write(a1)

b1.close()
a2.close()


