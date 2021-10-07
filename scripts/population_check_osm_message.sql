with sections as (
    select jsonb_build_array(
                   jsonb_build_object(
                           'type', 'section',
                           'text', jsonb_build_object(
                                   'type', 'mrkdwn',
                                   'text',
                                   '<https://www.openstreetmap.org/relation/' || osm_id || '|' ||
                                   coalesce(name_en, name) ||
                                   '>'
                               )
                       ),
                   jsonb_build_object(
                           'type', 'actions',
                           'elements', jsonb_build_array(
                                   jsonb_build_object(
                                           'type', 'button',
                                           'text', jsonb_build_object(
                                                   'type', 'plain_text',
                                                   'text', 'Open in JOSM'
                                               ),
                                           'url', 'http://localhost:8111/load_object?new_layer=true&objects=r' ||
                                                  osm_id ||
                                                  '&relation_members=true'
                                       ),
                                   jsonb_build_object(
                                           'type', 'button',
                                           'text', jsonb_build_object(
                                                   'type', 'plain_text',
                                                   'text', 'Open in Google'
                                               ),
                                           'url', 'https://google.com/search?q=' || urlencode(coalesce(name_en, name))
                                       )
                               )
                       ),
                   jsonb_build_object(
                           'type', 'section',
                           'fields',
                           jsonb_build_array(
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', 'Kontur population'
                                       ),
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char(kontur_pop, '99G999G999G999')
                                       ),
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', 'OSM population'
                                       ),
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char(osm_pop, '99G999G999G999')
                                       ),
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', 'Difference'),
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char(diff_pop, '99G999G999G999')
                                       )
                               )
                       ),
                   jsonb_build_object('type', 'divider')
               ) j
    from population_check_osm
    order by diff_pop desc
    limit 5
)
select jsonb_build_array(
               jsonb_build_object(
                       'type', 'section',
                       'text', jsonb_build_object(
                               'type', 'mrkdwn',
                               'text', 'Top 5 boundaries with population different from OSM'
                           )
                   ),
               jsonb_build_object(
                       'type', 'divider'
                   )
           ) || jsonb_agg(el) ||
       '{
         "type": "context",
         "elements": [
           {
             "type": "mrkdwn",
             "text": "For more details see <https://geocint.kontur.io/gis/population_check_osm.html|:arrow_upper_right:>"
           }
         ]
       }'::jsonb
from sections,
     jsonb_array_elements(j) "el";


with sections as (
    select jsonb_build_array(
                   jsonb_build_object(
                           'type', 'section',
                           'text', jsonb_build_object(
                                   'type', 'mrkdwn',
                                   'text',
                                   '<https://www.openstreetmap.org/relation/' || osm_id || '|' ||
                                   coalesce(name_en, name) ||
                                   '>'
                               )
                       ),
                   jsonb_build_object(
                           'type', 'actions',
                           'elements', jsonb_build_array(
                                   jsonb_build_object(
                                           'type', 'button',
                                           'text', jsonb_build_object(
                                                   'type', 'plain_text',
                                                   'text', 'Open in JOSM'
                                               ),
                                           'url', 'http://localhost:8111/load_object?new_layer=true&objects=r' ||
                                                  osm_id ||
                                                  '&relation_members=true'
                                       ),
                                   jsonb_build_object(
                                           'type', 'button',
                                           'text', jsonb_build_object(
                                                   'type', 'plain_text',
                                                   'text', 'Open in Google'
                                               ),
                                           'url', 'https://google.com/search?q=' || urlencode(coalesce(name_en, name))
                                       )
                               )
                       ),
                   jsonb_build_object(
                           'type', 'section',
                           'fields',
                           jsonb_build_array(
                                   '{
                                     "type": "plain_text",
                                     "text": "Kontur population"
                                   }'::jsonb,
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char(kontur_pop, '99G999G999G999')
                                       ),
                                   '{
                                     "type": "plain_text",
                                     "text": "OSM population"
                                   }'::jsonb,
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char(osm_pop, '99G999G999G999')
                                       ),
                                   '{
                                     "type": "plain_text",
                                     "text": "Difference"
                                   }'::jsonb,
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char(diff_pop, '99G999G999G999')
                                       )
                               )
                       ),
                   '{
                     "type": "divider"
                   }'::jsonb
               ) j
    from population_check_osm
    order by diff_pop desc
    limit 5
)
select '[
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "Top 5 boundaries with population different from OSM"
    }
  },
  {
    "type": "divider"
  }
]'::jsonb || jsonb_agg(el) ||
       '{
         "type": "context",
         "elements": [
           {
             "type": "mrkdwn",
             "text": "For more details see <https://geocint.kontur.io/gis/population_check_osm.html|:arrow_upper_right:>"
           }
         ]
       }'::jsonb
from sections,
     jsonb_array_elements(j) "el";
