#!/bin/bash

psql <<EOF
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

curl http://www.briandunning.com/sample-data/350000.zip | gzcat | iconv -f MacRoman -t UTF-8 | psql -d contacts -c 'COPY us FROM STDIN CSV HEADER'
curl http://www.briandunning.com/sample-data/50000-canada.zip | gzcat | iconv -f MacRoman -t UTF-8 | psql -d contacts -c 'COPY ca FROM STDIN CSV HEADER'
curl http://www.briandunning.com/sample-data/500-uk.zip | gzcat | iconv -f MacRoman -t UTF-8 | psql -d contacts -c 'COPY uk FROM STDIN CSV'
