drop table if exists covid_latest_cases;
create table covid_latest_cases as
(WITH latest_number_cases AS
(
    SELECT
        *
    FROM
        (
            SELECT
                geo_value,
                issue,
                VALUE,
                ROW_NUMBER() OVER(PARTITION BY geo_value
            ORDER BY
                issue DESC) AS rn
            FROM
                confirmed_7dav_incidence_prop_county
        )
        t
    WHERE
        t.rn = 1
)
SELECT
    latest_number_cases.*,
    gadm_fips_encode.county,
    gadm_fips_encode.fips,
    gadm_fips_encode.state_name
FROM
    latest_number_cases
    LEFT JOIN
        gadm_fips_encode
        ON geo_value = fips);

create index on covid_latest_cases using gist (geom)";

