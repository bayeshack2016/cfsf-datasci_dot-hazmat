# cfsf-datasci_dot-hazmat

Data Science Working Group @ Code for SF (CFA) : App for DoT Prompt 1 (Hazmat Incidents)

#### Synopsis:
In order to address the Department of Transportation prompt, the team has developed two tools which assist in detecting and predicting traffic related incidents.

The first tool is a model to predict the number of incidents that involved hazardous materials for a month in a particular state. The model was developed taking into account various publicly available data sources such as records on land development applications, employment data in energy related sectors, oil prices, and more.

#### Data sources used:
The website of the bureau of land management for oil and gas statistics:
http://www.blm.gov/wo/st/en/prog/energy/oil_and_gas/statistics.html
The bureau of labor statistics for sector related employment:
bls.gov
The office of hazardous material safety incident database:
https://hazmatonline.phmsa.dot.gov/IncidentReportsSearch/IncrSearch.aspx

Further details can be found in the markdown document which describes the model building process. [RMarkdown Report](https://github.com/bayeshack2016/cfsf-datasci_dot-hazmat/blob/master/random_forest_v2.md)

The model projection and actual data by state can be accessed and visualized through an interactive front-end tool.

The second tool monitors the number of fatalities as well as the number of reported incidences involving hazardous materials and flags breakouts in trends using an anomaly detection algorithm.  This can be used in real time for early detection of accumulations of incidents and accidents to trigger a fast investigation on the underlying problem.

#### Outlook:
Both tools have proven basic capabilities and can be further enhanced through a more thorough development. For instance, predictive capability of the model can be improved through taking into account further detailed and more granular data sources as they become available. 

