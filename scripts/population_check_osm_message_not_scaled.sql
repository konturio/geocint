with sections as (
    select jsonb_build_array(
                   jsonb_build_object(
                           'type', 'section',
                           'text', jsonb_build_object(
                                   'type', 'mrkdwn',
                                   'text',
                                   '<https://www.openstreetmap.org/relation/' || osm_id || '|' ||
                                   coalesce(name_en, name_boundaries) ||
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
                                           'url', 'https://google.com/search?q=' || urlencode(coalesce(name_en, name_boundaries))
                                       ),
                                   jsonb_build_object(
                                           'type', 'button',
                                           'text', jsonb_build_object(
                                                   'type', 'plain_text',
                                                   'text', 'Open on Wikidata'
                                               ),
                                           'url', wikidata_link
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
                                           'text', to_char("Kontur population", '99G999G999G999')
                                       ),
                                   '{
                                     "type": "plain_text",
                                     "text": "OSM population"
                                   }'::jsonb,
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char("OSM population", '99G999G999G999')
                                       ),
                                   '{
                                     "type": "plain_text",
                                     "text": "Wikidata population"
                                   }'::jsonb,
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char("Wikidata population", '99G999G999G999')
                                       ),
                                   '{
                                     "type": "plain_text",
                                     "text": "OSM-Kontur Population difference"
                                   }'::jsonb,
                                   jsonb_build_object(
                                           'type', 'plain_text',
                                           'text', to_char("OSM-Kontur Population difference", '99G999G999G999')
                                       )
                               )
                       ),
                   '{
                     "type": "divider"
                   }'::jsonb
               ) j
    from population_check_osm
    where "Expected population" is null
    order by abs("OSM-Kontur Population difference") desc
    limit 5
)
select '[
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "Top 5 not scaled boundaries with population different from OSM"
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
             "text": "<https://disaster.ninja/active/reports/population_tag_check|For more details see :arrow_upper_right:>"
           }
         ]
       }'::jsonb ||
       '{
         "type": "context",
         "elements": [
           {
             "type": "mrkdwn",
             "text": "<https://docs.google.com/spreadsheets/d/1-XuFA8c3sweMhCi52tdfhepGXavimUWA7vPc3BoQb1c|Prescale to OSM mastertable :spiral_note_pad:>"
           }
         ]
       }'::jsonb ||
       '{
         "type": "context",
         "elements": [
           {
             "type": "mrkdwn",
             "text": "<https://kontur.fibery.io/Tasks/document/Population-totals-improvement-1353|How to use this message :spiral_note_pad:>"
           }
         ]
       }'::jsonb
from sections,
     jsonb_array_elements(j) "el";
