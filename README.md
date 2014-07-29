open311server
=============

[Sinatra](http://www.sinatrarb.com) based Open311 server being developed as part of Code for Europe project for Aberdeen City Council.


Status
======

[![Build Status](https://travis-ci.org/andrewsage/open311server.svg?branch=master)](https://travis-ci.org/andrewsage/open311server)

This project is very much in a state of early development so do not expect everything to function or be implemented yet.

There is a demo version of the server running at [http://open311server.herokuapp.com](http://open311server.herokuapp.com)


Open311
=======

The server is built to meet the [Open311 GeoReport v2 specification](http://wiki.open311.org/GeoReport_v2) and [Open311 Inquiry v1 specification](http://wiki.open311.org/Inquiry_v1).

Inquiry v1
----
The Inquiry v1 specificiation was developed by NYC for their needs. In order to make the facility information more relevant for the UK some additional fields have been added as follows:

* postcode - the post code of the Facility
* phone - the phone number of the Facility
* contact - name of a contact for the Facility
* email - email address for the Facility
* web - web address for the Facility
* updated - the date and time that the information was last updated

Data
====

This server will initial be pre-populated with snapshot data extracted from Aberdeen City Council's internal systems.


The current data include is:

* Community Groups contact information within the geographic region of Aberdeen City Council (note this data has not been cleaned and may appear corrupt for some results)
* Public car parks within the geographic region of Aberdeen City Council
* Schools within the geographic region of Aberdeen City Council

Scrappers
====

Some data scrappers have been created for extracting some of the data from existing websites.

The current scrappers are for:

* Schools within the geographic region of Aberdeen City Council [http://www.aberdeencity.gov.uk/education_learning/schools/scc_schools_list.asp](http://www.aberdeencity.gov.uk/education_learning/schools/scc_schools_list.asp)

Running the app
===

`rackup -p 4567`

Replace 4567 with whatever port you wish to run the server on.

Calling the API
===

Get Services List
----

To get a list of the services use

URL

`http://<content_api_root>/services.xml`

Sample URL

`http://localhost:4567/dev/v2/services.xml`

Get Service Defintion
----

To get the service definition for a service use

URL

`http://<content_api_root>/services/<service_code>.xml`

Sample URL

`http://localhost:4567/dev/v2/services/001.xml`

Get Facilities List
----
To get a list of the facilities use

URL

`http://<content_api_root>/facilities/<category>.xml`

Sample URLs

`http://localhost:4567/dev/v1/facilities/all.xml`
`http://localhost:4567/dev/v1/facilities/community%20groups.xml`


Get Facility Details
----

To get the facility detailed information use

URL

`http://<content_api_root>/facilities/<facility_id>`

Sample URL

`http://localhost:4567/dev/v1/facilities/cg001.xml`