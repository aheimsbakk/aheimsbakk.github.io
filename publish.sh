#!/bin/bash

if ! which rst2html.py > /dev/null
then
  echo "**"
  echo "** Install missing dependency to use reStructuredText"
  echo "**"

  pip install --user rst2html
fi

echo "**"
echo "** Generate blog"
echo "**"

case "$(uname -p)" in
  x86_64|aarch64)
    ./hugo-$(uname -p)
    ;;
  unknown)
    ./hugo-aarch64
    ;;
esac

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

