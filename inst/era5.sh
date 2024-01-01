#!/bin/bash

## status indicates whether any files needed to be retrieved
status=0

## ERA5 
function retrieve_era5 () {
    date=$1
    
    if ! [ -e era5_${date}_0600_ml.nc ] ; then
	status=1
	( env PYTHONPATH=${PYTHONPATH}:${HOME}/mars/lib ${HOME}/mars/bin/mars <<EOF 
RETRIEVE,
    CLASS      = EA,
    TYPE       = FC,
    STREAM     = OPER,
    EXPVER     = 0001,
    REPRES     = SH,
    LEVTYPE    = ML,
    LEVELIST   = 100/101/102/103/104/105/106/107/108/109/110/111/112/113/114/115/116/117/118/119/120/121/122/123/124/125/126/127/128/129/130/131/132/133/134/135/136/137,
    PARAM      = 75/76/77/129/130/131/132/133/135/138/152/155/203/246/247/248/235001/235002/235003/235004/235005/235006/235007/235008/235009/235010/235011/235012/235013/235014,
    TIME       = 0600,
    STEP       = 3/6/9/12,
    DOMAIN     = G,
    RESOL      = AUTO,
    AREA       = 45/-180/-45/179.75,
    GRID       = 0.125/0.125,
    PADDING    = 0,
    EXPECT     = ANY,
    DATE       = ${date},
    FORMAT     = netcdf,
    TARGET     = era5_${date}_0600_ml.nc
EOF
	) &
	sleep 20
    fi

    if ! [ -e era5_${date}_1800_ml.nc ] ; then
	status=1
	( env PYTHONPATH=${PYTHONPATH}:${HOME}/mars/lib ${HOME}/mars/bin/mars <<EOF 
RETRIEVE,
    CLASS      = EA,
    TYPE       = FC,
    STREAM     = OPER,
    EXPVER     = 0001,
    REPRES     = SH,
    LEVTYPE    = ML,
    LEVELIST   = 100/101/102/103/104/105/106/107/108/109/110/111/112/113/114/115/116/117/118/119/120/121/122/123/124/125/126/127/128/129/130/131/132/133/134/135/136/137,
    PARAM      = 75/76/77/129/130/131/132/133/135/138/152/155/203/246/247/248/235001/235002/235003/235004/235005/235006/235007/235008/235009/235010/235011/235012/235013/235014,
    TIME       = 1800,
    STEP       = 3/6/9/12,
    DOMAIN     = G,
    RESOL      = AUTO,
    AREA       = 45/-180/-45/179.75,
    GRID       = 0.125/0.125,
    PADDING    = 0,
    EXPECT     = ANY,
    DATE       = ${date},
    FORMAT     = netcdf,
    TARGET     = era5_${date}_1800_ml.nc
EOF
	) &
	sleep 20
    fi

    if ! [ -e era5_${date}_0600_pl.nc ] ; then
	status=1
	( env PYTHONPATH=${PYTHONPATH}:${HOME}/mars/lib ${HOME}/mars/bin/mars <<EOF 
RETRIEVE,
    CLASS      = EA,
    TYPE       = FC,
    STREAM     = OPER,
    EXPVER     = 0001,
    REPRES     = SH,
    LEVELIST   = 500/700,
    LEVTYPE    = PL,
    PARAM      = 135.128,
    TIME       = 0600,
    STEP       = 3/6/9/12,
    DOMAIN     = G,
    RESOL      = AUTO,
    AREA       = 45/-180/-45/179.75,
    GRID       = 0.125/0.125,
    PADDING    = 0,
    EXPECT     = ANY,
    DATE       = ${date},
    FORMAT     = netcdf,
    TARGET     = era5_${date}_0600_pl.nc
EOF
	) &
	sleep 20
    fi

    if ! [ -e era5_${date}_1800_pl.nc ] ; then
	status=1
	( env PYTHONPATH=${PYTHONPATH}:${HOME}/mars/lib ${HOME}/mars/bin/mars <<EOF 
RETRIEVE,
    CLASS      = EA,
    TYPE       = FC,
    STREAM     = OPER,
    EXPVER     = 0001,
    REPRES     = SH,
    LEVELIST   = 500/700,
    LEVTYPE    = PL,
    PARAM      = 135.128,
    TIME       = 1800,
    STEP       = 3/6/9/12,
    DOMAIN     = G,
    RESOL      = AUTO,
    AREA       = 45/-180/-45/179.75,
    GRID       = 0.125/0.125,
    PADDING    = 0,
    EXPECT     = ANY,
    DATE       = ${date},
    FORMAT     = netcdf,
    TARGET     = era5_${date}_1800_pl.nc
EOF
	) &
	sleep 20
    fi

    if ! [ -e era5_${date}_0600_sf.nc ] ; then
	status=1
	( env PYTHONPATH=${PYTHONPATH}:${HOME}/mars/lib ${HOME}/mars/bin/mars <<EOF 
RETRIEVE,
    CLASS      = EA,
    TYPE       = FC,
    STREAM     = OPER,
    EXPVER     = 0001,
    REPRES     = SH,
    LEVTYPE    = SF,
    PARAM      = 1.228/3.228/7.228/8.128/8.228/9.128/9.228/10.228/11.228/12.228/13.228/14.228/15.128/15.228/16.128/16.228/17.128/17.228/18.128/18.228/19.228/21.228/22.228/23.228/24.228/26.128/29.228/31.128/32.128/33.128/34.128/35.128/36.128/37.128/38.128/39.128/40.128/41.128/42.128/44.128/45.128/49.128/50.128/53.162/54.162/57.128/59.128/59.162/60.162/61.162/62.162/63.162/64.162/65.162/66.128/66.162/67.128/67.162/68.162/69.162/70.162/71.162/72.162/73.162/74.162/75.162/76.162/77.162/78.128/78.162/79.128/79.162/80.162/81.162/82.162/83.162/84.162/85.162/86.162/87.162/88.162/88.228/89.162/89.228/90.162/90.228/91.162/129.128/129.228/130.228/131.228/132.228/134.128/136.128/137.128/139.128/141.128/142.128/143.128/144.128/145.128/146.128/147.128/148.128/151.128/159.128/164.128/165.128/166.128/167.128/168.128/169.128/170.128/172.128/175.128/176.128/177.128/178.128/179.128/180.128/181.128/182.128/183.128/186.128/187.128/188.128/195.128/196.128/197.128/198.128/201.128/202.128/205.128/206.128/208.128/209.128/210.128/211.128/212.128/213.128/217.228/218.228/219.228/220.228/221.228/226.228/227.228/228.128/229.128/230.128/231.128/232.128/235.128/236.128/238.128/239.128/240.128/243.128/244.128/245.128/246.228/247.228/251.228/260015/260121/260123,
    TIME       = 0600,
    STEP       = 3/6/9/12,
    DOMAIN     = G,
    RESOL      = AUTO,
    AREA       = 45/-180/-45/179.75,
    GRID       = 0.125/0.125,
    PADDING    = 0,
    EXPECT     = ANY,
    DATE       = ${date},
    FORMAT     = netcdf,
    TARGET     = era5_${date}_0600_sf.nc
EOF
	) &
	sleep 20
    fi

    if ! [ -e era5_${date}_1800_sf.nc ] ; then
	status=1
	( env PYTHONPATH=${PYTHONPATH}:${HOME}/mars/lib ${HOME}/mars/bin/mars <<EOF 
RETRIEVE,
    CLASS      = EA,
    TYPE       = FC,
    STREAM     = OPER,
    EXPVER     = 0001,
    REPRES     = SH,
    LEVTYPE    = SF,
    PARAM      = 1.228/3.228/7.228/8.128/8.228/9.128/9.228/10.228/11.228/12.228/13.228/14.228/15.128/15.228/16.128/16.228/17.128/17.228/18.128/18.228/19.228/21.228/22.228/23.228/24.228/26.128/29.228/31.128/32.128/33.128/34.128/35.128/36.128/37.128/38.128/39.128/40.128/41.128/42.128/44.128/45.128/49.128/50.128/53.162/54.162/57.128/59.128/59.162/60.162/61.162/62.162/63.162/64.162/65.162/66.128/66.162/67.128/67.162/68.162/69.162/70.162/71.162/72.162/73.162/74.162/75.162/76.162/77.162/78.128/78.162/79.128/79.162/80.162/81.162/82.162/83.162/84.162/85.162/86.162/87.162/88.162/88.228/89.162/89.228/90.162/90.228/91.162/129.128/129.228/130.228/131.228/132.228/134.128/136.128/137.128/139.128/141.128/142.128/143.128/144.128/145.128/146.128/147.128/148.128/151.128/159.128/164.128/165.128/166.128/167.128/168.128/169.128/170.128/172.128/175.128/176.128/177.128/178.128/179.128/180.128/181.128/182.128/183.128/186.128/187.128/188.128/195.128/196.128/197.128/198.128/201.128/202.128/205.128/206.128/208.128/209.128/210.128/211.128/212.128/213.128/217.228/218.228/219.228/220.228/221.228/226.228/227.228/228.128/229.128/230.128/231.128/232.128/235.128/236.128/238.128/239.128/240.128/243.128/244.128/245.128/246.228/247.228/251.228/260015/260121/260123,
    TIME       = 1800,
    STEP       = 3/6/9/12,
    DOMAIN     = G,
    RESOL      = AUTO,
    AREA       = 45/-180/-45/179.75,
    GRID       = 0.125/0.125,
    PADDING    = 0,
    EXPECT     = ANY,
    DATE       = ${date},
    FORMAT     = netcdf,
    TARGET     = era5_${date}_1800_sf.nc
EOF
	) &
	sleep 20
    fi
}

## Ideally, we would retrieve 2008-10-15 to 2008-11-14 (VOCALS-REx),
## but since ERA5 has only processed back to 2010, we'll settle for
## 2017
day=15
while [ $day -le 31 ] ; do
    date=`printf 200810%02d ${day}`
    retrieve_era5 $date 
    day=$(($day + 1))
done

day=1
while [ $day -le 14 ] ; do
    date=`printf 200811%02d ${day}`
    retrieve_era5 $date 
    day=$(($day + 1))
done

wait
exit $status
