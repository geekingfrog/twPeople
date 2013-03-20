#!/bin/bash
host=geekingfrog
path=~/projects/celebrities
scp ./logConfig.js package.json $host:$path
scp -r app mongo $host:$path
