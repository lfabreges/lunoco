#!/bin/sh

base="icon-1024.png"

convert "$base" -resize '57x57'     -unsharp 1x4 "Icon.png"

convert "$base" -resize '40x40'     -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-40.png"
convert "$base" -resize '58x58'     -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-58.png"
convert "$base" -resize '76x76'     -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-76.png"
convert "$base" -resize '80x80'     -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-80.png"
convert "$base" -resize '87x87'     -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-87.png"
convert "$base" -resize '120x120'   -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-120.png"
convert "$base" -resize '152x152'   -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-152.png"
convert "$base" -resize '167x167'   -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-167.png"
convert "$base" -resize '180x180'   -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-180.png"
convert "$base" -resize '1024x1024' -unsharp 1x4 "Images.xcassets/AppIcon.appiconset/Icon-1024.png"
