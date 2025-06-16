with tests(val, expected) as (
    values ('2010', 2010),
           ('2010-03', 2010),
           ('2010-03-31', 2010),
           ('~1855', 1855),
           ('1860s', 1860),
           ('~1940s', 1940),
           ('C18', 1750),
           ('C17', 1650),
           ('mid C14', 1350),
           ('before 1855', 1855),
           ('after 1823', 1823),
           ('mid C17..late C17', 1650),
           ('480 BC', -480),
           ('j:1918-01-31', 1918),
           ('jd:2455511', null)
)
select min(case when parse_start_year(val) is not distinct from expected then 1 else 0 end) as equal
from tests;
