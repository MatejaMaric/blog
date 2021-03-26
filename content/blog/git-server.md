---
title: "Set up your own Smart HTTP Git Server with Gitolite, Cgit and Apache"
date: 2020-08-10
lastmod: 2020-08-10
description: "This guide is for people want to setup their own git server but don’t want something as big as GitLab or Gitea, and don’t want something overly simple like bare git repository over SSH."
slug: "git-server"
draft: false
---

This guide is for people want to setup their own git server but don't want something as big as GitLab or Gitea, 
and don't want something overly simple like [bare git repository over SSH](https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server).
Also, it is made on the assumption that you know how to setup and use Apache with https and virtual hosts, 
and SSH server with public key authentication. Your gitolite user will be available over SSH so make sure it is secured.

If you follow this guide, you will have a git server with read-write access over SSH and read access over HTTPS.
Your repositories will also be displayed using cgit web interface.
Gitolite will give you the ability to easily add new repositories and manage complex permissions, 
ideal when you have to work with multiple people on a same project.
Gitolite also works very well with cgit and git-http-backend. 
For example, if you make a repository that is not readable by everyone, 
gitolite won't add it to `projects.list` which cgit uses to decide what repositories to display, 
it also won't add `git-deamon-export-ok` file in repository directory, 
which git-http-backend uses to decide whether it should serve a repository over http.

## Preparations 

First install necessary software. Package python-pygments is used by cgit for syntax highlighting. 
**Check optional dependencies for cgit, you probably want to add all of them.**

	pacman -Sy --needed gitolite cgit python-pygments

