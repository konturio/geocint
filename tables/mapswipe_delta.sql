drop table if exists mapswipe_delta;
-- Get new projects id and changed projects id
create table mapswipe_delta as (
	select project_id as pid
	from mapswipe_projects_new
	where project_id not in (select project_id from mapswipe_projects_old)
	union
	select b.project_id as pid
	from mapswipe_projects_old a,
         mapswipe_projects_new b
	where a.day != b.day and a.project_id = b.project_id);