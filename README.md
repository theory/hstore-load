hstore-load
===========

Load and test Nested HSTORE data

Synopsis
--------

    export PGDATABASE=contacts
    createdb $PGDATABASE
    ./load_tables.sh -a 500
    psql -f derive_contacts.sql


