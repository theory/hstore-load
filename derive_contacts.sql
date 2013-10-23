BEGIN;

CREATE EXTENSION IF NOT EXISTS HSTORE;
CREATE TABLE contacts (
    contact_id SERIAL PRIMARY KEY,
    data       HSTORE
);

CREATE OR REPLACE FUNCTION random_string(
    string_length INT4
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    possible_chars TEXT = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    output TEXT = '';
    i INT4;
    pos INT4;
BEGIN
    FOR i IN 1..string_length LOOP
        pos := 1 + cast( random() * ( length(possible_chars) - 1) as INT4 );
        output := output || substr(possible_chars, pos, 1);
    END LOOP;
    RETURN output;
END;
$$;

CREATE OR REPLACE FUNCTION address(
    type          TEXT,
    in_city       TEXT,
    exclude_email TEXT
) RETURNS HSTORE LANGUAGE PLPGSQL AS $$
DECLARE
    adr hstore;
BEGIN
    SELECT format('[[%I, {
        "street-address" => %I,
        "locality"       => %I,
        "region"         => %I,
        "postal-code"    => %I,
        "country-name"   => %I
    }]]', type, address, city, state, zip, 'USA')::hstore
     INTO adr
     FROM us
    WHERE city = in_city
      AND email <> exclude_email
    ORDER BY random()
    LIMIT 1;
    RETURN COALESCE(adr, '{}'::hstore);
END;
$$;

CREATE OR REPLACE FUNCTION random_phone(
) RETURNS TEXT LANGUAGE plpgsql as $$
DECLARE
    formats text[] := '{
        (%s) %s-%s,
        (%s) %s-%s,
        (%s) %s-%s,
        %s-%s-%s,
        %s-%s-%s,
        %s-%s-%s,
        +1-%s-%s-%s,
        +1 (%s) %s-%s,
        %2$s-%3$s,
        %s-%s-%s x%s,
        %2$s-%3$s x%s,
        +1 (%s) %s-%s x%s
    }';
BEGIN
    RETURN format(
        formats[ floor( (random() * array_upper(formats, 1)) + 1 )::int],
        trunc(random() * (799-201) + 201),
        lpad(trunc(random() * (201-999) + 999)::text,  3, '0'),
        lpad(trunc(random() * (100-9999) + 9999)::text, 4, '0'),
        trunc(random() * (1-1024) + 1024)::text
    );
END;
$$;

SET hstore.pretty_print          = TRUE;
SET hstore.array_square_brackets = TRUE;
SET hstore.root_hash_decorated   = TRUE;

DO $$
DECLARE
    row    us;
    name   HSTORE;
    adr    HSTORE;
    tel    HSTORE;
    email  HSTORE;
    url    HSTORE;
    geo    HSTORE;
    bday   HSTORE := '{}';
    xstuff HSTORE := '{}';
    ncount INT[]  := '{0,0,0,1,1,1,1,2,2,2,3,3,4,5,6,7}';
    ntypes TEXT[] := '{mobile,cell,work,main,pager,cell,iPhone,mobile,personal,business}';
    etypes TEXT[] := '{work,personal,business}';
    utypes TEXT[] := '{blog,social,personal,work,journal,blog,blog}';
    gcount INT[]  := '{0,0,0,0,0,0,1,1,2}';
    tlds   TEXT[] := '{com,net,org,com,net,org,com,net,org,edu,edu,cc,co,fm,pm,so,io}';
    dfmts  TEXT[] := ARRAY[
        'YYYY-MM-DD',
        'YYYY-MM-DD',
        'YYYY-MM-DD',
        'YYYY-MM-DD',
        'YYYY-MM-DD',
        'YYYY-MM-DD',
        'YYYY-MM-DD"T"HH24:MI:SS',
        'YYYY-MM-DD"T"HH24:MI:SS',
        '"T"HH24:MI:SS',
        '--MM-DD',
        '--MM-DD',
        '--MM-DD',
        '---DD',
        'YYYY',
        'YYYY',
        'YYYY-MM'
    ];
