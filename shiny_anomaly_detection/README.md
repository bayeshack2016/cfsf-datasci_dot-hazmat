## Shiny App for DoT Hazmat Anomaly Detection
by [Jude Calvillo](http://linkd.in/vVlpXA)  
[Data Science Working Group](http://datascience.codeforsanfrancisco.org)  
[Code for San Francisco](http://www.codeforsanfrancisco.org)  

The following application is meant to help DoT execs identify those states that exhibited an anomolous number of hazmat incidents, after accounting for incident seasonality and trend, for their selected month. Thereafter, these execs can click one of these anomolous months (via the embedded map) to get more context in the form of a time-series of incidents for that state (anomolous months highlighted), as well as hazmat-related news from that state and selected month.  

### [DoT Hazmat Incident Anomaly Detector (Shiny + R + Leaflet) >>](https://judec.shinyapps.io/shiny_anomaly_detection/)

[![](www/shiny_anomalies-R_jude-calvillo_mock.png)](https://judec.shinyapps.io/shiny_anomaly_detection/)   

### August 11, 2016:
v1.6 - Just news feed left. :) Some ideas for the future.

* About 90% done now! Map interactivity complete, thereby updating anomaly plotting and UI.  
* Just need to integrate a news feed drawn from an API query (e.g. "hazmat incident/accident" + selected state + selected month). [FAROO seems great for this >>](http://www.faroo.com/hp/api/api.html)  
* For the future: Since Shiny doesn't offer a month picker widget, if we want to make the month selection quicker and easier to understand, we'll have to use straight HTML/javascript. [This jQuery UI seems perfect for the job >>](https://kidsysco.github.io/jquery-ui-month-picker/)
    - For my own notes: Pay particular attention to the Month Format and Month Parsing options...
    - https://api.jqueryui.com/datepicker/#utility-formatDate (we want to extract the month in ISO format: $.datepicker.parseDate( "yy-mm-dd", "2007-01-26" );)

* Also for the future: Some U.S. territories, like Puerto Rico, are in the DoT's hazmat incident report records, but, of course, they're not within the contiguous United States. If Dan @ DoT confirms that they'd also like to see anomolous territories in this app, we'll need a different polygons dataset (i.e. not "state" from 'maps' library).  

#### SEO tags, because, well, why not? :)

Shiny, Shiny app, anomaly detection, Leaflet, department of transportation, data science working group, code for san francisco, R, r programming, jude calvillo
