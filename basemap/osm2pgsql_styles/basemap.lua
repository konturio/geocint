-- This config example file is released into the Public Domain.

-- This configuration for the flex output tries to be compatible with the
-- original pgsql C transform output. There might be some corner cases but
-- it should do exactly the same in almost all cases.

-- The output projection used (3857, web mercator is the default). Set this
-- to 4326 if you were using the -l|--latlong option or to the EPSG
-- code you were using on the -E|-proj option.
local srid = 3857

-- Set this to the table name prefix (what used to be option -p|--prefix).
local prefix = 'planet_osm'

-- Set this to true if multipolygons should be written as multipolygons into
-- db (what used to be option -G|--multi-geometry).
local multi_geometry = true

-- Set this to true if you want an hstore column (what used to be option
-- -k|--hstore). Can not be true if "hstore_all" is true.
local hstore = true

-- Set this to true if you want all tags in an hstore column (what used to
-- be option -j|--hstore-all). Can not be true if "hstore" is true.
local hstore_all = false

-- Only keep objects that have a value in one of the non-hstore columns
-- (normal action with --hstore is to keep all objects). Equivalent to
-- what used to be set through option --hstore-match-only.
local hstore_match_only = true

-- Set this to add an additional hstore (key/value) column containing all tags
-- that start with the specified string, eg "name:". Will produce an extra
-- hstore column that contains all "name:xx" tags. Equivalent to what used to
-- be set through option -z|--hstore-column. Unlike the -z option which can
-- be specified multiple time, this does only support a single additional
-- hstore column.
local hstore_column = nil

-- ---------------------------------------------------------------------------

if hstore and hstore_all then
    error("hstore and hstore_all can't be both true")
end

-- Used for splitting up long linestrings
if srid == 4326 then
    max_length = 1
else
    max_length = 100000
end

-- Ways with any of the following keys will be treated as polygon
local polygon_keys = {
    'aeroway',
    'amenity',
    'building',
    'harbour',
    'historic',
    'landuse',
    'leisure',
    'man_made',
    'military',
    'natural',
    'office',
    'place',
    'power',
    'public_transport',
    'shop',
    'sport',
    'tourism',
    'water',
    'waterway',
    'wetland',
    'abandoned:aeroway',
    'abandoned:amenity',
    'abandoned:building',
    'abandoned:landuse',
    'abandoned:power',
    'area:highway'
}

-- Objects without any of the following keys will be deleted
local generic_keys = {
    'access',
    'addr:housename',
    'addr:housenumber',
    'addr:interpolation',
    'admin_level',
    'aerialway',
    'aeroway',
    'amenity',
    'area',
    'barrier',
    'bicycle',
    'boundary',
    'brand',
    'bridge',
    'building',
    'capital',
    'construction',
    'covered',
    'culvert',
    'cutting',
    'denomination',
    'disused',
    'ele',
    'embankment',
    'foot',
    'generation:source',
    'harbour',
    'highway',
    'historic',
    'hours',
    'intermittent',
    'junction',
    'landuse',
    'layer',
    'leisure',
    'lock',
    'man_made',
    'military',
    'motorcar',
    'name',
    'natural',
    'office',
    'oneway',
    'operator',
    'place',
    'population',
    'power',
    'power_source',
    'public_transport',
    'railway',
    'ref',
    'religion',
    'route',
    'service',
    'shop',
    'sport',
    'surface',
    'toll',
    'tourism',
    'tower:type',
    'tracktype',
    'tunnel',
    'water',
    'waterway',
    'wetland',
    'width',
    'wood',
    'abandoned:aeroway',
    'abandoned:amenity',
    'abandoned:building',
    'abandoned:landuse',
    'abandoned:power',
    'area:highway'
}

