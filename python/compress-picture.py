#!/usr/bin/env python3
import argparse, os

def change_file(input, output):
    cmd = 'echo "' + input + ' not convert"'
    if any(list(map(lambda x: input.endswith(x),["JPEG","JPG","HEIC"]))):
        # if input.endswith("jpeg"):
        # stackoverflow 10234065
        _output = output.split(".")[0] + ".jpg"
        cmd = f"ffmpeg -i {input} -qscale:v 2 {_output}"

    # if input.endswith("MOV"):
    if any(list(map(lambda x: input.endswith(x),["MOV"]))):
        _output = output.split(".")[0] + ".mp4"
        cmd = f"ffmpeg -i {input} -c:v libx265 -crf 16 -c:a aac -b:a 128k {_output}"

    os.system(cmd)

def file_or_dir(input, output, k):
    if os.path.isfile(input):
        k(input, output)
    if os.path.isdir(input):
        if not os.path.exists(output):
            os.makedirs(output)
        input_file_list = os.listdir(input)
        input_full_path = list(map(lambda x: (input if input.endswith("/") else input + "/") + x, input_file_list))
        output_full_path = list(map(lambda x: (output if output.endswith("/") else output + "/") + x, input_file_list))
        list(map(lambda i,o: file_or_dir(i, o, k), input_full_path, output_full_path))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("-i", "--input", help="input file path or dir")
    parser.add_argument("-o", "--output", help="output file path or dir")
    args = parser.parse_args()

    file_or_dir(args.input, args.output, change_file)
