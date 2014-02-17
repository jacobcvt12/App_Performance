#!/usr/bin/env python

import urllib2
from elementtree import ElementTree
import sys
import re

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
    url = "http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%s&pageNumber=%d&sortOrdering=4&onlyLatestVersion=false&type=Purple+Software" % (appId, pageNo)

    # Request method is used in order to pass spoofing info
    review_page_request = urllib2.Request(
            url, headers={"X-Apple-Store-Front" : front,
                          "User-Agent" : userAgent})

    # open request object review_page_request
    review_page = urllib2.urlopen(review_page_request, timeout=30)
   
    # goal: replace ElementTree package with xml.etree.ElementTree and rewrite
    # all of the following code in the program
    # will need to add in code to determine date of review
    # hint: it sits right below the version of the app reviewed
    root = ElementTree.parse(review_page).getroot()

    # create empty list to store list of dictionary of reviews
    # (dictionary created and filled in for loop)
    reviews=[]

    for node in root.findall('{http://www.apple.com/itms/}View/{http://www.apple.com/itms/}ScrollView/{http://www.apple.com/itms/}VBoxView/{http://www.apple.com/itms/}View/{http://www.apple.com/itms/}MatrixView/{http://www.apple.com/itms/}VBoxView/{http://www.apple.com/itms/}VBoxView/{http://www.apple.com/itms/}VBoxView/'):
        # create empty dictionary to store individual review information in
        review = {}

        review_node = node.find("{http://www.apple.com/itms/}TextView/{http://www.apple.com/itms/}SetFontStyle")
        if review_node is None:
            review["review"] = None
        else:
            review["review"] = review_node.text

        version_node = node.find("{http://www.apple.com/itms/}HBoxView/{http://www.apple.com/itms/}TextView/{http://www.apple.com/itms/}SetFontStyle/{http://www.apple.com/itms/}GotoURL")
        if version_node is None:
            review["version"] = None
        else:
            review["version"] = re.search("Version [^\n^\ ]+", version_node.tail).group()
    
        rank_node = node.find("{http://www.apple.com/itms/}HBoxView/{http://www.apple.com/itms/}HBoxView/{http://www.apple.com/itms/}HBoxView")
        try:
            alt = rank_node.attrib['alt']
            st = int(alt.strip(' stars'))
            review["rank"] = st
        except KeyError:
            review["rank"] = None

        topic_node = node.find("{http://www.apple.com/itms/}HBoxView/{http://www.apple.com/itms/}TextView/{http://www.apple.com/itms/}SetFontStyle/{http://www.apple.com/itms/}b")
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
        print "%s %d" % (review["version"], review["rank"])
        print " (%s) %s\n" % (review["topic"].encode('utf-8'), 
                review["review"].encode('utf-8'))
