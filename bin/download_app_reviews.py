#!/usr/bin/env python

import urllib2
import xml.etree.ElementTree as ET
import sys
import re
from datetime import datetime

# dictionary of hotels and the corresponding app ID
hotelIDs = {
        'marriott' : '455004730',
        'hilton' : '337937175',
        'starwood' : '312306003',
        'booking' : '367003839',
        'expedia' : '427916203',
        'kayak' : '305204535',
        'airbnb' : '401626263'
        }

def getReviews(appId):
    ''' returns list of reviews for given application Id
        return list format: [{"topic": string, "review": string, "rank": int}]
    '''
    # initialize empty reviews list which will become a list of dictionaries
    # each dictionary contains info of one review
    reviews=[]
    
    # i is a counter for page numbers - the App Store only allows viewing
    # pages of 10 reviews at a time
    i=0

    # loop until _getReviewsForPage returns nothing
    # which indicates the end of reviews
    
    while True: 
        # iTunes will occasionally not load for certain page
        # (this happened for one specific page for airbnb
        # and the page would not load in iTunes or on an
        # iPhone. no fault of the scraper. In these instances,
        # skip this page and try the next
        try:
            ret = _getReviewsForPage(appId, i)
            if len(ret)==0:
                # there are no more reivews, break the loop
                break
            reviews += ret
            
        except:
            pass
        
        i += 1
    return reviews

def _getReviewsForPage(appId, pageNo):
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

        topic_node = xml_review.find("{0}HBoxView/{0}TextView/{0}SetFontStyle/{0}b".format(xmlns))
        if topic_node is None:
            review["topic"] = None
        else:
            review["topic"] = topic_node.text

        reviews.append(review)
    return reviews
   

if __name__ == '__main__':
    # Bash script passes name of company as the first (and only) argument
    hotel = sys.argv[1]

    # get reviews for specified hotel
    reviews = getReviews(hotelIDs[hotel])
   
    # write reviews
    # line 1: Version number (i.e. 1.2.4) Rating (i.e. 4)
    # line 2: Topic (i.e. Great app) Body of review (i.e. This app works)
    # note that the review body may be longer than one line
    # Bash script writes this to a .reviews file

    for review in reviews:
        print "%s %s %d" % (review["version"], review["date"], review["rank"])
        print " (%s) %s\n" % (review["topic"].encode('utf-8'), 
                review["review"].encode('utf-8'))
