
default:
	xcodebuild -configuration Release -target OpenTXL -sdk iphonesimulator
	xcodebuild -configuration Release -target OpenTXL -sdk iphoneos
	sh ../Scripts/iOSFramework.sh

clean:
	-rm -rf build/*
