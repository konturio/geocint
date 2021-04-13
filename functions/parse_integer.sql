create or replace function parse_integer(val text)
    returns integer as
$$
select case
           when val ~ '^\w*\.?[0-9]+$'
               then regexp_replace(val, '^\w*\.?', '')::integer
           else null
       end
$$
    language 'sql'
    immutable
    parallel safe;
