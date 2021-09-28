#!/usr/bin/env python3

### usage: $./combine-subtitle.py English.srt Chinese.srt English-Chinese.srt

import sys
empty_line = '\n'
count = 1
        
sub = []
sub.append(open(sys.argv[1], 'r', encoding = 'utf-8'))
sub.append(open(sys.argv[2], 'r', encoding = 'utf-8'))
sub.append(open(sys.argv[3], 'a', encoding = 'utf-8'))


file1_string_list = sub[0].readlines()
file2_string_list = sub[1].readlines()
file3_string_list = []

""" 
2个列表的对比，并把中间的项捡出
读取整个文件行，然后匹配时间戳，在列表里找时间戳项，并把时间戳中间的项捡出来，就是字幕
2个列表的里面的项的匹配 ["00:01", hi, "00:02", bla]  ["00:01", 你好, "00:02", ...]
列表1 英文字幕， 列表2 中文字幕
在列表1中找到 -->的项，然后去列表2中匹配，并把匹配后的项到\r\n
得到列表1中-->项的位置和值，然后用值去匹配列表2,并得到列表2的位置，然后列表2寻找\r\n项
并存列表3中
"""
def get_strings_position_in_list(astring, alist, position):
    while position < len(alist):
        if alist[position].find(astring) != -1:
            yield position
        position = position + 1
            
### 找到 --> 在列表1中的位置    
g = get_strings_position_in_list(" --> ", file1_string_list, 0)
while True:
    try:
        position1 = next(g)
    except StopIteration as e:
        break
    ### find the timestamp
    timestamp = file1_string_list[position1]

    ### append number line
    file3_string_list.append(str(count) + "\n")
    count = count + 1

    ### append timestamp to file3_string_list
    file3_string_list.append(timestamp)
    ### append file1_string_list's subtitle into file3_string_list
    try:
        file3_string_list.append(
            file1_string_list[position1 + 1:
                              file1_string_list.index(empty_line, position1)])
    ### if last line is not \n, do this    
    except ValueError as e:
        file3_string_list.append(
            file1_string_list[position1 + 1:])

    try:
        ### find timestamp in file2_string_list, if don't find it then pass and loop again
        position2 = file2_string_list.index(timestamp)
        try:
            file3_string_list.append(
                file2_string_list[position2 + 1:
                                  file2_string_list.index(empty_line, position2) + 1])
        except ValueError as e:
            ### if last line is not \n
            file3_string_list.append(
                file2_string_list[position2 + 1:])
    except ValueError as e:
        file3_string_list.append("\n")
        pass
            



### print(file3_string_list)
### file3_string_list is like [["00:00:00 --> 00:00:04"], ["hi"], ["\n"]], there're inner list in it, unpack it first, then turn it to string
new_list = []
for i in file3_string_list:
    new_list.append("".join(i))

#new_list=[i[0] for i in file3_string_list]

### file.writelines(a_list) 
sub[2].writelines(new_list)
sub[0].close()
sub[1].close()


"""
4
00:04:37,647 --> 00:04:42,050
Now, look, here's the list of all the patients
we've had in the ward in the last month.

5
00:04:49,359 --> 00:04:50,587
Thank you, Nurse.

6
00:05:58,061 --> 00:06:00,928
- You're Alexandria?
- Yes.

不要排序的数字，只要时间和字幕，readline判断是否是时间(搜索: : -->)，readline判断字幕下一行是否是空行(读完一行，读下一行看是否是空行)

两个函数read_timestamp和read_subtitle, 2个互相尾递归调用(not a good idea)
read_timestamp执行完yield返回，next执行read_subtitle,然后yield返回再read_timestamp

combine two subtitle files to one, one file is english, another is chinese
they share the same time
class names named with CamelCase, all others lower_case_with_underscores, like variable and method

class JohnsList(list):
    
    def empty(self):
        if self == []:
            return True
        else:
            return False
            
    def car(self):
        if self != []:
            return self[0]
        else:
            return False
        
    def cdr(self):
        if self != []:
            return self[1:]
        else:
            return False
"""
