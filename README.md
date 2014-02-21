App_Performance
===============

App_Performance is a project for downloading reviews for apps and 
comparings the reviews of each of the apps.

The idea behind this project is to download app reviews for all 
apps in a commercial market to compare performance of each of the
company's apps and find out where each app is succeeding and 
failing. This project was initially designed to investigate 
the hospitality market, but is translatable to any other market.

Dependencies
============

Python 2.7
- Only standard library python is required. 

R 3.0
- Rcpp (note this requires a c++ compiler, such as g++)
- tm
- wordcloud
- plyr
- ggplot2
- scales
- RSQLite

Unix-like environment
- Note that the bash scripts use items from bash version 4
- This project has been test on the following
- Ubuntu 13.10 "Saucy Salamander"
- OS X 10.9 "Mavericks"

Run
===

To run this program, simply clone the repository to your computer,
edit the associative array beginning on line 17 to include the apps
that you wish to compare, and then from bash, run
    $ ./main.sh
