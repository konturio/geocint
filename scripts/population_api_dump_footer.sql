  CREATE INDEX stat_h3_geom_zoom_population_idx ON public.stat_h3__new USING gist (geom, zoom, population);
  ALTER TABLE public.stat_h3 RENAME TO stat_h3__old;
  ALTER TABLE public.stat_h3__new RENAME TO stat_h3;
  DROP TABLE public.stat_h3__old;
  COMMIT;
