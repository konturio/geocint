create table population_vector_constrained as (select * from population_vector);
alter table population_vector_constrained add column min_population float;
alter table population_vector_constrained add column max_population float;
create index on population_vector_constrained using gist(geom);
