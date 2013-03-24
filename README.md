##Famous taiwanese people in the news.

This fun project is here to visualize the passion (really, the number of article) about some famous taiwanese people. The list of people is on [wikipedia](http://en.wikipedia.org/wiki/List_of_Taiwanese_people).

The project in two parts.

##The crawler
For the moment I only crawled the appledaily (蘋果日報), the crawler is in the folder crawler. It is built using node.js and store the data with mongoDB. The code to access the DB (the dao) is in the folder mongo.

##The visualization
The server and the pages are in the folder app. The server uses node.js and express. The visualization uses the awesome library [d3](http://d3js.org/) and basic html/css.

##How do I build this ?
This project is not really intended to be built and used by other people. You'll want to change the database configuration (in mongo/mongoConfig.coffee) and probably some other things. Maybe I'll make that easier if the future (unlikely).

##Why ?
This project is only for fun and for the sake of learning new things. Here, it was node.js and mongo (and refresh my memory about d3). This is not a great project but [ship early !](http://fuckitship.it/).

##And later ?
There are tons of things to improve, here are some.
* The crawler is slow, tweak node to open more connections.
* Sometimes the crawler hangs, add a timeout and a retry process.
* The database is not super efficient (count() in mongo is super slow).
* Put the 'cache' in the dao and impove it.
* Make the app crawl new articles every days.
* Find better color for the graph.
* Make the site less ugly.


