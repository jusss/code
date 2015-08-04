#!/usr/bin/env python3

### "(html ...)" -> [ '(', 'html', ... ')'] -> ['</html>',...'<html>'] -> ['<html>'...'</html>'] -> "<html>...</html>"

### set a list as a stack to store one token after '<', convert_list to store the list after changingn
stack=[]
clist=[]
s="(html (body (h1 hello)))"

def car(alist):
    return alist[0]

def cdr(alist):
    return alist[1:]

def cons(atom,alist):
    return [atom]+alist

def reverse(alist):
    return alist[::-1]

def tokenize(s):
    "Convert a string into a list of tokens."
    return s.replace('(',' ( ').replace(')',' ) ').split()

def list2string(alist):
    return ''.join(alist)

def convert(alist, clist, stack):
    if not alist:
        return clist
    else:
        if car(alist) == '(':
            return convert(cdr(cdr(alist)), cons('<'+car(cdr(alist))+'>',clist), cons(car(cdr(alist)),stack))
        else:
            if car(alist) == ')':
                return convert(cdr(alist), cons('</'+car(stack)+'>',clist), cdr(stack))
            else:
                return convert(cdr(alist), cons(car(alist),clist), stack)

print(list2string(reverse(convert(tokenize(s), clist, stack))))




    
    
