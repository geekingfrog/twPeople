#!/bin/bash

echo "Make java from coffee"
coffee -c app/

echo "Compressing scripts"
uglifyjs app/js/celeb.js > app/js/prod.js
# cat app/js/handlebars.js app/js/celeb.js > app/js/prod.js

echo "Compress the css"
cat app/foundation/css/normalize.css app/css/almost-flat-ui.css app/css/celeb.css > prodtmp.css
sqwish prodtmp.css -o app/css/prod.css
rm prodtmp.css