-- The following keys will be deleted
local delete_keys = {
    -- "mapper" keys
    'attribution',
    'comment',
    'created_by',
    'fixme',
    'note',
    'note:*',
    'odbl',
    'odbl:note',
    'source',
    'source:*',
    'source_ref',
    'way',
    'way_area',
    'z_order',

    -- "import" keys

    -- Corine Land Cover (CLC) (Europe)
    'CLC:*',

    -- Geobase (CA)
    'geobase:*',
    -- CanVec (CA)
    'canvec:*',

    -- osak (DK)
    'osak:*',
    -- kms (DK)
    'kms:*',

    -- ngbe (ES)
    -- See also note:es and source:file above
    'ngbe:*',

    -- Friuli Venezia Giulia (IT)
    'it:fvg:*',

    -- KSJ2 (JA)
    -- See also note:ja and source_ref above
    'KSJ2:*',
    -- Yahoo/ALPS (JA)
    'yh:*',

    -- LINZ (NZ)
    'LINZ2OSM:*',
    'linz2osm:*',
    'LINZ:*',
    'ref:linz:*',

    -- WroclawGIS (PL)
    'WroclawGIS:*',
    -- Naptan (UK)
    'naptan:*',

    -- TIGER (US)
    'tiger:*',
    -- GNIS (US)
    'gnis:*',
    -- National Hydrography Dataset (US)
    'NHD:*',
    'nhd:*',
    -- mvdgis (Montevideo, UY)
    'mvdgis:*',

    -- EUROSHA (Various countries)
    'project:eurosha_2012',

    -- UrbIS (Brussels, BE)
    'ref:UrbIS',

    -- NHN (CA)
    'accuracy:meters',
    'sub_sea:type',
    'waterway:type',
    -- StatsCan (CA)
    'statscan:rbuid',

    -- RUIAN (CZ)
    'ref:ruian:addr',
    'ref:ruian',
    'building:ruian:type',
    -- DIBAVOD (CZ)
    'dibavod:id',
    -- UIR-ADR (CZ)
    'uir_adr:ADRESA_KOD',

    -- GST (DK)
    'gst:feat_id',

    -- Maa-amet (EE)
    'maaamet:ETAK',
    -- FANTOIR (FR)
    'ref:FR:FANTOIR',

    -- 3dshapes (NL)
    '3dshapes:ggmodelk',
    -- AND (NL)
    'AND_nosr_r',

    -- OPPDATERIN (NO)
    'OPPDATERIN',
    -- Various imports (PL)
    'addr:city:simc',
    'addr:street:sym_ul',
    'building:usage:pl',
    'building:use:pl',
    -- TERYT (PL)
    'teryt:simc',

    -- RABA (SK)
    'raba:id',
    -- DCGIS (Washington DC, US)
    'dcgis:gis_id',
    -- Building Identification Number (New York, US)
    'nycdoitt:bin',
    -- Chicago Building Inport (US)
    'chicago:building_id',
    -- Louisville, Kentucky/Building Outlines Import (US)
    'lojic:bgnum',
    -- MassGIS (Massachusetts, US)
    'massgis:way_id',
    -- Los Angeles County building ID (US)
    'lacounty:*',
    -- Address import from Bundesamt für Eich- und Vermessungswesen (AT)
    'at_bev:addr_date',

    -- misc
    'import',
    'import_uuid',
    'OBJTYPE',
    'SK53_bulk:load',
    'mml:class'
}

local point_columns = {
    'access',
    'addr:housename',
    'addr:housenumber',
    'addr:interpolation',
    'admin_level',
    'aerialway',
    'aeroway',
    'amenity',
    'area',
    'barrier',
    'bicycle',
    'brand',
    'bridge',
    'boundary',
    'building',
    'capital',
    'construction',
    'covered',
    'culvert',
    'cutting',
    'denomination',
    'disused',
    'ele',
    'embankment',
    'foot',
    'generator:source',
    'harbour',
    'highway',
    'historic',
    'horse',
    'intermittent',
    'junction',
    'landuse',
    'layer',
    'leisure',
    'lock',
    'man_made',
    'military',
    'motorcar',
    'name',
    'natural',
    'office',
    'oneway',
    'operator',
    'place',
    'population',
    'power',
    'power_source',
    'public_transport',
    'railway',
    'ref',
    'religion',
    'route',
    'service',
    'shop',
    'sport',
    'surface',
    'toll',
    'tourism',
    'tower:type',
    'tunnel',
    'water',
    'waterway',
    'wetland',
    'width',
    'wood',
}

