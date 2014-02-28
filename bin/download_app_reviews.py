#!/usr/bin/env python

import urllib2
import xml.etree.ElementTree as ET
import sys
import re
from datetime import datetime

def download_reviews(pageNo):
    # create userAgent to spoof user agent and pretend to be iTunes
    userAgent = 'iTunes/9.2 (Macintosh; U; Mac OS X 10.6)'
    
    # store country info (number for US reviews)
    front = "143441-1"

    # url for app appId reviews on page pageNo
    url = "http://ax.phobos.apple.com.edgesuite.net/WebObjects/" + \
            "MZStore.woa/wa/viewContentsUserReviews?" + \
            "id=%s&pageNumber=%d&sortOrdering=4" % (appId, pageNo) + \
            "&onlyLatestVersion=false&type=Purple+Software"

    # store xml namespace in string to reduce tag lengths
    xmlns = '{http://www.apple.com/itms/}'
    
    # Request method is used in order to pass spoofing info
    review_page_request = urllib2.Request(
            url, headers={"X-Apple-Store-Front" : front,
                          "User-Agent" : userAgent})

    # open request object review_page_request, parse xml to review_page_root
    review_page = urllib2.urlopen(review_page_request, timeout=30)
    review_page_root = ET.parse(review_page).getroot()

    # create empty list to store list of dictionary of reviews
    # (dictionary created and filled in for loop)
    reviews=[]

    xml_review_path = '{0}View/{0}ScrollView/{0}VBoxView/{0}View/{0}MatrixView/{0}VBoxView/{0}VBoxView/{0}VBoxView'.format(xmlns)

    # get to tags of reviews and loop over them
    for xml_review in review_page_root.findall(xml_review_path):
        # create empty dictionary to store individual review information in
        review = {}

        review_node = xml_review.find("{0}TextView/{0}SetFontStyle".format(xmlns))
        if review_node is None:
            review["review"] = None
        else:
            review["review"] = review_node.text

        version_node = xml_review.find("{0}HBoxView/{0}TextView/{0}SetFontStyle/{0}GotoURL".format(xmlns))
        if version_node is None:
            review["version"] = None
        else:
            review["version"] = re.search("Version [^\n^\ ]+", version_node.tail).group()
        
        dt = re.search("[A-Za-z]{3} [0-9]{1,2}, [^\n^\ ]+", version_node.tail).group() 

        review["date"] = \
                datetime.strptime(dt, "%b %d, %Y").strftime("%Y-%m-%d")

        rank_node = xml_review.find("{0}HBoxView/{0}HBoxView/{0}HBoxView".format(xmlns))
        try:
            alt = rank_node.attrib['alt']
            st = int(alt.strip(' stars'))
            review["rank"] = st
        except KeyError:
            review["rank"] = None

        reviews.append(review)
    return reviews
   

if __name__ == '__main__':
    # Bash script passes app ID number as the first (and only) argument
    appId = sys.argv[1]


    # initialize empty reviews list which will become a list of dictionaries
    # each dictionary contains info of one review
    all_reviews=[]
    
    # i is a counter for page numbers - the App Store only allows viewing
    # pages of 10 reviews at a time
    i=0

    # loop until download_reviews returns nothing
    # which indicates the end of reviews
    
    while True: 
        # iTunes will occasionally not load for certain page
        # (this happened for one specific page for airbnb
        # and the page would not load in iTunes or on an
        # iPhone. no fault of the scraper. In these instances,
        # skip this page and try the next
        try:
            page_of_reviews = download_reviews(i)
            if len(page_of_reviews) == 0:
                # there are no more reviews, break the loop
                break
            all_reviews += page_of_reviews
            
        except:
			# loading of page i didn't work. increment i and try again
            pass
        
        i += 1
   
    # write reviews
    # line 1: Version number (i.e. 1.2.4) Rating (i.e. 4)
    # line 2: Body of review (i.e. This app works)
    # note that the review body may be longer than one line
    # Bash script writes this to a .reviews file

    for review in all_reviews:
		# topic and review text can include non-ascii characters
		# so we encode as utf-8 in order to write to a file
        print "%s %s %d" % (review["version"], review["date"], review["rank"])
        print "%s" % review["review"].encode('utf-8')
