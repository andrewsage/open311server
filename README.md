open311server
=============

Sinantra based Open311 server being developed as part of Code for Europe project for Aberdeen City Council.


Status
======

[![Build Status](https://travis-ci.org/andrewsage/open311server.svg?branch=master)](https://travis-ci.org/andrewsage/open311server)

This project is very much in a state of early development so do not expect everything to function or be implented yet.


Open311
=======

The server is built to meet the [Open311 GeoReport v2 specification](http://wiki.open311.org/GeoReport_v2).


Data
====

This server will initial be pre-populated with snapshot data extracted from Aberdeen City Council's internal systems.


The current data include is:

* Community Groups contact information within the geographic region of Aberdeen City Council

Running the app
===

`rackup -p 4567`

Replace 4567 with whatever port you wish to run the server on.

Calling the API
===

Get Services List
==

To get a list of the services use

URL
`http://<content_api_root>/services.xml`

Sample URL
`http://localhost:4567/dev/v2/services.xml`

Get Service Defintion
==

To get the service definition for a service use

URL
`http://<content_api_root>/services/<service_code>.xml`

Sample URL
`http://localhost:4567/dev/v2/services/001.xml`

Get Facilities List
==
To get a list of the facilities use

URL
`http://<content_api_root>/facilities/<category>.xml`

Sample URLs
`http://localhost:4567/dev/v1/facilities/all.xml`
`http://localhost:4567/dev/v1/facilities/community%20groups.xml`


Get Facility Details
==

To get the facility detailed information use

URL
`http://<content_api_root>/facilities/<facility_id>`

Sample URL
`http://localhost:4567/dev/v1/facilities/cg001.xml`