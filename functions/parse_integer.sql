create or replace function parse_integer(val text)
    returns integer as
$$
select case
           when val ~ '^[-+]?[0-9]*(\.|\,)?[0-9]+$'
               then regexp_replace(val, '\D+(\.|\,)?\w+$', '')::integer
           else null
       end
$$
    language 'sql'
    immutable
    parallel safe;
