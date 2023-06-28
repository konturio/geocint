# run this script from directory geocint/scripts
# this api token  was generated on https://data.humdata.org/user/kontur-hdx-robot/api-tokens
API_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJJZjVpbncxZDBBT3VwMHZjU0RWaloweUVscHVVeTBZTjhIMWhzd0ZpakF3IiwiaWF0IjoxNjg3NzkxNzQ2LCJleHAiOjE3MTkzMjc3NDZ9.v7EXbPqCuIrjVOueJK2bpIGS8qcAIGDU4Dgiuyo5VKs

python3 -m hdxloader update -t country-population --update_by_iso3 --iso3_file hdxloader/config/update-country-population-customviz.yml --hdx-site prod -k $API_TOKEN --no-dry-run