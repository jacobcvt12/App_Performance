#!/usr/bin/env python

from sys import stdin

if __name__ == '__main__':
    for line in stdin:
        line = line.replace('\n', '')
        if line[:7] == 'company':
            print line
        else:
            t = line.split('|')
            n = [t[0], '"' + t[1] + '"', t[2], t[3], t[4]]
            print '|'.join(str(x) for x in n)
