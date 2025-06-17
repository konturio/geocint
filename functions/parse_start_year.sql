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

    -- eight digit numbers like 01012000 or 19991231
    if s ~ '^[0-9]{8}$' then
        m := substring(s from 5 for 4);
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        m := substring(s from 1 for 4);
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    -- fourteen digit timestamps like 19930709000000
    if s ~ '^[0-9]{14}$' then
        m := substring(s from 1 for 4);
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    -- centuries like "C18" or "mid C17" -> middle year of the century
    if s ~ '^(early |mid |late |~)?c[0-9]{1,2}$' then
        m := substring(s from 'c([0-9]{1,2})');
        c := m::integer;
        return (c - 1) * 100 + 50;
    end if;

    -- centuries written as "12th century" or "12 century"
    if s ~ '^[0-9]{1,2}(st|nd|rd|th)?( |\.)?century$' then
        m := substring(s from '([0-9]{1,2})');
        c := m::integer;
        return (c - 1) * 100 + 50;
    end if;

    -- century ranges like "mid c17..late c17" -> use the first century
    if s ~ 'c[0-9]{1,2}\.{2}' then
        m := substring(s from 'c([0-9]{1,2})');
        c := m::integer;
        return (c - 1) * 100 + 50;
    end if;

    -- circa year like "c.1300" or "ca 1300"
    if s ~ '^ca?\.?\s*[0-9]{3,4}$' then
        m := substring(s from '[0-9]{3,4}');
        return m::integer;
    end if;

    -- years BC like "480 BC" or "480 BCE"
    if s ~ '^[0-9]{1,4}\s*bc(e)?$' then
        return -substring(s from '[0-9]{1,4}')::integer;
    end if;

    -- decades like "1860s" or "~1940s" -> first year
    if s ~ '^(early |mid |late |~)?[0-9]{4}s$' then
        m := substring(s from '([0-9]{4})');
        return m::integer;
    end if;

    -- full dates like "2010-03-31" or single digit month/day
    if s ~ '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$' then
        m := substring(s from 1 for 4);
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    -- year and month like "2010-03" or "2010-3"
    if s ~ '^[0-9]{4}-[0-9]{1,2}$' then
        m := substring(s from 1 for 4);
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    -- plain year or approximate year like "~1855"
    if s ~ '^~?[0-9]{4}$' then
        m := regexp_replace(s, '[^0-9]', '', 'g');
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    -- ranges expressed with "before" or "after" or "on or before"/"on or after"
    if s ~ '^(on or )?before [0-9]{1,4}\s*bc(e)?$' then
        m := substring(s from '[0-9]{1,4}');
        return -m::integer;
    elsif s ~ '^(on or )?before [0-9]{4}' then
        m := substring(s from '([0-9]{4})');
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    if s ~ '^(on or )?after [0-9]{4}' then
        m := substring(s from '([0-9]{4})');
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    -- ranges like "1894..1905" -> first year
    if s ~ '^[0-9]{4}\.{2}[0-9]{4}' then
        m := substring(s from '^[0-9]{4}');
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    -- any other string containing a standalone 4 digit year
    m := substring(s from '(?:^|[^0-9])([0-9]{4})(?:[^0-9]|$)');
    if m is not null then
        if m::integer between 1000 and 2100 then
            return m::integer;
        end if;
        return null;
    end if;

    return null;
end;
$$;
