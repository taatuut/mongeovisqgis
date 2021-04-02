# MongoDB geospatial visualisation in QGIS with MongoDB Connector

## Introduction

Created this repo as a proof of concept for storing geospatial data in MongoDB and visualzing in QGIS, and showcasing some of GDAL/OGR capabilities through ogr2ogr.

Using CBS data <TODO: link>

## Prerequisites

* MongoDB 4.x (just take latest) locally or your MongoDB Atlas account
* ogr2ogr from GDAL/OGR
* QGIS 3.18.1-Zürich
* MongoConnector 1.3.1 plugin for QGIS https://github.com/gospodarka-przestrzenna/MongoConnector
* jq
* Some other command line tools like cat, or alternatively chain some steps in one command to avoid using cat and intermediate files

## Installation

NOTE: The manual was created on a MacBook Pro so some commands use tools default available on MacOS (and Linux). It does not cover installing/using OS/VM or tools like Homebrew and Chocolaty.

Install the prerequisites the way you prefer. E.g. using Homebrew on MacOS or Linux to install MongoDB, MongoDB Database Tools, GDAL/OGR, jq and QGIS do:

```
brew tap mongodb/brew
brew install mongodb-community@4.4
brew install mongodb-database-tools
brew install gdal
brew install jq
brew install qgis
```

On Windows use for example Chocolatey, or download and run the relevant installers.

## Data

Central Bureau Statistiek (CBS) dataset Netherlands Municipalities 2020

<TODO: link>

## Summary

Esri Shapefile to CSV/WKT to Geojson to MongoDB with 2dsphere index then displayed in QGIS using Mongo Connector plugin

## Steps

### Esri Shapefile in EPSG:28992 to CSV/WKT in EPSG:4326

Convert from Shapefile format to CSV with geometry in WKT while transforming coordinate system from RD to WGS84.

#### Gemeenten

ogr2ogr -f CSV nl_gemeenten_2020.csv gemeente_2020_v1.shp -nlt POLYGON -lco GEOMETRY=AS_WKT -a_srs EPSG:28992 -t_srs EPSG:4326

#### Buurten

ogr2ogr -f CSV nl_buurten_2020.csv buurt_2020_v1.shp -nlt POLYGON -lco GEOMETRY=AS_WKT -a_srs EPSG:28992 -t_srs EPSG:4326

### Explode MULTIPOLYGON objects

Could optionally use -simplify or ST_Buffer

Note syntax for geometry creation:

```
ST_MakeValid(GeomFromText(WKT))
```

During this operation you might see some RTTOPE warnings like below, these can be ignored.

```
RTTOPO warning: Hole lies outside shell at or near point 5.2958321274823703 53.067692190656501
RTTOPO warning: Hole lies outside shell at or near point 5.0370504170311703 52.922703651113999
RTTOPO warning: Hole lies outside shell at or near point 4.4235497275776696 51.709474841912602
```

#### Gemeenten

Get columns from header line in CSV file:

WKT,GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area

Selecting all columns in the example below, putting the validated geometry as the last one

ogr2ogr -explodecollections -f CSV nl_gemeenten_2020.xp.csv -dialect sqlite -sql "SELECT GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM nl_gemeenten_2020" nl_gemeenten_2020.csv -nlt POLYGON -lco GEOMETRY=AS_WKT

#### Buurten

Get columns from header line in CSV file:

WKT,BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,WK_NAAM,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area

Selecting all columns in the example below, putting the validated geometry as the last one

ogr2ogr -explodecollections -f CSV nl_buurten_2020.xp.csv -dialect sqlite -sql "SELECT BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,WK_NAAM,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM nl_buurten_2020" nl_buurten_2020.csv -nlt POLYGON -lco GEOMETRY=AS_WKT

### CSV/WKT to Geojson

#### Gemeenten

```
ogr2ogr -f "geojson" /vsistdout/ -dialect sqlite -sql "SELECT GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM 'nl_gemeenten_2020.xp'" nl_gemeenten_2020.xp.csv  -a_srs EPSG:4326 > nl_gemeenten_2020.json
```

#### Buurten

```
ogr2ogr -f "geojson" /vsistdout/ -dialect sqlite -sql "SELECT BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,WK_NAAM,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM 'nl_buurten_2020.xp'" nl_buurten_2020.xp.csv  -a_srs EPSG:4326 > nl_buurten_2020.json
```

### Store in format suitable for mongoimport

#### Gemeenten

cat nl_gemeenten_2020.json | jq -c '.features[]' > nl_gemeenten_2020.jq.json

#### Buurten

cat nl_buurten_2020.json | jq -c '.features[]' > nl_buurten_2020.jq.json

### mongoimport

#### Gemeenten

```
mongoimport --uri mongodb://127.0.0.1:27017/test --drop --collection nl_gemeenten_2020 --file nl_gemeenten_2020.jq.json
```

```
2021-04-01T13:09:10.100+0200    connected to: 127.0.0.1:27017
2021-04-01T13:09:10.100+0200    dropping: test.nl_gemeenten_2020
2021-04-01T13:09:11.718+0200    imported 1142 documents
```

#### Buurten

```
mongoimport --uri mongodb://127.0.0.1:27017/test --drop --collection nl_buurten_2020 --file nl_buurten_2020.jq.json
```

```
1-04-01T18:05:10.915+0200    connected to: 127.0.0.1:27017
2021-04-01T18:05:10.916+0200    dropping: test.nl_buurten_2020
2021-04-01T18:05:13.912+0200    [##################......] test.nl_buurten_2020 136MB/174MB (78.0%)
2021-04-01T18:05:14.832+0200    [########################] test.nl_buurten_2020 174MB/174MB (100.0%)
2021-04-01T18:05:14.832+0200    imported 14855 documents
```

### geospatial index

Create 2dsphere index on geometry, using Compass or Atlas UI, or mongo shell:

#### Gemeenten

```
db.nl_gemeenten_2020.createIndex( { geometry: "2dsphere" } )
```

#### Buurten

```
db.nl_buurten_2020.createIndex( { geometry: "2dsphere" } )
```

### QGIS Mongo Connector plugin

Install Mongo Connector plugin 1.3.1

Load layer(s)

See images cbs_nl_gemeenten_2020_shp2wkt2geojson2mdb_2dsphereindex_qgis.png and cbs_nl_buurten_2020_shp2wkt2geojson2mdb_2dsphereindex_qgis.png