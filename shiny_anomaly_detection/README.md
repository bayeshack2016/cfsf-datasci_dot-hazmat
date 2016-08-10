## Shiny App for DoT Hazmat Anomaly Detection
by [Jude Calvillo](http://linkd.in/vVlpXA)  
[Data Science Working Group](http://datascience.codeforsanfrancisco.org)  
[Code for San Francisco](http://www.codeforsanfrancisco.org)  

This isn't done yet, but in case my Data Science Working Group, Code for SF, and/or Bayes Hack friends would ocassionally like to see my progress, go here:  

### [Shiny + R DoT Anomaly Detector >>](https://judec.shinyapps.io/shiny_anomaly_detection/)

### Latest Update: 8/9/16 

v1.4 - Major update: Anomalies, Summ Stats, Style and more...

* UI's tableOutput now reactive and includes summary stats.
* I'd like to now include a news feed in the area formerly dedicated to summary stats, one that shows hazmat-related news stories from the anomolous states for the selected month. :)
* Applied a bootstrap theme to pretty things up a bit, BUT it's hurt the readability of the date input.
* Apparently, there's no such thing as a purely by "month" date input widget, which makes date selection really confusing. Thus, I'll soon be developing a slider solution for month selection.
* Anomolous state-specific and date-range specific timeline plot, with anomalies highlighted, now reactive to user input.
* Leaflet map rendering now working, but polygon opacity is still funky; it should only color in the anomalous states. Working on it.
* Still need to 'interact' with user's Leaflet map selection for specifying state to plot and summarize.
* Using basic drop down for testing reactive state-specific timeline plotting until I get leaflet to interact, but there seems to be a bug: only some states produce a plot. Hopefully, that's just due to some mismatch between the drop down's state.abb values and the State values in dat/dat2 (main data frames).

#### SEO tags, because, well, why not? :)

Shiny, Shiny app, anomaly detection, Leaflet, department of transportation, data science working group, code for san francisco, R, r programming, jude calvillo
