#!/bin/sh

create_iconset()
{
    ORIG_FILE=$1
    DEST_FOLDER=$2
    magick "$ORIG_FILE" -resize 16x16      "$DEST_FOLDER/icon_16x16.png"
    magick "$ORIG_FILE" -resize 32x32      "$DEST_FOLDER/icon_16x16@2x.png"
    magick "$ORIG_FILE" -resize 32x32      "$DEST_FOLDER/icon_32x32.png"
    magick "$ORIG_FILE" -resize 64x64      "$DEST_FOLDER/icon_32x32@2x.png"
    magick "$ORIG_FILE" -resize 128x128    "$DEST_FOLDER/icon_128x128.png"
    magick "$ORIG_FILE" -resize 256x256    "$DEST_FOLDER/icon_128x128@2x.png"
    magick "$ORIG_FILE" -resize 256x256    "$DEST_FOLDER/icon_256x256.png"
    magick "$ORIG_FILE" -resize 512x512    "$DEST_FOLDER/icon_256x256@2x.png"
    magick "$ORIG_FILE" -resize 512x512    "$DEST_FOLDER/icon_512x512.png"
    magick "$ORIG_FILE" -resize 1024x1024  "$DEST_FOLDER/icon_512x512@2x.png"
}

create_icns_file()
{
    iconutil -c icns $2 
}

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

src="../Assets/Icons/AppIcon.png"
des1="../Assets/Icons/AppIcon.iconset"
des2="../Assets/Icons/AppIcon.icns"

mkdir -p "$des1"
create_iconset "$src" "$des1"
create_icns_file "$des2" "$des1"
