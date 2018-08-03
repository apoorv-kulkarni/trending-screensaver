#!/usr/bin/env python

#-----------------------------------------------------------------------
# twitter-trends
#  - lists the current global trending topics
#-----------------------------------------------------------------------

from twitter import *

#-----------------------------------------------------------------------
# load our API credentials
#-----------------------------------------------------------------------
import sys, json
sys.path.append(".")
import config

#-----------------------------------------------------------------------
# create twitter API object
#-----------------------------------------------------------------------
twitter = Twitter(auth = OAuth(config.access_key,
                  config.access_secret,
                  config.consumer_key,
                  config.consumer_secret))

#-----------------------------------------------------------------------
# retrieve global trends.
# other localised trends can be specified by looking up WOE IDs:
#   http://developer.yahoo.com/geo/geoplanet/
# twitter API docs: https://dev.twitter.com/rest/reference/get/trends/place
#-----------------------------------------------------------------------

class SetEncoder(json.JSONEncoder):
    def default(self, obj):
       if isinstance(obj, set):
          return list(obj)
       return json.JSONEncoder.default(self, obj)

#-----------------------------------------------------------------------
#Driver function
#-----------------------------------------------------------------------
def trnds():
    # print("USA Trends\n")
    results = twitter.trends.place(_id = 23424977)
    filtered_set = set()
    for location in results:
     for trend in location["trends"]:
         filtered_set.add(str(trend["name"]))
    
    print(json.dumps(filtered_set, cls=SetEncoder))
     
#-----------------------------------------------------------------------
#Main function
#-----------------------------------------------------------------------
if __name__ == '__main__':
    trnds()