local non_point_columns = {
    'access',
    'addr:housename',
    'addr:housenumber',
    'addr:interpolation',
    'admin_level',
    'aerialway',
    'aeroway',
    'amenity',
    'area',
    'barrier',
    'bicycle',
    'brand',
    'bridge',
    'boundary',
    'building',
    'construction',
    'covered',
    'culvert',
    'cutting',
    'denomination',
    'disused',
    'embankment',
    'foot',
    'generator:source',
    'harbour',
    'highway',
    'historic',
    'horse',
    'intermittent',
    'junction',
    'landuse',
    'layer',
    'leisure',
    'lock',
    'maritime',
    'man_made',
    'military',
    'motorcar',
    'name',
    'natural',
    'office',
    'oneway',
    'operator',
    'place',
    'population',
    'power',
    'power_source',
    'public_transport',
    'railway',
    'ref',
    'religion',
    'route',
    'service',
    'shop',
    'sport',
    'surface',
    'toll',
    'tourism',
    'tower:type',
    'tracktype',
    'tunnel',
    'water',
    'waterway',
    'wetland',
    'width',
    'wood',
}

function gen_columns(text_columns, with_hstore, area, geometry_type)
    columns = {}

    local add_column = function (name, type)
        columns[#columns + 1] = { column = name, type = type }
    end

    for _, c in ipairs(text_columns) do
        add_column(c, 'text')
    end

    if area ~= nil then
        if area then
            add_column('way_area', 'area')
        else
            add_column('way_area', 'real')
        end
    end

    if hstore_column then
        add_column(hstore_column, 'hstore')
    end

    if with_hstore then
        add_column('tags', 'hstore')
    end

    add_column('way', geometry_type)
    columns[#columns].projection = srid

    return columns
end

local tables = {}

tables.point = osm2pgsql.define_table{
    name = prefix .. '_point',
    ids = { type = 'node', id_column = 'osm_id' },
    columns = gen_columns(point_columns, hstore or hstore_all, nil, 'point'),
    cluster = 'no',
}

tables.line = osm2pgsql.define_table{
    name = prefix .. '_line',
    ids = { type = 'way', id_column = 'osm_id' },
    columns = gen_columns(non_point_columns, hstore or hstore_all, false, 'linestring'),
    cluster = 'no',
}

tables.polygon = osm2pgsql.define_table{
    name = prefix .. '_polygon',
    ids = { type = 'area', id_column = 'osm_id' },
    columns = gen_columns(non_point_columns, hstore or hstore_all, true, 'geometry'),
    cluster = 'no',
}

tables.countries = osm2pgsql.define_relation_table('countries', {
    { column = 'lang', type = 'text' },
    { column = 'geom', type = 'geometry' },
})

function make_check_in_list_func(list)
    local h = {}
    for _, k in ipairs(list) do
        h[k] = true
    end
    return function(tags)
        for k, _ in pairs(tags) do
            if h[k] then
                return true
            end
        end
        return false
    end
end

local is_polygon = make_check_in_list_func(polygon_keys)
local clean_tags = osm2pgsql.make_clean_tags_func(delete_keys)

function make_column_hash(columns)
    local h = {}

    for _, k in ipairs(columns) do
        h[k] = true
    end

    return h
end

function make_get_output(columns, hstore_all)
    local h = make_column_hash(columns)
    if hstore_all then
        return function(tags)
            local output = {}
            local hstore_entries = {}

            for k, _ in pairs(tags) do
                if h[k] then
                    output[k] = tags[k]
                end
                hstore_entries[k] = tags[k]
            end

            return output, hstore_entries
        end
    else
        return function(tags)
            local output = {}
            local hstore_entries = {}

            for k, _ in pairs(tags) do
                if h[k] then
                    output[k] = tags[k]
                else
                    hstore_entries[k] = tags[k]
                end
            end

            return output, hstore_entries
        end
    end
end

local has_generic_tag = make_check_in_list_func(generic_keys)

local get_point_output = make_get_output(point_columns, hstore_all)
local get_non_point_output = make_get_output(non_point_columns, hstore_all)

function get_hstore_column(tags)
    local len = #hstore_column
    local h = {}
    for k, v in pairs(tags) do
        if k:sub(1, len) == hstore_column then
            h[k:sub(len + 1)] = v
        end
    end

    if next(h) then
        return h
    end
    return nil
end

function osm2pgsql.process_node(object)
    if clean_tags(object.tags) then
        return
    end

    local output
    local output_hstore = {}
    if hstore or hstore_all then
        output, output_hstore = get_point_output(object.tags)
        if not next(output) and not next(output_hstore) then
            return
        end
        if hstore_match_only and not has_generic_tag(object.tags) then
            return
        end
    else
        output = object.tags
        if not has_generic_tag(object.tags) then
            return
        end
    end

    output.tags = output_hstore

    if hstore_column then
        output[hstore_column] = get_hstore_column(object.tags)
    end

    tables.point:add_row(output)
end

function osm2pgsql.process_way(object)
    -- skip boundary=administrative, Kontur Boundaries are used instead
    if object.tags.boundary == 'administrative' then
        return
    end

    if clean_tags(object.tags) then
        return
    end

    local add_area = false
    if object.tags.natural == 'coastline' then
        add_area = true
        object.tags.natural = nil
    end

    local output
    local output_hstore = {}
    if hstore or hstore_all then
        output, output_hstore = get_non_point_output(object.tags)
        if not next(output) and not next(output_hstore) then
            return
        end
        if hstore_match_only and not has_generic_tag(object.tags) then
            return
        end
        if add_area and hstore_all then
            output_hstore.area = 'yes'
        end
    else
        output = object.tags
        if not has_generic_tag(object.tags) then
            return
        end
    end

    local polygon
    local area_tag = object.tags.area
    if area_tag == 'yes' or area_tag == '1' or area_tag == 'true' then
        polygon = true
    elseif area_tag == 'no' or area_tag == '0' or area_tag == 'false' then
        polygon = false
    else
        polygon = is_polygon(object.tags)
    end

    if add_area then
        output.area = 'yes'
        polygon = true
    end

    output.tags = output_hstore

    if hstore_column then
        output[hstore_column] = get_hstore_column(object.tags)
    end

    if polygon and object.is_closed then
        output.way = { create = 'area' }
        tables.polygon:add_row(output)
    else
        output.way = { create = 'line', split_at = max_length }
        tables.line:add_row(output)
    end
end

function osm2pgsql.process_relation(object)
    if clean_tags(object.tags) then
        return
    end

    local type = object.tags.type
    if (type ~= 'route') and (type ~= 'multipolygon') and (type ~= 'boundary') then
        return
    end
    object.tags.type = nil

    if object.tags.default_language ~= nil and object.tags.default_language ~= '' then
        tables.countries:add_row({
                geom = { create = 'area' },
                name = object.tags.name,
                lang = 'name:' .. object.tags.default_language
            })
    end

    local output
    local output_hstore = {}
    if hstore or hstore_all then
        output, output_hstore = get_non_point_output(object.tags)
        if not next(output) and not next(output_hstore) then
            return
        end
        if hstore_match_only and not has_generic_tag(object.tags) then
            return
        end
    else
        output = object.tags
        if not has_generic_tag(object.tags) then
            return
        end
    end

    if not next(output) and not next(output_hstore) then
        return
    end

    local make_boundary = false
    -- skip boundary=administrative, Kontur Boundaries are used instead
    if object.tags.boundary == 'administrative' then
        return
    end

    local make_polygon = false
    if type == 'boundary' then
        make_boundary = true
    elseif type == 'multipolygon' and object.tags.boundary then
        make_boundary = true
    elseif type == 'multipolygon' then
        make_polygon = true
    end

    output.tags = output_hstore

    if hstore_column then
        output[hstore_column] = get_hstore_column(object.tags)
    end

    if not make_polygon then
        output.way = { create = 'line', split_at = max_length }
        tables.line:add_row(output)
    end

    if make_boundary or make_polygon then
        output.way = { create = 'area' }
        if not multi_geometry then
            output.way.split_at = 'multi'
        end
        tables.polygon:add_row(output)
    end
end
