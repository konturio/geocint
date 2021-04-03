create or replace function parse_float(val text)
    returns double precision as
$$
begin
    return val::double precision;
exception
    when others then
        begin
            -- todo: more sophisticated parsing
            return null;
        end;
        return null;
end
$$
    language 'plpgsql'
    immutable
    strict parallel safe;