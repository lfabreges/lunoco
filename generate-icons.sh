#!/bin/sh

base="icon"

##
# Android
##

convert "${base}.png" -resize '48x48' -unsharp 1x4 "AndroidResources/res/mipmap-mdpi/ic_launcher.png"
convert "${base}.png" -resize '72x72' -unsharp 1x4 "AndroidResources/res/mipmap-hdpi/ic_launcher.png"
convert "${base}.png" -resize '96x96' -unsharp 1x4 "AndroidResources/res/mipmap-xhdpi/ic_launcher.png"
convert "${base}.png" -resize '144x144' -unsharp 1x4 "AndroidResources/res/mipmap-xxhdpi/ic_launcher.png"
convert "${base}.png" -resize '192x192' -unsharp 1x4 "AndroidResources/res/mipmap-xxxhdpi/ic_launcher.png"

convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_background.png" -resize '108x108' \
  -unsharp 1x4 "AndroidResources/res/mipmap-mdpi/ic_launcher_background.png"
convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_foreground.png" -resize '108x108' \
  -unsharp 1x4 "AndroidResources/res/mipmap-mdpi/ic_launcher_foreground.png"
convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_background.png" -resize '162x162' \
  -unsharp 1x4 "AndroidResources/res/mipmap-hdpi/ic_launcher_background.png"
convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_foreground.png" -resize '162x162' \
  -unsharp 1x4 "AndroidResources/res/mipmap-hdpi/ic_launcher_foreground.png"
convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_background.png" -resize '216x216' \
  -unsharp 1x4 "AndroidResources/res/mipmap-xhdpi/ic_launcher_background.png"
convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_foreground.png" -resize '216x216' \
  -unsharp 1x4 "AndroidResources/res/mipmap-xhdpi/ic_launcher_foreground.png"
convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_background.png" -resize '324x324' \
  -unsharp 1x4 "AndroidResources/res/mipmap-xxhdpi/ic_launcher_background.png"
convert "AndroidResources/res/mipmap-xxxhdpi/ic_launcher_foreground.png" -resize '324x324' \
  -unsharp 1x4 "AndroidResources/res/mipmap-xxhdpi/ic_launcher_foreground.png"

##
# iOS
##

convert "${base}.png" -resize '40x40' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-40.png"
convert "${base}.png" -resize '58x58' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-58.png"
convert "${base}.png" -resize '76x76' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-76.png"
convert "${base}.png" -resize '80x80' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-80.png"
convert "${base}.png" -resize '87x87' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-87.png"
convert "${base}.png" -resize '120x120' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-120.png"
convert "${base}.png" -resize '152x152' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-152.png"
convert "${base}.png" -resize '167x167' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-167.png"
convert "${base}.png" -resize '180x180' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-180.png"
convert "${base}.png" -resize '1024x1024' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-1024.png"

convert "${base}.png" \
  \( +clone  -alpha extract \
    -draw 'fill black polygon 0,0 0,180 180,0 fill white circle 180,180 180,0' \
    \( +clone -flip \) -compose Multiply -composite \
    \( +clone -flop \) -compose Multiply -composite \
  \) -alpha off -compose CopyOpacity -composite "${base}-rounded.png"

convert "${base}-rounded.png" -resize '256x256' -unsharp 1x4 "images/icon.png"
convert "${base}-rounded.png" -resize '512x512' -unsharp 1x4 "images/icon@2x.png"
convert "${base}-rounded.png" -resize '768x768' -unsharp 1x4 "images/icon@3x.png"
convert "${base}-rounded.png" -resize '1024x1024' -unsharp 1x4 "images/icon@4x.png"

rm -f "${base}-rounded.png"
