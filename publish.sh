#!/bin/bash

echo "**"
echo "** Generate blog"
echo "**"

./hugo-$(uname -p)

echo "**"
echo "** Publish blog $(date -I)"
echo "**"

cd public
git add .
git commit -m "published @ $(date -I)"
git push origin HEAD:master
cd ..

echo "**"
echo "** Update submodule reference"
echo "**"

git add public
git commit -m "published @ $(date -I)"
git push

echo "**"
echo "** Done"
echo "**"

