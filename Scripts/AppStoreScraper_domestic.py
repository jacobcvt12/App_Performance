#!/usr/bin/env python

import urllib2
from elementtree import ElementTree
import sys
import string
import argparse
import re

try:
    hotel = sys.argv[1]
except:
    hotel = "marriott"

hotelIDs = {
        'marriott' : '455004730',
        'hilton' : '337937175',
        'starwood' : '312306003',
        'booking' : '367003839',
        'expedia' : '427916203',
        'kayak' : '305204535',
        'airbnb' : '401626263'
        }

def getReviews(appStoreId, appId):
    ''' returns list of reviews for given AppStore ID and application Id
        return list format: [{"topic": unicode string, "review": unicode string, "rank": int}]
    ''' 
    reviews=[]
    i=0
    while True: 
        try:
            ret = _getReviewsForPage(appStoreId, appId, i)
            if len(ret)==0: # funny do while emulation ;)
                break
            reviews += ret
        except:
            pass
        i += 1
    return reviews

def _getReviewsForPage(appStoreId, appId, pageNo):
    userAgent = 'iTunes/9.2 (Macintosh; U; Mac OS X 10.6)'
    front = "%d-1" % appStoreId
    url = "http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%s&pageNumber=%d&sortOrdering=4&onlyLatestVersion=false&type=Purple+Software" % (appId, pageNo)
    req = urllib2.Request(url, headers={"X-Apple-Store-Front": front,"User-Agent": userAgent})
    try:
        u = urllib2.urlopen(req, timeout=30)
    except urllib2.HTTPError:
        print "Can't connect to the AppStore, please try again later."
        raise SystemExit
    root = ElementTree.parse(u).getroot()
    reviews=[]
    for node in root.findall('{http://www.apple.com/itms/}View/{http://www.apple.com/itms/}ScrollView/{http://www.apple.com/itms/}VBoxView/{http://www.apple.com/itms/}View/{http://www.apple.com/itms/}MatrixView/{http://www.apple.com/itms/}VBoxView/{http://www.apple.com/itms/}VBoxView/{http://www.apple.com/itms/}VBoxView/'):
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
    
        user_node = node.find("{http://www.apple.com/itms/}HBoxView/{http://www.apple.com/itms/}TextView/{http://www.apple.com/itms/}SetFontStyle/{http://www.apple.com/itms/}GotoURL/{http://www.apple.com/itms/}b")
        if user_node is None:
            review["user"] = None
        else:
            review["user"] = user_node.text.strip()

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
    
def _print_reviews(reviews):
    ''' returns (reviews count, sum rank)
    '''
    if len(reviews)>0:
        sumRank = 0
        for review in reviews:
            print "%s %d" % (review["version"], review["rank"])
            print " (%s) %s" % (review["topic"].encode('utf-8'), review["review"].encode('utf-8'))
            print ""
            sumRank += review["rank"]
        return (len(reviews), sumRank)
    else:
        return (0, 0)

if __name__ == '__main__':
    reviews = getReviews(143441, hotelIDs[hotel])
    _print_reviews(reviews)
        
