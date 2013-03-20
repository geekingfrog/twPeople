#!/bin/bash

echo "Make java from coffee"
coffee -c app/

echo "Compressing scripts"
uglifyjs app/js/handlebars.js app/js/d3.v3.js app/js/celeb.js >> app/js/prod.js

