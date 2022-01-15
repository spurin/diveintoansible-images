#!/bin/bash

# Reset index.html
cp /usr/share/nginx/html/index.html.TEMPLATE /usr/share/nginx/html/index.html

# Overwrite, where desired based on env
if [ ! -z "$LOCALHOST_OVERRIDE" ]; then
   perl -p -i -e "s/http:\/\/localhost/http:\/\/${LOCALHOST_OVERRIDE}/g" /usr/share/nginx/html/index.html
fi

# Overwrite, where desired based on env
if [ ! -z "$OPEN_LINKS_AS_TABS" ] && [ "$OPEN_LINKS_AS_TABS"==1 ]; then
   perl -p -i -e "s/><img src=\"assets\/img\/terminal-/ target=\"_blank\"><img src=\"assets\/img\/terminal-/g" /usr/share/nginx/html/index.html
   perl -p -i -e "s/><img src=\"assets\/img\/webserver.png/ target=\"_blank\"><img src=\"assets\/img\/webserver.png/g" /usr/share/nginx/html/index.html
fi

exit 0
