create or replace function max_of_array(anyarray)
    returns integer
    language sql
as
$$
select max(elements) FROM unnest($1) elements
$$;