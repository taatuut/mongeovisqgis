# MongoDB geospatial visualisation in QGIS with MongoDB Connector

## Introduction

I created this repository as a proof of concept for storing geospatial data in MongoDB and visualzing in QGIS, and showcasing some of GDAL/OGR capabilities through ogr2ogr.

## Prerequisites

* MongoDB 4.x (just take latest) locally or your MongoDB Atlas account
* ogr2ogr, part of GDAL/OGR
* Latest QGIS stable release, with PyMongo installed for QGIS (see installation) 
* MongoConnector 1.3.1 or newer plugin for QGIS https://github.com/gospodarka-przestrzenna/MongoConnector
* `jq`
* Some other command line tools like `cat`, or alternatively chain some steps in one command to avoid both using `cat` and creating intermediate files

## Installation

NOTE: This proof of concept was created on a MacBook Pro so some commands use tools default available on MacOS (and Linux). The readme does not cover extensively installing/using OS/VM, or tools like Homebrew and Chocolatey.

For a quick setup based on the latest known working defaults on MacOs you can use the install script. You can then skip to [QGIS Mongo Connector plugin|https://github.com/taatuut/mongeovisqgis#qgis-mongo-connector-plugin]
```
./install.sh
```

Install the prerequisites the way you prefer. E.g. using Homebrew on MacOS or Linux to install MongoDB, MongoDB Database Tools, GDAL/OGR, jq and QGIS:

```
brew tap mongodb/brew
brew install mongodb-community@4.4
brew install mongodb-database-tools
brew install gdal
brew install jq
brew install qgis
```

On Windows use for example Chocolatey, or download and run the relevant installers.

QGIS comes with its own Python installation (version 3.8 for QGIS 3.18.1-Zürich). To install PyMongo open a terminal to find the QGIS installation folder first. Then use that path to find the `bin` folder where you will find the Python executable. Use that executable to install PyMongo for QGIS. 

### Install PyMongo for QGIS

In QGIS open the Python Console and run following code to check for the QGIS installation folder:

```
import sys
print(sys.executable)
```

This gives back a path to the executable like:

```
/Applications/QGIS.app/Contents/MacOS/QGIS
```

<img width="762" alt="QGIS_python_console" src="https://user-images.githubusercontent.com/2260360/113404589-b4150f80-93a8-11eb-853e-963a19b69ea8.png">

In a terminal go the `bin` folder using the path to the executable by replacing `QGIS` with `bin`. Then list the folder contents to find the Python executable:

```
cd /Applications/QGIS.app/Contents/MacOS/bin/
ls -al python*
```

Gives back something like:

```
python3 -> python3.8
python3-config -> python3.8-config
python3.8
python3.8-config
```

Install PyMongo by selecting the appropriate Python executable (or alias):

```
./python3.8 -m pip install pymongo
```

## Data

This example uses data from Dutch Central Bureau Statistiek (CBS), specifically the Wijk- en Buurtkaart 2020. This can be found at https://www.cbs.nl/nl-nl/dossier/nederland-regionaal/geografische-data/wijk-en-buurtkaart-2020, with direct download at https://www.cbs.nl/-/media/cbs/dossiers/nederland-regionaal/wijk-en-buurtstatistieken/wijkbuurtkaart_2020_v2.zip. Direct link may get broken, check the homepage if so.

Feel free to use any dataset you like, startpoint here is Esri Shapefiles. 

Unzip the file `wijkbuurtkaart_2020_v2.zip` at a location of your choice.

## Summary

Convert the CBS data from Esri Shapefile to CSV/WKT with CRS change, then explode MULTIxxx geometries into separate parts, convert from CSV/WKT to Geojson, prepare format for mongoimport using jq, load into MongoDB, create `2dsphere` index, then display in QGIS using Mongo Connector plugin and do your geospatial things there.

## Steps

### Esri Shapefile in EPSG:28992 to CSV/WKT in EPSG:4326

Convert from Shapefile format to CSV with geometry in WKT while transforming coordinate system from RD to WGS84.

_**Gemeenten**_

```
ogr2ogr -f CSV nl_gemeenten_2020.csv gemeente_2020_v2.shp -nlt POLYGON -lco GEOMETRY=AS_WKT -a_srs EPSG:28992 -t_srs EPSG:4326
```

_**Buurten**_

```
ogr2ogr -f CSV nl_buurten_2020.csv buurt_2020_v2.shp -nlt POLYGON -lco GEOMETRY=AS_WKT -a_srs EPSG:28992 -t_srs EPSG:4326
```

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

_**Gemeenten**_

Get columns from header line in CSV file:

```
WKT,GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area
```

Selecting all columns in the example below, putting the validated geometry as the last one:

```
ogr2ogr -explodecollections -f CSV nl_gemeenten_2020.xp.csv -dialect sqlite -sql "SELECT GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM nl_gemeenten_2020" nl_gemeenten_2020.csv -nlt POLYGON -lco GEOMETRY=AS_WKT
```

_**Buurten**_

Get columns from header line in CSV file:

```
WKT,BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area
```

Selecting all columns in the example below, putting the validated geometry as the last one:

```
ogr2ogr -explodecollections -f CSV nl_buurten_2020.xp.csv -dialect sqlite -sql "SELECT BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM nl_buurten_2020" nl_buurten_2020.csv -nlt POLYGON -lco GEOMETRY=AS_WKT
```

### CSV/WKT to Geojson

_**Gemeenten**_

```
ogr2ogr -f "geojson" /vsistdout/ -dialect sqlite -sql "SELECT GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM 'nl_gemeenten_2020.xp'" nl_gemeenten_2020.xp.csv  -a_srs EPSG:4326 > nl_gemeenten_2020.json
```

_**Buurten**_

```
ogr2ogr -f "geojson" /vsistdout/ -dialect sqlite -sql "SELECT BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM 'nl_buurten_2020.xp'" nl_buurten_2020.xp.csv  -a_srs EPSG:4326 > nl_buurten_2020.json
```

### Store in format suitable for mongoimport

_**Gemeenten**_

```
cat nl_gemeenten_2020.json | jq -c '.features[]' > nl_gemeenten_2020.jq.json
```

_**Buurten**_

```
cat nl_buurten_2020.json | jq -c '.features[]' > nl_buurten_2020.jq.json
```

### mongoimport

_**Gemeenten**_

```
mongoimport --uri mongodb://127.0.0.1:27017/test --drop --collection nl_gemeenten_2020 --file nl_gemeenten_2020.jq.json
```

```
2021-04-01T13:09:10.100+0200    connected to: 127.0.0.1:27017
2021-04-01T13:09:10.100+0200    dropping: test.nl_gemeenten_2020
2021-04-01T13:09:11.718+0200    imported 1142 documents
```

_**Buurten**_

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

Create `2dsphere` index on geometry, through the wizard in Compass or Atlas UI, or using MQL in any of the available tools including mongo shell. Note that the spatial index is not required, but it will speed up operations, especially at larger data volumes.

_**Gemeenten**_

```
db.nl_gemeenten_2020.createIndex( { geometry: "2dsphere" } )
```

_**Buurten**_

```
db.nl_buurten_2020.createIndex( { geometry: "2dsphere" } )
```

### QGIS Mongo Connector plugin

**Open QGIS**

**Install Mongo Connector plugin 1.3.1**

<img width="278" alt="QGIS_plugins" src="https://user-images.githubusercontent.com/2260360/113393936-ab680d80-9397-11eb-892f-963ca0e20ba9.png">

<img width="987" alt="QGIS_plugins_mongoconnector" src="https://user-images.githubusercontent.com/2260360/113393956-b4f17580-9397-11eb-98ef-e62f708e0739.png">

**Add mongodb layer(s)**

In menu Database select Mongo Connector and then Connect

<img width="325" alt="MongoDBConnector_Menu" src="https://user-images.githubusercontent.com/2260360/113393986-c20e6480-9397-11eb-85cd-76d747d1976c.png">

A window will open with default connectionstring for localhost. Adapt the connectionstring as needed. Click [ Refresh Databases ] and select the database that has the collections with the spatial data. Then select the relevant collection and clik 'geojson geometry' to add the layer. 

<img width="340" alt="MongoDBConnector_Widget" src="https://user-images.githubusercontent.com/2260360/113394003-c9ce0900-9397-11eb-88c2-5f822c6a9895.png">

**Explore the data**

<img width="1792" alt="cbs_nl_gemeenten_2020_shp2wkt2geojson2mdb_2dsphereindex_qgis" src="https://user-images.githubusercontent.com/2260360/113394042-de120600-9397-11eb-8253-2aaa839b68a5.png">

<img width="1904" alt="cbs_nl_buurten_2020_shp2wkt2geojson2mdb_2dsphereindex_qgis" src="https://user-images.githubusercontent.com/2260360/113394104-f5e98a00-9397-11eb-9b0a-0a49a58aa2ef.png">

Tip: In the map you also see a nice OpenStreetMap (OSM) layer in the background. For that I used the QuickMapServices plugin for QGIS, that comes with a collection of easy to add basemaps.