BEGIN
    FOR row IN SELECT * FROM us LOOP
        name := hstore(ARRAY[
            'fn', format('%s %s', row.first_name, row.last_name),
            'org', row.company
        ]) || format(
            'n => { "given-name" => %I, "family-name" => %I }',
            row.first_name, row.last_name
        )::hstore;

        adr := format(
            '[[home, {
                "street-address" => %I,
                "locality"       => %I,
                "region"         => %I,
                "postal-code"    => %I,
                "country-name"   => %I
            }]]',
            row.address, row.city, row.state, row.zip, 'USA'
        )::hstore || CASE WHEN random() > 0.5 THEN '[]'::hstore ELSE
            address( type := 'work', in_city := row.city, exclude_email := row.email )
        END || CASE WHEN random() > 0.05 THEN  '[]'::hstore ELSE
            address( type := 'shipping', in_city := row.city, exclude_email := row.email )
        END;
        tel := format(
            '[[ home, %I ], [ mobile, %I ]]',
            row.phone, row.fax
        );

        -- Add additional numbers.
        FOR i IN 1..ncount[ floor( (random() * array_upper(ncount, 1)) + 1 )::int] LOOP
            tel := tel || format(
                '[[ %I, %I ]]',
                ntypes[ floor( (random() * array_upper(ntypes, 1)) + 1 )::int],
                random_phone()
            )::hstore;
        END LOOP;

        email := format('[[ home, %I ]]', row.email);
        FOR i IN 1..ncount[ floor( (random() * array_upper(ncount, 1)) + 1 )::int] LOOP
            email := email || format(
                '[[ %I, %I ]]',
                etypes[ floor( (random() * array_upper(etypes, 1)) + 1 )::int],
                format(
                    '%s@%s.%s',
                    random_string(trunc(random() * (4-25) + 25)::int),
                    random_string(trunc(random() * (4-25) + 25)::int),
                    tlds[ floor( (random() * array_upper(tlds, 1)) + 1 )::int]
                )
            )::hstore;
        END LOOP;
         
        url := format('[[ home, %I ]]', row.web);
        FOR i IN 1..ncount[ floor( (random() * array_upper(ncount, 1)) + 1 )::int] LOOP
            url := url || format(
                '[[ %I, %I ]]',
                utypes[ floor( (random() * array_upper(utypes, 1)) + 1 )::int],
                format(
                    'http://%s.%s',
                    random_string(trunc(random() * (4-25) + 25)::int),
                    tlds[ floor( (random() * array_upper(tlds, 1)) + 1 )::int]
                )
            )::hstore;
        END LOOP;

        geo := '[]';
        FOR i IN 1..gcount[ floor( (random() * array_upper(gcount, 1)) + 1 )::int] LOOP
            -- http://answers.yahoo.com/question/index?qid=20070729220301AA6Ct4s
            geo := geo || format(
                '[[ %s, { lat => %s, long => %s } ]]',
                etypes[ floor( (random() * array_upper(etypes, 1)) + 1 )::int],
                random() * (-124.626080 + 62.361014) - 62.361014,
                random() * (48.987386 - 18.005611) + 18.005611
            )::hstore;
        END LOOP;

        IF (geo -> 0) IS NOT NULL THEN
            geo := format('geo => %s', geo)::hstore;
        END IF;

        IF random() <= 0.1 THEN
            bday := hstore( 'bday', to_char(
                NOW() - '1 year'::INTERVAL * ROUND(RANDOM() * 100),
                dfmts[ floor( (random() * array_upper(dfmts, 1)) + 1 )::int]
            ) );
        ELSE
            bday := '{}';
        END IF;

        -- Random x- fields.
        xstuff := '{}';
        IF random() <= 0.01 THEN
            xstuff := format(
                '{ "x-smoker" => %s }',
                CASE WHEN random() < 0.7 THEN true ELSE false END
            )::hstore;
        END IF;

        IF random() <= 0.7 THEN
            xstuff := xstuff || hstore('x-twitter', row.first_name || '_' || row.last_name);
        END IF;

        IF random() <= 0.7 THEN
            xstuff := xstuff || hstore('x-facebook', row.first_name || '_' || row.last_name);
        END IF;

        IF random() <= 0.4 THEN
            xstuff := xstuff || hstore('x-aim', row.first_name || '_' || row.last_name);
        END IF;

        IF random() <= 0.1 THEN
            xstuff := xstuff || hstore('x-jabber', row.first_name || '_' || row.last_name);
        END IF;

        IF random() <= 0.2 THEN
            xstuff := xstuff || hstore('x-google-talk', row.first_name || '_' || row.last_name);
        END IF;

        IF random() <= 0.2 THEN
            xstuff := xstuff || hstore('x-skype', row.first_name || '_' || row.last_name);
        END IF;

        IF random() <= 0.2 THEN
            xstuff := xstuff || hstore(
                'x-anniversary',
                to_char(
                    NOW() - '1 year'::INTERVAL * ROUND(RANDOM() * 55),
                    dfmts[ floor( (random() * array_upper(dfmts, 1)) + 1 )::int]
            ) );
        END IF;

        INSERT INTO contacts (data) VALUES (
            name
            || format('adr => %s', adr)::hstore
            || format('tel => %s', tel)::hstore
            || format('url => %s', url)::hstore
            || format('email => %s', email)::hstore
            || geo || bday || xstuff
        );
    END LOOP;
END;
$$;

COMMIT;
