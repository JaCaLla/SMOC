#!/bin/zsh


#Archive
xcodebuild clean archive \
  -project SMOC.xcodeproj \
  -scheme SMOC \
  -configuration Debug \
  -archivePath build/SMOC.xcarchive


