---
title: Find duplicate files
date: 2014-04-13T21:00:00
draft: false
categories:
  - blog
tags:
  - bash
  - oneliner
---

Find all duplicate files in current and sub-directories with bash.

```bash
find -not -empty -type f -printf '%s\n' | sort -rn | uniq -d | xargs -I{} -n1 find -type f -size {}c -print0 | xargs -0 md5sum | sort | uniq -w32 --all-repeated=separate
```

Breakdown
---------

1. Find all non empty files and print out size.
2. Do a numeric sort on size list.
3. Print out only duplicate sizes.
4. One at a time run find on size and print file names.
5. Find md5sum of all files.
6. Alphabetical sort md5sums and file names.
7. Find all md5sums which repeats and print them in groups.

Alternatively
-------------

Or do it the easy way and install a tool for finding duplicates files. This tool is much faster than the oneliner above.

```bash
apt-get install fdupes
```

This does more or less the same thing as the oneliner.

```bash
fdupes -r .
```

