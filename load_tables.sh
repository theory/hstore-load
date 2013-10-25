#!/bin/bash

USCOUNT=0
CACOUNT=0
UKCOUNT=0

while getopts 'a:c:u:' opt; do
    case "$opt" in
        a)
            case "$OPTARG" in
                500|5000|50000|350000)
                    USCOUNT="$OPTARG"
                    ;;
                *)
                    echo >&2 "Unsupported American contact count; allowed: 500, 5000, 50000, or 35000"
                    exit 2
                    ;;
            esac
            ;;

        c)
            case "$OPTARG" in
                500|5000|50000)
                    CACOUNT="$OPTARG"
                    ;;
                *)
                    echo >&2 "Unsupported Canadian contact count; allowed: 500, 5000, or 50000"
                    exit 2
                    ;;
            esac
            ;;

        u)
            case "$OPTARG" in
                500)
                    UKCOUNT="$OPTARG"
                    ;;
                *)
                    echo >&2 "Unsupported UK contact count; allowed: 500"
                    exit 2
                    ;;
            esac
            ;;
    esac
done

if [ $USCOUNT != 0 ]; then
    echo Loading $USCOUNT US contacts...
    psql <<'    EOF'
        CREATE TABLE us (
            first_name TEXT,
            last_name  TEXT,
            company    TEXT,
            address    TEXT,
            city       TEXT,
            county     TEXT,
            state      TEXT,
            zip        TEXT,
            phone      TEXT,
            fax        TEXT,
            email      TEXT,
            web        TEXT
        );
    EOF
    curl http://www.briandunning.com/sample-data/us-$USCOUNT.zip > /tmp/us.zip
    unzip -p /tmp/us.zip | iconv -f MacRoman -t UTF-8 | psql -c 'COPY us FROM STDIN CSV HEADER'
    rm /tmp/us.zip
fi

if [ $CACOUNT != 0 ]; then
    echo Loading $CACOUNT CA contacts...
    psql <<'    EOF'
        CREATE TABLE ca (
            first_name TEXT,
            last_name  TEXT,
            company    TEXT,
            address    TEXT,
            city       TEXT,
            province   TEXT,
            zip        TEXT,
            phone      TEXT,
            fax        TEXT,
            email      TEXT,
            web        TEXT
        );
    EOF
    curl http://www.briandunning.com/sample-data/ca-$CACOUNT.zip > /tmp/ca.zip
    unzip -p /tmp/ca.zip | iconv -f MacRoman -t UTF-8 | psql -c 'COPY ca FROM STDIN CSV HEADER'
    rm /tmp/ca.zip
fi

if [ $UKCOUNT != 0 ]; then
    echo Loading $UKCOUNT UK contacts...
    psql <<'    EOF'
        CREATE TABLE uk (
            id         INT,
            first_name TEXT,
            last_name  TEXT,
            junk1      TEXT, 
            junk2      TEXT,
            email      TEXT,
            address    TEXT,
            city       TEXT,
            county     TEXT,
            zip        TEXT,
            company    TEXT,
            phone      TEXT,
            web        TEXT
        );
    EOF
    curl http://www.briandunning.com/sample-data/uk-$UKCOUNT.zip > /tmp/uk.zip
    unzip -p /tmp/uk.zip | iconv -f MacRoman -t UTF-8 | psql -c 'COPY uk FROM STDIN CSV'
    rm /tmp/uk.zip
fi
