create or replace function parse_start_year(val text)
    returns integer
    language plpgsql
    immutable strict parallel safe
as
$$
declare
    s text;
    m text;
    c integer;
begin
    if val is null then
        return null;
    end if;

    s := lower(trim(val));

    -- examples: j:1918-01-31 - drop prefix, jd:2455511 - skip julian day values
    if s ~ '^j:' then
        s := substring(s from 3);
    elsif s ~ '^jd:' then
        return null;
    end if;

    -- centuries like "C18" or "mid C17" -> middle year of the century
    if s ~ '^(early |mid |late |~)?c[0-9]{1,2}$' then
        m := substring(s from 'c([0-9]{1,2})');
        c := m::integer;
        return (c - 1) * 100 + 50;
    end if;

    -- years BC like "480 BC"
    if s ~ '^[0-9]{1,4}\s*bc$' then
        return -substring(s from '[0-9]{1,4}')::integer;
    end if;

    -- decades like "1860s" or "~1940s" -> first year
    if s ~ '^(early |mid |late |~)?[0-9]{4}s$' then
        m := substring(s from '([0-9]{4})');
        return m::integer;
    end if;

    -- full dates like "2010-03-31" or single digit month/day
    if s ~ '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$' then
        return substring(s from 1 for 4)::integer;
    end if;

    -- year and month like "2010-03" or "2010-3"
    if s ~ '^[0-9]{4}-[0-9]{1,2}$' then
        return substring(s from 1 for 4)::integer;
    end if;

    -- plain year or approximate year like "~1855"
    if s ~ '^~?[0-9]{4}$' then
        return regexp_replace(s, '[^0-9]', '', 'g')::integer;
    end if;

    -- ranges expressed with "before" or "after"
    if s ~ '^before [0-9]{4}' then
        return substring(s from '[0-9]{4}')::integer;
    end if;

    if s ~ '^after [0-9]{4}' then
        return substring(s from '[0-9]{4}')::integer;
    end if;

    -- ranges like "1894..1905" -> first year
    if s ~ '^[0-9]{4}\.{2}[0-9]{4}' then
        return substring(s from '^[0-9]{4}')::integer;
    end if;

    -- any other string containing a 4 digit year
    m := substring(s from '([0-9]{4})');
    if m is not null then
        return m::integer;
    end if;

    return null;
end;
$$;
