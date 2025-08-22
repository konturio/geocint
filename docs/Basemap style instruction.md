# Basemap style instruction

In this instruction you can find out how to change and update style of basemap. Here is an example how to make changes on "Kontur Lines" which as a result you can see on Disaster Ninja.

# Connection to geocint and file with style

Original basemap is located on geocint and it isn't directly and automatically related to basemaps on zigzag, sonic and lima, so here you can try to apply your style changes without fear. First of all, you need to connect with geocint. Print these commands in your terminal/command line:

1. `ssh `[`geocint.kontur.io`](http://geocint.kontur.io)
2. \*Enter passphrase for key
3. `sudo su - gis`
4. `cd geocint` -  (*should we switch a branch here?)*
5. `nano basemap/styles/ninja.mapcss `- there is a directory where file with style is located in geocint

Now you're connected to **ninja.mapcss** - file with style of basemap, where you can add or edit what is necessary.

![Снимок экрана 2021-11-25 в 17.15.49.png](https://kontur.fibery.io/api/files/35590172-14dc-4896-91c1-5dfb7eeca616#align=%3Aalignment%2Fblock-center&width=1616&height=671 "that's how it is seen in terminal (Macbook")")

After editing, you need to save changes and come back to terminal/command line (`CTRL+X - Y - Enter`)

Print this command `rm data/basemap/metadata/geocint/style_day.json `- it will delete generated json-file with basemap style

![Снимок экрана 2021-11-25 в 17.23.50.png](https://kontur.fibery.io/api/files/33591988-d09a-40fc-91dd-3397dc174199#align=%3Aalignment%2Fblock-left&width=707&height=17 "if you will see it after the command above - it's normal, just continue")

Then print this: `make deploy/geocint/basemap_mapcss `- it will make a deploy of basemap on geocint and create new json-file with style. After that you can visually see all your changes here: [https://geocint.kontur.io/basemap/index.html](https://geocint.kontur.io/basemap/index.html "https://geocint.kontur.io/basemap/index.html") - buttons "geocint" and "day"/"ninja" should be chosen. Often it works while updating your usual browser page, but to be 100% sure - use **incognito mode.** If you want to continue editing, come back to ninja.mapcss. If everything is perfect, go further.

# How to commit changes

Usually our next step is to add changes in our repository on Gitlab if we really need them. (*Ninja.mapcss on geocint is refreshed almost everyday, so your changes can be lost, that's why important changes should be commited*). Here is a directory of file with style: 

[https://gitlab.com/kontur-private/platform/geocint/-/blob/master/basemap/styles/ninja.mapcss](https://gitlab.com/kontur-private/platform/geocint/-/blob/master/basemap/styles/ninja.mapcss "https://gitlab.com/kontur-private/platform/geocint/-/blob/master/basemap/styles/ninja.mapcss")

With help of your own local repository (ex. PyCharm, Visual Studio Code) to avoid unacceptable situations, add changes and push commit to main repository on Gitlab, create merge request (if you don't have an experience with local repositories - ask Aliaksandra Tsiatserkina or Aliaksandr Kalenik for help.

After merging your request, you can update file with style on geocint. Of course, you need to be connected to geocint with your terminal/command line (if you're already connected, start with point 4):

1. `ssh `[`geocint.kontur.io`](http://geocint.kontur.io)
2. \*Enter passphrase for key
3. `sudo su - gis`
4. `cd geocint` 
5. `git switch master` - to be sure that you are on origin branch
6. `git pull origin master `- it will update your file with style according to the file on Gitlab

   Now the version of basemap on geocint is the freshest. 

If everything is okay, you will see a picture like this:![Снимок экрана 2021-11-29 в 20.41.16.png](https://kontur.fibery.io/api/files/c9f60a08-66b7-44b6-be02-3df931c267f2#width=685&height=206 "")

It happens that someone can change something in other files on geocint or your changes just stayed in file. So after `git pull origin master` you can see something like this:

![Снимок экрана 2021-11-29 в 19.22.35.png](https://kontur.fibery.io/api/files/ced56478-ac45-4bc1-a087-96ec755eb4a6#width=533&height=152 "")You need just to restore changed files with this command:

`git restore basemap/styles/ninja.mapcss`

\-if there are some changes somewhere else, ask the person who made it to restore their files too. Make `git restore `+ directory of file (like in command above). 

# How to update basemap on zigzag, sonic and lima(prod)

So, then, you need to update basemap in zigzag. 

Type it in your terminal/command line 

`make -o deploy/zigzag/basemap.mbtiles deploy/zigzag/basemap`

Result is seen here: [https://test-apps-ninja02.konturlabs.com/active/](https://test-apps-ninja02.konturlabs.com/active/)

By the way, you can check how basemap is working with colours and hexagons.

And, of course, you need to give your changes to QA testing, so you should update style on sonic:

`make -o deploy/sonic/basemap.mbtiles deploy/sonic/basemap`

After testing and checking that everything is okay, you can finally update prod version of basemap, which we all can see here: [https://disaster.ninja/live/](https://disaster.ninja/live/ "https://disaster.ninja/live/") 

This is the last command you should type:

`make -o deploy/lima/basemap.mbtiles deploy/lima/basemap`

Everything should be seen on Disaster Ninja. Also you can check all basemap updatings here: <https://geocint.kontur.io/basemap/index.html> - just be sure to choose the right button (zigzag, sonic or lima; day/ninja) 
