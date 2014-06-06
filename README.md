open311server
=============

Sinantra based Open311 server being developed as part of Code for Europe project for Aberdeen City Council.


Status
======

[![Build Status](https://travis-ci.org/andrewsage/open311server.svg?branch=master)](https://travis-ci.org/andrewsage/open311server)

This project is very much in a state of early development so do not expect everything to function or be implemented yet.


Open311
=======

The server is built to meet the [Open311 GeoReport v2 specification](http://wiki.open311.org/GeoReport_v2) and [Open311 Inquiry v1 specification](http://wiki.open311.org/Inquiry_v1).


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

To get a list of the services use

`http://localhost:4567/dev/v2/services.xml`


To get the service definition for a service use (replacing 001 with the service_code for the service)

`http://localhost:4567/dev/v2/services/001.xml`
