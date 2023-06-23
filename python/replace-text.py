#!/usr/bin/env python3
import argparse, os

def change_file(input, output, origin, replace):
    new_data = ''
    with open(input, 'r', encoding='utf-8') as _file:
        data = _file.read()
        # rlist = data.split(origin)
        # plist = [replace for i in range(len(rlist) - 1)]
        # new_data = ''.join(map(lambda x,y: x+y, rlist, plist))
        for o,r in zip(origin, replace):
            data = data.replace(o, r)
    
    with open(output, 'w', encoding='utf-8') as f:
        f.write(data)

def file_or_dir(input, output, origin, replace):
    if os.path.isfile(input):
        change_file(input, output, origin, replace)
    if os.path.isdir(input):
        if not os.path.exists(output):
            os.makedirs(output)
        input_file_list = os.listdir(input)
        input_full_path = list(map(lambda x: (input if input.endswith("/") else input + "/") + x, input_file_list))
        output_full_path = list(map(lambda x: (output if output.endswith("/") else output + "/") + x, input_file_list))
        list(map(lambda i,o: file_or_dir(i, o, origin, replace), input_full_path, output_full_path))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("-i", "--input", help="input file path or dir")
    parser.add_argument("-o", "--output", help="output file path or dir")
    parser.add_argument("-w", "--origin", default=[], nargs='+', help="the original words")
    parser.add_argument("-r", "--replace", default=[], nargs='+', help="the new words")
    args = parser.parse_args()
    file_or_dir(args.input, args.output, args.origin, args.replace)
