#! /bin/bash

cd "$SRCROOT"
sed -e "/BUILD_NUMBER =/ s/= .*/= $(date +"%y%m%d%H%M")/" Config.xcconfig \
    > Config.xcconfig.tmp && mv Config.xcconfig.tmp Config.xcconfig
