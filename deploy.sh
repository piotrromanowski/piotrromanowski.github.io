# build the site
hugo

# move to tmp directory
tmpdir=$(mktemp -d)
echo "moving to $tmpdir"
mv public/* $tmpdir/

# checkout master and copy new files
git checkout master
rm -fr *
mv $tmpdir/* .
