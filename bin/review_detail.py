#!/usr/bin/env python

from glob import glob
from sys import stdout

if __name__ == "__main__":
    review_files = [fn for fn in glob("../output/reviews/*.reviews")
                    if not 'summarized' in fn]
    stdout.write("Company|Version|Date|Rating|Review\n")

    for review_file in review_files:
        company = review_file.split("/")[-1].split(".")[0]

        with open(review_file) as f:
            text = None

            for line in f:
                if line[:7] == "Version":
                    if text is not None:
                        stdout.write("|\"" + \
                                text.replace("\n", " ").replace("\"", "'") + \
                                "\"\n")

                    line = line.replace("\n", "")
                    review_info = line.split(" ")
                    review_info[0] = company
                    text = ""
                    stdout.write("|".join(review_info))

                else:
                    text += line
