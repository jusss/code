#!/usr/bin/env python3

### "(html (body ...))" -> " ( html  ( body ... ) ) " -> [ '(', 'html', ... ' ) ', ')'] -> [ '<','html',...'>'] -> "<html> ...</html>"

### set a list as a stack to store one token after '<', convert_list to store the list after changingn
global stack=[]
global convert_list=[]

### define a function to push and pop the stack
def push(token):
    stack.append(token)
    
def pop():
    first=stack[0]
    stack.remove_first()
    return first

def tokenize(s):
    "Convert a string into a list of tokens."
    return s.replace('(',' ( ').replace(')',' ) ').split()

def convert(alist):

    if stack[0]='(':
        convert_list.appen('<')
        push(stack[1])
        stack.remove_first()
        return convert(alist)
    else:
        if stack[0]=')':
            stack.append(pop())
            stack.append('>')
            stack.remove_first()
            return convert(alist)
        else:
            stack.append(stack[0])
            stack.remove_first()
            return convert(alist)

def parse(string):
    return list2string(convert(tokenize(string)))

### list.remove_first() shoule turn  ['1', '2'...] to ['2'...] like (car ...) in lisp




    
    
