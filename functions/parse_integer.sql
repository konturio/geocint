create or replace function parse_integer(val text)
    returns integer as
$$
select case
           when val ~ '^[-+]?[012]?[0-9]{1,8}$'
               then regexp_replace(val, '^\w*\.?', '')::integer
           else null
       end
$$
    language 'sql'
    immutable
    parallel safe;
