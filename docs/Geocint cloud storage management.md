# Geocint cloud storage management

1. **Credentials.** \
   **- local AWS.**\
   aws credentials are used for uploading and downloading objects to buckets with access policies. File .aws/credentials is located in linux user home directory\
   ![](https://lh4.googleusercontent.com/WNzGi6D8hpwR_u-hwuhGs1mGy3zzqAnvkHd_KuM2nsWMOy6uEFQNi9D7yJN_lNwHqbr5M3GkR8hHXCtIp1dpqsjylEVQO650RKSvfGMEIC6VH8KTClSXv7ufZG-RkwM9-ZkY8ti3=s0 "")\
   Where \[default, geocint_pipeline_sender\] is profile name, which is used in commands like: \
   *aws s3 ….*  **--profile geocint_pipeline_sender**\
   Make sure that you use right profile on every step and server **\
   \
   - ansible**\
   Ansible is used for managing deployment (and etc) from geocint server. You can find list of used servers and local linux users in\
   **/etc/ansible/hosts** file. \
   ![](https://lh6.googleusercontent.com/wssToKdelnJHtsKP7C_i_TOaRpKr_vfN4nmLmmVlQMGgD0Bu9SmWSuRcrUWgIg76OLQnfQLSezWptFMOg1qo_6lh-rspage4GxSfF-Ho9r60GHLOhKi1eCLLqt-D38n8374ti93A=s0 "")For example, *ansible zigzag_population_api* means that command will be executed on zigzag under local user population-api, which should have aws credential file in home dir, like said above.\
   \
   \
   - **Bucket permissions.** These permissions are configured in the web console. \
   ![](https://lh6.googleusercontent.com/b5lHEneEzSQbKLViijbBvvIyNf9USdgxChuaLGr3HDJ-yEaTIVAkP7BOKQmd4L4xbcHHAvUODggdaWGDjPyKpLDH4QDFxq-2HT5Rsgl7TVr13Nw5NauaEK9mRy9lvYzdWQqTnl65=s0 "")
2. **Buckets and folders**\
   As for 20210909, we have private bucket **geodata-eu-central-1-kontur**, containing list of folders:\
   geodata-eu-central-1-kontur/private/geocint/in\
   geodata-eu-central-1-kontur/private/geocint/test\
   geodata-eu-central-1-kontur/private/geocint/prod\
   \
   Public buckets need to be made\
   Public bucket: geodata-us-east-1-kontur/public/geocint/
3. **IAM Users**. As for 20210909, in IAM we have one group of users (**geocint_pipeline**) and two users, having access to our private bucket - **geocint_pipeline_sender** and **geocint_pipeline_receiver**.\
   Sender’s credentials are on geocint server, and receiver’s credentials are on zigzag, sonic and lima servers.\
   ![](https://lh3.googleusercontent.com/4sQthPE2sMUrbCJJFTiSDhoVhKaW88OaYyA5aZIDGQNoscDeOIMChMdilli05EYhyqjHrmPfcZuMD88lENcPfHbXhORhPy6zn59ctLCOVQnflbDfZ5bc7V9IXGYX5LxFukvJbyX_=s0 "")
4. **Access rights** are not easy, make sure you tested access from all endpoints.\
   Also, make sure that you use the right syntax when defining permissions. \
   \
   For example:\
   ListBucket needs only bucket name\
   GetObject/PutObject and etc. need …. /\* in the end
5. **How to put/get your files**\
   Currently, we have **geodata-eu-central-1-kontur/private/geocint/in** folder for files needed for pipeline. There are several ways to put and get the file, the depends on the size of your file.\
   For files less than 4GB you can use put/get syntax, for files larger than 4GB you need to use *aws s3 cp* command.\
   Also, you can use syncing files instead of copy\
   \
   TODO: add examples

`aws s3 cp data/out/global_fires/kontur_global_fires_20210913.csv `[`s3://geodata-eu-central-1-kontur-public/kontur_datasets/`](s3://geodata-eu-central-1-kontur-public/kontur_datasets/)` --profile geocint_pipeline_sender --acl public-read`\
that how global fires were uploded\
\
[https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_datasets/kontur_population_20211109.gpkg.gz](https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_datasets/kontur_population_20211109.gpkg.gz)\
 as example, so <https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/>  is a http link, [geodata-eu-central-1-kontur-public](https://s3.console.aws.amazon.com/s3/buckets/geodata-eu-central-1-kontur-public) is bucket, [kontur_datasets/](https://s3.console.aws.amazon.com/s3/buckets/geodata-eu-central-1-kontur-public?prefix=kontur_datasets/) is a folder inside it

Don't forget to malually add permissions: 
