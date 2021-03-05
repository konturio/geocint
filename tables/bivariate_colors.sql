drop table if exists bivariate_colors;
create table bivariate_colors (
    color text,
    color_comment text,
    corner json
);

insert into bivariate_colors (color, color_comment, corner)
values ('#58b075', 'green', jsonb_build_array('good'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e8e89d', 'yellow', jsonb_build_array('bad', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#5d5398', 'purple', jsonb_build_array('bad', 'good'));

insert into bivariate_colors (color, color_comment, corner)
values ('#5ac8c8', 'alternate_color_2_green?', jsonb_build_array('good', 'bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#ada9c8', 'lilac', jsonb_build_array('bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#fedb00', 'dark yellow', jsonb_build_array('bad', 'unimportant', 'good'));

insert into bivariate_colors (color, color_comment, corner)
values ('#5ac87f', 'pale green', jsonb_build_array('good', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#53986a', 'dark green', jsonb_build_array('good', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#fedb00', 'dark yellow', jsonb_build_array('good', 'bad', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#58b075', 'green', jsonb_build_array('good', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#58b075', 'green', jsonb_build_array('neutral', 'good'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e41a1c', 'bloody red', jsonb_build_array('bad', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#f37e7e', 'light red', jsonb_build_array('neutral', 'bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#f37e7e', 'light red', jsonb_build_array('neutral', 'bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#f37e7e', 'light red', jsonb_build_array('bad', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#5ac87f', 'pale green', jsonb_build_array('unimportant', 'good'));

insert into bivariate_colors (color, color_comment, corner)
values ('#53986a', 'dark green', jsonb_build_array('important', 'good'));

insert into bivariate_colors (color, color_comment, corner)
values ('#f37e7e', 'light red',jsonb_build_array('unimportant', 'bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e41a1c', 'bloody red', jsonb_build_array('important', 'bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#f37e7e', 'light red', jsonb_build_array('neutral', 'bad', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#f37e7e', 'light red', jsonb_build_array('bad', 'unimportant', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#cccccc', '#cccccc', jsonb_build_array('neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#c85a5a', 'red', jsonb_build_array('bad', 'unimportant', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#999999', 'dark grey', jsonb_build_array('bad', 'important', 'good'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e8e89d', 'yellow', jsonb_build_array('good', 'unimportant', 'bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#999999', 'dark grey', jsonb_build_array('good', 'bad', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#c85a5a', 'red', jsonb_build_array('important', 'bad', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#abd8ed', 'sky blue', jsonb_build_array('neutral', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e8e89d', 'yellow', jsonb_build_array('important', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e8e89d', 'yellow', jsonb_build_array('neutral', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#999999', 'dark grey', jsonb_build_array('good', 'important', 'bad'));

insert into bivariate_colors (color, color_comment, corner)
values ('#abd8ed', 'sky blue', jsonb_build_array('unimportant', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e8e89d',  'yellow', jsonb_build_array('bad', 'good', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#999999', 'dark grey', jsonb_build_array('bad', 'good', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#c85a5a', 'red', jsonb_build_array('bad', 'important', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#5ac87f', 'pale green', jsonb_build_array('neutral', 'good', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#5ac87f', 'pale green', jsonb_build_array('good', 'unimportant', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#cccccc',  '#cccccc', jsonb_build_array('bad', 'unimportant', 'good', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#53986a', 'dark green', jsonb_build_array('neutral', 'good', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#c85ac8', 'alternate_color_1_magenta?', jsonb_build_array('unimportant', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e41a1c', 'bloody red', jsonb_build_array('neutral', 'bad', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#53986a', 'dark green', jsonb_build_array('good', 'important', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e8e89d', 'yellow', jsonb_build_array('unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#999999', 'dark grey', jsonb_build_array('important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#cccccc', '#cccccc', jsonb_build_array('good', 'important', 'bad', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#e41a1c', 'bloody red', jsonb_build_array('bad', 'important', 'neutral'));

insert into bivariate_colors (color, color_comment, corner)
values ('#5ac8c8', 'alternate_color_2_cyan?', jsonb_build_array('important', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#58b075', 'green', jsonb_build_array('good', 'unimportant', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#58b075', 'green', jsonb_build_array('good', 'important', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#c85a5a', 'red', jsonb_build_array('unimportant', 'bad', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#58b075',  'green', jsonb_build_array('important', 'good', 'unimportant'));

insert into bivariate_colors (color, color_comment, corner)
values ('#58b075', 'green', jsonb_build_array('unimportant', 'good', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#cccccc', '#cccccc', jsonb_build_array('good', 'unimportant', 'bad', 'important'));

insert into bivariate_colors (color, color_comment, corner)
values ('#cccccc', '#cccccc', jsonb_build_array('bad', 'important', 'good', 'unimportant'));
