Notes for agents:

 - Check out README.md.
 - Makefile can have some targets that are coming from geocint-runner and geocint-openstreetmap repositories, it's ok.
 - Makefile: there are comments on the same line after each target separated by ## - they are used in debug graph visualization, need to be concise and descriptive of what's going on in the code itself.
 - Makefile: Don't create too many targets if you don't need intermediate results in many places.
 - Makefile: If you need intermediate result from other target, split it into two and depend on the intermediate result.
 - File names in tables/ are supposed to match primary table name, file names in procedures/ and functions/ - similarly.
 - When adding layers, check `tables/bivariate_indicators.sql` to add description, emoji, copyrights. Add targets to deploy to dev, test, prod.
 - Don't use postfixes for units in h3 indicators, put them into metadata field for the layer instead.
 - Add empty lines between logical blocks as in the rest of the codebase.
 - SQL files in tables/ need to be idempotent: drop table if exists; add some comments to make people grasp quereies faster.
 - values in layers should be absolute as much as possible: store "birthday" or "construction date" instead of "age".
 - prefer h3 resolution 11 unless you have other good reasons.
 - prefer indexed operators when dealing with jsonb ( `tags @> '{"key": "value"}` instead of `tags ->> 'key' = 'value'` ).
 - use pigz instead of gzip where possible.
 - SQL is lowercase, PostGIS functions follow their spelling from the manual (`st_segmentize` -> `ST_Segmentize`).
 - clean stuff up if you can: fix typos, make lexics more correct in Enghish.
 - trivial oneliner SQLs are okay to keep in Makefile.
