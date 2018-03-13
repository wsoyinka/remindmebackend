#!/bin/bash

#activate venv

. /appenv/bin/activate


## Download the requirements to build cache. 
# Helps to avoid having different package versions between test and build stage 

pip download -d /build -r requirements_test.txt --no-input

# Install application test requirements (mocha et al...) 

pip install --no-index -f /build -r requirements_test.txt

exec $@
