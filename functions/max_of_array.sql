create or replace function max_of_array(anyarray)
    returns integer
    language sql
as
$$
select max(elements) from unnest($1) elements
$$;