# syntax=docker/dockerfile:1
#
# SVN-Service 
#
# (c) 2022 LSC-Labs
#
# Alpine Linux with s6 service management - latest version
# Additional layers :
# - Apache2 with svn extension
# - SVN server
# - SVN admin
#
# Customizing vars at runtime : 
# =============================
# SVN_Areas   Names of areas separated with ' ' like : "Projects Libraries ..."
#             this Areas will be created in apache config, filesystem and subversion access control file
#
# Expected filesystems :
# ======================
# /etc/subversion     contains the authentication and authorization data for the system
# /home/svn           contains the maintained subversion repositories
#
FROM smebberson/alpine-base:3.2.0

LABEL "vendor"="LSC-Labs"

# -----------------------------------------------------
# Add services configurations
# -----------------------------------------------------
ADD rootFS/etc/services.d /etc/services.d

# Set HOME in non /root folder
ENV HOME /home

# Steps to be done:
# - Install apache
# - Install subverion
# - Install php7 modules (base for svn-admin)
# - Enable LDAP (in php module)
# - Create directory /home/svn  (repositories)
# - Create directory /etc/subversion (authentication and authorisation)
# - Create an empty passwd (authentication)
# - Install SVNAdmin from github

# -----------------------------------------------------
# Install the needed packages and enable LDAP in php
# =====================================================
RUN apk add --no-cache apache2 apache2-utils apache2-webdav mod_dav_svn &&\
	apk add --no-cache subversion &&\
	apk add --no-cache wget unzip php7 php7-apache2 php7-session php7-json php7-ldap &&\
	apk add --no-cache php7-xml &&\	
	sed -i 's/;extension=ldap/extension=ldap/' /etc/php7/php.ini &&\
	mkdir -p /run/apache2/

# -----------------------------------------------------
# Make the subversion config area with the passwd file
# =====================================================
RUN mkdir -p  /etc/subversion 				&&\
	touch     /etc/subversion/passwd 		&&\
	chmod a+w /etc/subversion/passwd

# -----------------------------------------------------
# Create the area for the Subversion repositories
# =====================================================
ENV SVN_Repositories 		/data/repos/svn

RUN	mkdir -p   "${SVN_Repositories}" 	&&\
	chmod a+w  "${SVN_Repositories}"
	
# -----------------------------------------------------
# Install the SVNAdmin module (currently 1.6.2)
# =====================================================
ENV SVN_Admin_Data_Dir 		/opt/svnadmin/data
ENV SVN_Admin_Templates_Dir /opt/LSC/SvnAdminDataTemplates

RUN wget --no-check-certificate https://github.com/mfreiholz/iF.SVNAdmin/archive/stable-1.6.2.zip &&\
	unzip stable-1.6.2.zip -d /opt 								&&\
	rm stable-1.6.2.zip 										&&\
	mv /opt/iF.SVNAdmin-stable-1.6.2     /opt/svnadmin 			&&\	
	chmod -R a+w "${SVN_Admin_Data_Dir}"						&&\
	ln -s /opt/svnadmin /var/www/localhost/htdocs/svnadmin 		
	

# Fixing https://github.com/mfreiholz/iF.SVNAdmin/issues/118
ADD svnadmin/classes/util/global.func.php /opt/svnadmin/classes/util/global.func.php

RUN mkdir -p "${SVN_Admin_Templates_Dir}" 									&&\
	echo "copy from ${SVN_Admin_Data_Dir} to ${SVN_Admin_Templates_Dir}" 	&&\
	chmod -R a+w "${SVN_Admin_Templates_Dir}" 								&&\
	ls -al "${SVN_Admin_Data_Dir}"											&&\
	cp "/opt/svnadmin/data/.gitignore" 		"${SVN_Admin_Templates_Dir}"	&&\
	cp "/opt/svnadmin/data/.htaccess" 		"${SVN_Admin_Templates_Dir}"	&&\
	cp "/opt/svnadmin/data/config.tpl.ini"  "${SVN_Admin_Templates_Dir}" 	&&\
	ls -al "${SVN_Admin_Templates_Dir}"

# ----------------------------------------------------------------
# Expose ports for http and custom protocol access (http / svn )
# 443 is not hosted, use a proxy with cert management.
# ----------------------------------------------------------------
EXPOSE 80 3690
