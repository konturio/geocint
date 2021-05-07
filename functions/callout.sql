/*
k2_feature - основная таблица с геометриями. На момент отработки содержит только геометрии в Перу
\d k2_feature
                          Table "public.k2_feature"
      Column      |           Type           | Collation | Nullable | Default
------------------+--------------------------+-----------+----------+---------
 layer_id         | bigint                   |           |          |
 feature_id       | text                     |           |          |
 geometry         | geometry                 |           |          |
 properties       | jsonb                    |           |          |
 last_updated     | timestamp with time zone |           |          |
 datetime         | tstzrange                |           |          |
 geometry_preview | geometry                 |           |          |


\d k2_feature_outline
           Table "public.k2_feature_outline"
   Column   |   Type   | Collation | Nullable | Default
------------+----------+-----------+----------+---------
 feature_id | text     |           |          |
 label      | geometry |           |          |
 cflag      | boolean  |           |          | true
 cline      | geometry |           |          |
 rn         | integer  |           |          |


k2_feature_outline table
feature_id - id для связи
label - point, точка подписи или PIA, центр выноски
cline - line, линия-выноска
cflag - bool, флаг. true если label НЕ умещается в границы полигона и требуется выноска
                    false если label умешается в границы полигона
                    null если линия-выноска пересекает другую или  label

canvas - таблица с полем geom с границами экрана (задано условно вручную)

0.15 - примерный радиус подписи на 8 зуме в 4326
0.0001 - буфер вокруг точки подписи или PIA (~11 метров, для видимости в кугисе при отладке)
*/

drop table if exists canvas;
create table canvas as
select st_buffer(ST_SetSRID(ST_Extent(k2_feature.geometry), 4326), 1) as geom
from k2_feature;
-- внешняя граница

update canvas
set geom = ST_Difference(
        canvas.geom, st_buffer(a.geom, 0.15)
    )
from (select st_collect(k2_feature.geometry_preview) as geom from k2_feature) a;
-- внутренняя граница. 1 - 2 min, долгое выполнение

drop table if exists k2_feature_outline;
create table k2_feature_outline (feature_id text, label geometry, cflag bool default true, cline geometry, rn integer);

insert into k2_feature_outline (feature_id, label)
    select feature_id, p.center from k2_feature a,
                                    ST_MaximumInscribedCircle(geometry) p;

update k2_feature_outline set cflag = false where feature_id in (
SELECT k2_feature.feature_id
FROM k2_feature
JOIN k2_feature_outline  ON ST_Intersects(st_buffer(k2_feature_outline.label, 0.15), k2_feature.geometry)
GROUP BY k2_feature.feature_id, k2_feature.geometry
having count (k2_feature_outline.*) = 1 ) ;
-- определение записей, покрываемых только 1 меткой - их собственной

update canvas set
geom = ST_Difference (
    canvas.geom, st_buffer(label, 0.15)
                    )
from  k2_feature_outline where not cflag;
-- есть в таске, но не нужна по сути т.к. из канваса уже вырезаны все геометрии


-- deconflict the same PIAs

update k2_feature_outline set rn = a.rn from
                    (select ROW_NUMBER() OVER (PARTITION BY label) as rn, feature_id, label from k2_feature_outline ou
                    where (select count(*) from k2_feature_outline inr
                    where inr.label = ou.label) > 1) a
where a.feature_id = k2_feature_outline.feature_id;
-- нумеруем одинаковые PIA


do
$$
    declare
        row        record;
        tmp_centers   geometry;
    begin
        for row in (select rn, feature_id, label from k2_feature_outline
                    where rn >1 order by rn) loop
            if row.rn = 2 then tmp_centers := coalesce(tmp_centers,row.label);  end if;
            update k2_feature_outline set label =
            p.center from k2_feature a,
                                    ST_MaximumInscribedCircle(ST_Difference(geometry,
                                                                            st_buffer (tmp_centers,0.0001))) p
            where k2_feature_outline.rn = row.rn and k2_feature_outline.feature_id = row.feature_id;
         end loop;
    end;
$$;

do
$$
    declare
        row       record;
        tmp_cline geometry;
    begin
        for row in (select k2_feature_outline.feature_id, k2_feature_outline.label
                    from k2_feature_outline,
                         canvas
                    where k2_feature_outline.cflag  -- где требуются выноски
                    order by st_length(ST_MakeLine(label, ST_ClosestPoint(ST_Boundary(canvas.geom), label)))
                        DESC) -- начиная от дальней от канваса точки
            loop

                select ST_MakeLine(row.label, ST_ClosestPoint(ST_Boundary(canvas.geom), row.label))
                into tmp_cline
                from canvas;

                if not (select coalesce(st_intersects(tmp_cline, a.geoms), false)  -- линий сначала нет, st_intersects выдаст null
                        from (select st_collect(cline) as geoms from k2_feature_outline) a)
                    -- проверяем на пересечение с имеющимися линиями-выносками
                then
                    if not (select coalesce(st_intersects(tmp_cline, a.geoms), false)
                            from (select st_buffer(st_collect(st_buffer(st_endpoint(cline), 0.15)), 0) as geoms  -- buffer to prevent TopologyException
                                                                                                                        -- возможно не нужен если брать буффер pixel-size
                                  from k2_feature_outline) a)
                    then
                        if not ( select st_intersects(st_buffer(st_endpoint(tmp_cline), 0.15),                     -- лейбл не выходит за границы экрана
                                                   ST_Boundary(st_buffer(ST_SetSRID(ST_Extent(k2_feature.geometry), 4326), 1))
                                                    )
                            from k2_feature )                                                                           -- buffer of endpoint, bounds of original canvas
                        then
                            update k2_feature_outline
                            set cline = tmp_cline
                            where row.feature_id = k2_feature_outline.feature_id;
                        else
                            update k2_feature_outline set cflag = null where row.feature_id = k2_feature_outline.feature_id; -- null если есть пересечение. стоило Int делать сразу
                        end if;
                     end if;
                end if;

                if (select cflag from k2_feature_outline where feature_id = row.feature_id) = 'true'
                then
                    update canvas       -- если 2 условия выполнились, вырезаем из канваса EndPoint
                    set geom = ST_Difference(
                            canvas.geom, st_buffer(ST_EndPoint(a.geom), 0.15 * 2)
                        )
                    from (select ST_MakeLine(
                                         row.label, ST_ClosestPoint(ST_Boundary(canvas.geom), row.label)
                                     ) as geom
                          from canvas) a;
                end if;
            end loop;
    end;
$$;
-- 13 sec
