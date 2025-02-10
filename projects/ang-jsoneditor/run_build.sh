#!/bin/sh
#
# Copy build product files to installation vm for testing.
# Must run this from the trilynx-lib-dev-ng/build-util folder

getVersion() {
	local versionFile version

	# get the version from the package.json file so version is only in one place
	versionFile="package.json" 
	# find the version line and remove everything in the line except the version numbers
	# each of these characters are removed, their order or number of repeats aren't important
	version=$(grep 'version' $versionFile | tr -d '"version: ,')
	echo "$version"
}

parseCommandLine() {
        local opt
        optstring="htS"
        while getopts $optstring opt; do
                # echo "Command line option is ${opt}"
                case $opt in
                        S) # -S  Create and copy tarball file to S3
							COPY_TAR_TO_S3=true
							CREATE_TARBALL=true
                                ;;
                        t) # -t  create the tarball
							CREATE_TARBALL=true
							echo "Creating tarball"
                                ;;
                        h) # -h  prints usage options
							echo "ang-jsoneditor tarball builder"
							echo "-h Prints this list of options"
							echo "-S Create tarball and copy to S3"
							echo "-t Create tarball"
							exit 0
                                ;;
		esac
	done
}

PROJECT_NAME="ang-jsoneditor"

#get version from the package.json file
PRODUCT_VERSION=$(getVersion)

# S3 location if copying to S3 is specified
S3LOC="trilynx-systems-software/trilynx-systems-npm/package/ang-jsoneditor/$PRODUCT_VERSION"
S3LATEST_LOC="trilynx-systems-software/trilynx-systems-npm/package/ang-jsoneditor/latest"

# tarball filename
TARFILE="ang-jsoneditor-$PRODUCT_VERSION.tgz"

COPY_TAR_TO_S3=false
CREATE_TARBALL=false

parseCommandLine $@

echo "Actions:"
echo "Create library for $PROJECT_NAME, version $PRODUCT_VERSION"

if [ "$CREATE_TARBALL" = true ]; then
	echo "Create tarball."
fi

if [ "$COPY_TAR_TO_S3" = true ]; then
	echo "Copy tarball $TARFILE to $S3LOC."
fi

# build
cd ..
ng build "$PROJECT_NAME" --configuration production

# Create tarball
if [ "$CREATE_TARBALL" = true ]; then
	# change to distribution version of library
	cd ../dist/$PROJECT_NAME

	# create tarball
	npm pack

	# Copy to S3
	if [ "$COPY_TAR_TO_S3" = true ]; then
		aws s3 cp $TARFILE s3://$S3LOC/
		aws s3 rm s3://$S3LATEST_LOC/*
		aws s3 cp $TARFILE s3://$S3LATEST_LOC/
	fi
fi
