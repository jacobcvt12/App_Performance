#!/usr/bin/env python

from sys import stdin
from sys import argv

header = ['company', 'version', 'date', 'easy', 'slow', 'error', 'broken', \
        'crash', 'reviews']

if __name__ == "__main__":
    company_name = argv[1]

    agg_info = {}
    empty_info = [0, 0, 0, 0, 0, 0]

    review_line = 0
    version = ''
    date = ''
    txt = ''
    triplet = ('', '', '')

    for line in stdin:
        if line[:8] == 'Version ':
            # do stuff with old text if there is any
            if len(txt):
                (easy, slow, error, broken, crash) = (0, 0, 0, 0, 0)

                if 'easy' in txt:
                    easy = 1

                if 'slow' in txt:
                    slow = 1

                if 'error' in txt:
                    error = 1

                if 'crash' in txt:
                    crash = 1

                review_count = 1

                counts = [easy, slow, error, broken, crash, review_count]
                agg_info[triplet] = [x + y for x, y in zip(agg_info[triplet], \
                        counts)]

            txt = ''
            review_line = 1
            review = line.split(' ') 

            version = review[1]
            date = review[2]
            triplet = (company_name, version, date)

            if triplet not in agg_info:
                agg_info[triplet] = empty_info

            # else already in dict so don't do anything yet

        else:
            txt += line

    print ','.join(header)

    for key in agg_info:
        print ','.join(key) + ',' + ','.join(str(num) for num in agg_info[key])
