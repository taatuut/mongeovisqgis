#!/bin/bash

# You probably already have mongodb + tools installed
#brew tap mongodb/brew
#brew install mongodb-community@4.4
#brew install mongodb-database-tools

brew install gdal
brew install jq
brew install qgis
# we're using wget to get the map
brew install wget

/Applications/QGIS.app/Contents/MacOS/bin/python3 -m pip install pymongo
wget -O maps.zip https://www.cbs.nl/-/media/cbs/dossiers/nederland-regionaal/wijk-en-buurtstatistieken/wijkbuurtkaart_2020_v2.zip
unzip maps.zip
mv Wijk*/ maps/
cd maps
ogr2ogr -f CSV nl_gemeenten_2020.csv gemeente_2020_v*.shp -nlt POLYGON -lco GEOMETRY=AS_WKT -a_srs EPSG:28992 -t_srs EPSG:4326
ogr2ogr -f CSV nl_buurten_2020.csv buurt_2020_v*.shp -nlt POLYGON -lco GEOMETRY=AS_WKT -a_srs EPSG:28992 -t_srs EPSG:4326
ogr2ogr -explodecollections -f CSV nl_gemeenten_2020.xp.csv -dialect sqlite -sql "SELECT GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM nl_gemeenten_2020" nl_gemeenten_2020.csv -nlt POLYGON -lco GEOMETRY=AS_WKT
ogr2ogr -explodecollections -f CSV nl_buurten_2020.xp.csv -dialect sqlite -sql "SELECT BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM nl_buurten_2020" nl_buurten_2020.csv -nlt POLYGON -lco GEOMETRY=AS_WKT
ogr2ogr -f "geojson" /vsistdout/ -dialect sqlite -sql "SELECT GM_CODE,JRSTATCODE,GM_NAAM,H2O,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM 'nl_gemeenten_2020.xp'" nl_gemeenten_2020.xp.csv  -a_srs EPSG:4326 > nl_gemeenten_2020.json
ogr2ogr -f "geojson" /vsistdout/ -dialect sqlite -sql "SELECT BU_CODE,JRSTATCODE,BU_NAAM,WK_CODE,GM_CODE,GM_NAAM,IND_WBI,H2O,POSTCODE,DEK_PERC,OAD,STED,BEV_DICHTH,AANT_INW,AANT_MAN,AANT_VROUW,P_00_14_JR,P_15_24_JR,P_25_44_JR,P_45_64_JR,P_65_EO_JR,P_ONGEHUWD,P_GEHUWD,P_GESCHEID,P_VERWEDUW,AANTAL_HH,P_EENP_HH,P_HH_Z_K,P_HH_M_K,GEM_HH_GR,P_WEST_AL,P_N_W_AL,P_MAROKKO,P_ANT_ARU,P_SURINAM,P_TURKIJE,P_OVER_NW,OPP_TOT,OPP_LAND,OPP_WATER,Shape_Leng,Shape_Area,ST_MakeValid(GeomFromText(WKT)) FROM 'nl_buurten_2020.xp'" nl_buurten_2020.xp.csv  -a_srs EPSG:4326 > nl_buurten_2020.json
cat nl_gemeenten_2020.json | jq -c '.features[]' > nl_gemeenten_2020.jq.json
cat nl_buurten_2020.json | jq -c '.features[]' > nl_buurten_2020.jq.json
mongoimport --uri mongodb://127.0.0.1:27017/test --drop --collection nl_gemeenten_2020 --file nl_gemeenten_2020.jq.json
mongoimport --uri mongodb://127.0.0.1:27017/test --drop --collection nl_buurten_2020 --file nl_buurten_2020.jq.json
mongo  mongodb://127.0.0.1:27017/test --eval 'db.nl_gemeenten_2020.createIndex( { geometry: "2dsphere" } )'
mongo  mongodb://127.0.0.1:27017/test --eval 'db.nl_buurten_2020.createIndex( { geometry: "2dsphere" } )'  
