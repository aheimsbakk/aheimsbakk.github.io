Title: Use GitHub to host a Pelican blog
Date: 2015-01-15
Category: blog
Tags: howto, pelican
Slug: pelican-github
Author: arnulf
Status: draft

[github]: https://github.io

* Create a git repository 

    ```bash
    mkdir blog
    cd blog
    git init
    touch README.md
    git add README.md 
    git commit -a -m "initial commit"

    ```

* Create a working branch for our blog, the master branch will be the blog content

    ```bash
    git branch blog
    git checkout blog
    ```

* Initialize the blog with `pelican-quickstart`

    ```bash
    pelican-quickstart

    Welcome to pelican-quickstart v3.4.0.

    This script will help you create a new Pelican-based website.

    Please answer the following questions so this script can generate the files
    needed by Pelican.
        
    > Where do you want to create your new web site? [.] 
    > What will be the title of this web site? My Blog
    > Who will be the author of this web site? John Doe
    > What will be the default language of this web site? [en] 
    > Do you want to specify a URL prefix? e.g., http://example.com   (Y/n) n
    > Do you want to enable article pagination? (Y/n) 
    > How many articles per page do you want? [10] 
    > Do you want to generate a Fabfile/Makefile to automate generation and publishing? (Y/n) 
    > Do you want an auto-reload & simpleHTTP script to assist with theme and site development? (Y/n) 
    > Do you want to upload your website using FTP? (y/N) 
    > Do you want to upload your website using SSH? (y/N) 
    > Do you want to upload your website using Dropbox? (y/N) 
    > Do you want to upload your website using S3? (y/N) 
    > Do you want to upload your website using Rackspace Cloud Files? (y/N) 
    > Do you want to upload your website using GitHub Pages? (y/N) y
    > Is this your personal page (username.github.io)? (y/N) y
    Done. Your new project is available at /tmp/blog
    ```

###### vim: set syn=markdown spell spl=en:
