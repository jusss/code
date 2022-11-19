#!/usr/bin/env python3
import os, argparse
from datetime import datetime

def trim(input_file, start_time, end_time, output_file):
    start = datetime.strptime(start_time, "%H:%M:%S")
    end = datetime.strptime(end_time, "%H:%M:%S")
    duration = end - start
    # print(duration)
    _minute, second = divmod(duration.seconds, 60)
    hour, minute = divmod(_minute, 60)
    t = ":".join([ "0" + str(x) if x < 10 else str(x) for x in [hour, minute, second] ])
    # print(t)
    cmd = f"ffmpeg -ss {start_time} -t {t} -i {input_file} -vcodec copy -acodec copy {output_file}"
    print(cmd)
    os.system(cmd)

def concat_video(input_files, output_file):
    with open("input_video_files.txt","w") as f:
        for i in input_files:
            f.write(f"file {i}\r\n")
    cmd = f'ffmpeg -f concat -i input_video_files.txt -c copy {output_file}'
    print(cmd)
    os.system(cmd)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=
            'video-edit.py -i input_file -s "00:03:00" -e "00:06:00" -o output_file ' +
            'or video-edit.py -m concat -i input_files -o output_file')
    parser.add_argument("-m", "--mode", default = "trim", help = "trim as default, or concat")
    parser.add_argument("-i", "--input_files", nargs='+')
    parser.add_argument("-s", "--start_time")
    parser.add_argument("-e", "--end_time")
    parser.add_argument("-o", "--output_file")
    args = parser.parse_args()
    if args.mode == "trim":
        trim(args.input_files[0], args.start_time, args.end_time, args.output_file)
    if args.mode == "concat":
        concat_video(args.input_files, args.output_file)