We will use [git-http-backend](https://git-scm.com/docs/git-http-backend) CGI program (it is part of the git package) to serve our repositories as read only over https. 
Since CGI programs are ran by default Apache user (http on my system, check your `httpd.conf`) and our repositories will belong to the gitolite user, 
we will add http user to gitolite group to later allow it to access repositories. 
Cgit is also a CGI program that needs to be able to access repositories.

	usermod -aG gitolite http

You will also need to enable `mod_cgi`, `mod_alias` and `mod_env` in your Apache configuration, since we are using CGI programs.

## Setting up gitolite

First you will need to copy your public ssh key to your server and rename it to `username.pub` .
Then you will copy it to gitolite user's home directory. You can use this command: 

	install -o gitolite -g gitolite -m 640 username.pub /var/lib/gitolite/

Per default gitolite uses umask of 077, meaning that only gitolite user can read, write and execute gitolite files. 
Since we want users in gitolite group to be able to read and execute gitolite files, we will need to set umask that gitolite uses to 027. 
However, when we run gitolite setup it uses default `.gitolite.rc` configuration file if it can't find one. 
We can of course change directories it made with `chmod -R g+rX /var/lib/gitolite/repositories`, but why not do it right the first time? 

Generate `.gitolite.rc` with command `gitolite print-default-rc > .gitolite.rc` .
Then change lines 21 and 24 to `UMASK => 0027,` and `GIT_CONFIG_KEYS => '.*',` respectively. 
We changed line 24 so that we could use gitweb keys in gitolite-admin repository to tell cgit who is repository owner and repository description.

This is how your `.gitolite.rc` should look like without comments, you should of course keep comments, they are useful.

	%RC = (
	    UMASK                   =>  0027,
	    GIT_CONFIG_KEYS         =>  '.*',
	    LOG_EXTRA               =>  1,
	    ROLES => {
		READERS                 =>  1,
		WRITERS                 =>  1,
	    },
	    ENABLE => [
		    'help',
		    'desc',
		    'info',
		    'perms',
		    'writable',
		    'ssh-authkeys',
		    'git-config',
		    'daemon',
		    'gitweb',
	    ],
	);
	1;

You can copy it to gitolite user's home directory.

	install -o gitolite -g gitolite -m 640 .gitolite.rc /var/lib/gitolite/

Now we are done with configuring gitolite and we can actually set it up. Login to gitolite user and run gitolite setup.

	sudo -iu gitolite
	gitolite setup -pk username.pub
	exit

Now, we finished setting up gitolite. 
You can use `git clone ssh://gitolite@git.your-domain.com:port/gitolite-admin` on your client machine to clone gitolite administrator repository. 
In gitolite-admin repository you have `conf` and `keydir` directories. `keydir` keeps public keys for all available users, 
you can of course have [multiply keys per user](https://gitolite.com/gitolite/basic-admin.html#multiple-keys-per-user).
You can use `gitweb.owner` and `gitweb.description` to set repository owner and description in cgit.
Cgit can only display repositories in `projects.list` file and git-http-backend can only export them if git-deamon-export-ok file is present,
 in other words, only if it's readable by everyone (`R = @all`).  
Here you have an example `gitolite.conf`:

	repo gitolite-admin
		RW+     =   username

	repo testing
		RW+     =   username
		R       =   @all
		config gitweb.owner = Your Name
		config gitweb.description = Simple testing repo

You can do bunch of things in gitolite and they are explained in great detail on it's [website](https://gitolite.com/gitolite/basic-admin.html).

## Configuring cgit

Configuration file below is quite self explanatory so I won't go over it. 
Edit it per your needs, just make sure that `scan-path` is at the end of the file. 
You can find explanation for each line in [cgitrc(5)](https://git.zx2c4.com/cgit/tree/cgitrc.5.txt) man page.
Files (css, icons) that cgit uses can be found at `/usr/share/webapps/cgit/` .
You can install this configuration file using `install -o root -g root -m 644 cgitrc /etc/` .

	css=/cgit-css/cgit.css
	logo=/cgit-css/cgit.png
	favicon=/cgit-css/favicon.ico

	source-filter=/usr/lib/cgit/filters/syntax-highlighting.py
	about-filter=/usr/lib/cgit/filters/about-formatting.sh
	root-title=Yours repositories
	root-desc=Here you can find all my public projects.
	snapshots=tar.gz zip

	#settings
	#cache-size=100
	clone-url=https://git.your-domain.com/$CGIT_REPO_URL

	#default
	enable-index-owner=1

	#not default
	enable-index-links=1
	remove-suffix=1

	#nice to have...
	enable-blame=1
	enable-commit-graph=1
	enable-log-filecount=1
	enable-log-linecount=1
	branch-sort=age

	# if you do not want that webcrawler (like google) index your site
	# robots=noindex, nofollow

	# if cgit messes up links, use a virtual-root. For example, cgit.example.org/ has this value:
	#virtual-root=/

	# Allow using gitweb.* keys
	enable-git-config=1

	##
	## List of common mimetypes
	##
	mimetype.gif=image/gif
	mimetype.html=text/html
	mimetype.jpg=image/jpeg
	mimetype.jpeg=image/jpeg
	mimetype.pdf=application/pdf
	mimetype.png=image/png
	mimetype.svg=image/svg+xml

	##
	## Search for these files in the root of the default branch of repositories
	## for coming up with the about page:
	##
	readme=:README.md
	readme=:readme.md
	readme=:README.mkd
	readme=:readme.mkd
	readme=:README.rst
	readme=:readme.rst
	readme=:README.html
	readme=:readme.html
	readme=:README.htm
	readme=:readme.htm
	readme=:README.txt
	readme=:readme.txt
	readme=:README
	readme=:readme
	readme=:INSTALL.md
	readme=:install.md
	readme=:INSTALL.mkd
	readme=:install.mkd
	readme=:INSTALL.rst
	readme=:install.rst
	readme=:INSTALL.html
	readme=:install.html
	readme=:INSTALL.htm
	readme=:install.htm
	readme=:INSTALL.txt
	readme=:install.txt
	readme=:INSTALL
	readme=:install


	#gitolite repos
	project-list=/var/lib/gitolite/projects.list
	scan-path=/var/lib/gitolite/repositories

## Configuring Apache

And finally, the last step, connecting everything using Apache. 

`GIT_PROJECT_ROOT` variable is used by git-http-backend to locate repositories.  
`ScriptAliasMatch` part I took from [git-http-backend](https://git-scm.com/docs/git-http-backend)
and changed it so that it only allows http clients to `git pull` but not to `git push` . 
`Alias` part is where cgit should look for additional files (css, png), if you want to change it don't forget to change `/etc/cgitrc` . 
`ScriptAlias` is part where cgit actually executes.  
`Files` and `Directory` entries just tell Apache that it can access given files.  
For more information check out [Apache documentation](http://httpd.apache.org/docs/2.4/), 

You can just append this to your `httpd-vhosts-le-ssl.conf` file, you should of course edit it per your needs.

	<IfModule mod_ssl.c>
	<VirtualHost *:443>
	#    ServerAdmin admin@your-domain.com
	    DocumentRoot "/srv/http/git.your-domain.com"
	    ServerName git.your-domain.com

	    SetEnv GIT_PROJECT_ROOT /var/lib/gitolite/repositories/

	    ScriptAliasMatch \
		"(?x)^/(.*/(HEAD | \
			info/refs | \
			objects/info/[^/]+ | \
			git-upload-pack))$" \
		    /usr/lib/git-core/git-http-backend/$1

	    Alias /cgit-css "/usr/share/webapps/cgit/"
	    ScriptAlias / "/usr/lib/cgit/cgit.cgi/"


	    <Files "git-http-backend">
		  Require all granted
	    </Files>

	    <Directory "/usr/share/webapps/cgit/">
		  AllowOverride None
		  Options None
		  Require all granted
	    </Directory>

	    <Directory "/usr/lib/cgit/">
		  AllowOverride None
		  Options ExecCGI FollowSymlinks
		  Require all granted
	    </Directory>

	    ErrorLog "/var/log/httpd/git.your-domain.com-error_log"
	    CustomLog "/var/log/httpd/git.your-domain.com-access_log" common

	SSLCertificateFile /etc/letsencrypt/live/git.your-domain.com/fullchain.pem
	SSLCertificateKeyFile /etc/letsencrypt/live/git.your-domain.com/privkey.pem
	Include /etc/letsencrypt/options-ssl-apache.conf
	</VirtualHost>
	</IfModule>

Don't forget to restart Apache for changes to take effect!
That's all, hope you like your new git server!

If you found any mistakes, or that something is outdated, badly explained or you have something to add,
feel free to [contact me](/contact/) or contribute to [this site's repository](https://github.com/MatejaMaric/blog).

## Resources
- <https://wiki.archlinux.org/index.php/Git_server>
- <https://wiki.archlinux.org/index.php/Cgit>
- <https://gitolite.com/gitolite/index.html>
- <https://git-scm.com/docs/git-http-backend>
- <https://joel.porquet.org/wiki/hacking/cgit_gitolite_lighttpd_archlinux/>
- <https://git.seveas.net/apache-gitweb-cgit-smart-http.html>
