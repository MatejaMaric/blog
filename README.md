# About this project

This code is used to build [my website](https://matejamaric.com) using [Hugo](https://gohugo.io/).

It doesn't use any prebuilt theme. Source Markdown files are in `content` directory.
The way site is build is described in `layouts` directory.
General structure and navbar of every page is described in `layouts/_default/baseof.html` template.
Structure of blog posts is described in `layouts/blog/single.html`.

# How to build

Install [Hugo](https://gohugo.io/) and just run `hugo` command which will generate `public` directory 
that contains the files you can host pretty much anywhere.

You can also run `hugo server` which will start development web server on <http://localhost:1313>.
