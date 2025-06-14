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

    if s ~ '^j:' then
        s := substring(s from 3);
    elsif s ~ '^jd:' then
        return null;
    end if;

    if s ~ '^(early |mid |late |~)?c[0-9]{1,2}$' then
        m := substring(s from 'c([0-9]{1,2})');
        c := m::integer;
        return (c - 1) * 100 + 50;
    end if;

    if s ~ '^(early |mid |late |~)?[0-9]{4}s$' then
        m := substring(s from '([0-9]{4})');
        return m::integer;
    end if;

    if s ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
        return substring(s from 1 for 4)::integer;
    end if;

    if s ~ '^[0-9]{4}-[0-9]{2}$' then
        return substring(s from 1 for 4)::integer;
    end if;

    if s ~ '^~?[0-9]{4}$' then
        return regexp_replace(s, '[^0-9]', '', 'g')::integer;
    end if;

    if s ~ '^before [0-9]{4}' then
        return substring(s from '[0-9]{4}')::integer;
    end if;

    if s ~ '^after [0-9]{4}' then
        return substring(s from '[0-9]{4}')::integer;
    end if;

    if s ~ '^[0-9]{4}\.{2}[0-9]{4}' then
        return substring(s from '^[0-9]{4}')::integer;
    end if;

    m := substring(s from '([0-9]{4})');
    if m is not null then
        return m::integer;
    end if;

    return null;
end;
$$;
