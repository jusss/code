#!/usr/bin/env python3
import argparse, os, datetime, codecs
from functools import *

result = []

# type FilePath = String
# open_file :: FilePath -> [String]
def open_file(input_file):
    encodings = ['utf-8', 'gb18030','big5', 'big5hkscs', 'utf-16-le', 'utf-16-be','utf-16', 'windows-1250', 'windows-1252']
    for e in encodings:
        try:
            fh = codecs.open(input_file, 'r', encoding=e)
            data = fh.read()
            return list(map(lambda x: x.lower(), filter(lambda x: x!= '', data.split('\n'))))
        except UnicodeDecodeError:
            return None
        # else:
            # print(f'opening {input_file} with {e}')

# grep_file :: FilePath -> FilePath -> Float -> Float -> IO ()
def grep_file(input_file, sensitive_file, from_time, to_time):
    if os.path.getmtime(input_file) < from_time:
        return None

    if os.path.getmtime(input_file) > to_time:
        return None

    skip_file = [".tar", ".bin", ".exe", ".mp4", ".mkv", ".zip", ".7z", ".rar", "HEAD", "bla2", "master"]
    for i in skip_file:
        if input_file.endswith(i):
            return None

    # data :: [String]
    data = open_file(input_file)

    if data is None:
        return None

    # sensitive_data :: [String]
    sensitive_data = open_file(sensitive_file)

    if sensitive_data is None:
        raise Exception(f"failed to open {sensitive_file}")

    for s in sensitive_data:
        for d in data:
            if s in d:
                # print(f'{input_file}\n{d}\n')
                result.append((input_file, d))

# file_or_dir :: FilePath -> FilePath -> Float -> Float -> IO ()
def file_or_dir(input_file, sensitive_file, from_time, to_time):
    if os.path.isfile(input_file):
        grep_file(input_file, sensitive_file, from_time, to_time)
    if os.path.isdir(input_file):
        input_file_list = os.listdir(input_file)
        input_full_path = list(map(lambda x: (input_file if input_file.endswith("/") else input_file + "/") + x, input_file_list))
        sensitive_list = [ sensitive_file for i in range(len(input_file_list)) ]
        from_time_list = [ from_time for i in range(len(input_file_list)) ]
        to_time_list = [ to_time for i in range(len(input_file_list)) ]
        list(map(lambda i, s, f, t: file_or_dir(i, s, f, t), input_full_path, sensitive_list, from_time_list, to_time_list))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("-i", "--input_file", help="input_file file path or dir")
    parser.add_argument("-s", "--sensitive_file", help="sensitive_file file path")
    parser.add_argument("-f", "--from_time", help="from when, like '2022-02-12'")
    parser.add_argument("-t", "--to_time", default = None, help="to when, like '2022-02-12'")
    args = parser.parse_args()
    from_time = datetime.datetime.strptime(args.from_time, "%Y-%m-%d").timestamp()
    if args.to_time is None:
        to_time = datetime.datetime.now().timestamp()
    else:
        to_time = datetime.datetime.strptime(args.to_time, "%Y-%m-%d").timestamp()
    file_or_dir(args.input_file, args.sensitive_file, from_time, to_time)

    remove_dup = lambda alist: [alist[i] for i in range(len(alist)) if alist[i] not in alist[i+1::]]
    # print(remove_dup(result))

    # [("a",1), ("b",2), ("a",3)...] to [("a",[1,3...]), ("b",[...])...]
    # M.fromListWith (++) . fmap (fmap pure)
    # M.fromListWith (<>) . map (fmap S.singleton)
    # M.fromListWith (M.unionWith (+)) . map (fmap (`M.singleton` 1))

    r1 = remove_dup(result)

    the_first_ones = remove_dup(list(map(lambda xy: xy[0], r1)))
    print(f'****** {the_first_ones}')

    # r2 :: [(String,[String])]
    r2 = map(lambda first_one: (first_one, list(map(lambda xy: xy[1], filter(lambda xy: xy[0] == first_one, r1)))), the_first_ones)
    # r2 = map(lambda first_one: (first_one, [ y for (x,y) in r1 if x == first_one ]), the_first_ones)


    # for path, data in r1:
        # print(f'{path}\n{data}\n')

    for path, data in r2:
        print(f'****** {path}')
        list(map(print, data))
        print('')
