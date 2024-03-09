# SVN-Service

[![Docker Image](https://img.shields.io/badge/docker%20image-available-green.svg)](https://hub.docker.com/r/lsclabs/svn-service/)

As we need a subversion service in our environment we start to build a svn service from scratch.
Inspired by smemberson, we started by using his prepared alpine linux and started to implement the layers.

## Use Case

The image should offering a subversion service that can be accessed via web (http:) or svn (svn:),
 has an authentication and authorisation mechanism and should be able to organise the repositories in subfolders / areas.
The access should be possible via the protocols svn:// and http:// (https:// is solved via a proxy mechanism)

## Architecture

Based on a small **alpine** image and S6 process management (see [here](https://github.com/smebberson/docker-alpine) for details). additional services are installed in this image:

- apache server with svn extension
- svn server
- svn administrative gui

## Configuration

### Ports and addresses of the container

| Port | Protocol | Address | Function  |
| :--- | -------- | ------- | --------- |
| 80   | http:    | /       | Root of the repositories         |
| 80   | http:    | /\<*AreaName*> | Area root - see SVN_Areas |
| 80   | http:    | /svnadmin      | svnAdmin interface        |
| 3690 | svn:     | /              | access to the repositories via svn:// |

### Vars

| Var       | Sample Content     | Function           |
| :-------- | :----------------- | :----------------- |
| SVN_Areas | Projects Libraries | Names of the areas, spearated with a blank (' '). For each of this Area, a directory, a authentication section and a apache mod entry will be created at (each) startup. |

### Volumes

You need 3 docker volumes, otherwise you will loose your data. Either specify a container, or map the data to the hosting machine (see parameter docker run -v xxx:yyyy ).

- Users with passwords for authentification.
- User subversion authorisation.
- Subversion repositories data.
- Configuration of the svnadmin gui.

|Local path         | Function|
|----------------   |----------|  
|/etc/subversion    | User authentification and authorisation (subversion)|
|/home/svn          | root path of all subversion repositories
|/opt/svnadmin/data | Config data of the svnadmin interface

## Run the image (sample)

The following sample runs the image, maps the ports 1:1 to the host and maps the 3 volumes to named persistent docker volumes.

```en
docker run -d --name svn-service -p 80:80 -p 3690:3690 -v svn_repos:/home/svn -v svn_config:/etc/subversion -v svn_admin_config:/opt/svnadmin/data lsclabs/svn-service
```

## Using the running container

When you start the container the first time, no user, no repository is in place. As the webserver is configured to ask for user credentials and no user is in place you have to create a user first, before you can start using and accessing the repositories.
In the steps, the hostname is set to **localhost** and the port is **80**. Use your hostname and your ports as you set it in step "Run the image".

### Step - prepare svnadmin

Go to [http://localhost:80/svnadmin](http://localhost:80/svnadmin) and a panel will apear that has to be filled with the necessary information on the first call. This image already filled the elements with the defaults mostly matching for this image.
Change if you want to use LDAP for authentication instead, or if you have special requirements.
Press "test" on the elements to ensure all data is in place.

Now save the configuration and a panel will apear that a default user "admin" with the password "admin" has been created.

### Step - create the users

In the svnadmin panel, create the user(s) that should have access to the repositories.

### Step - create repositories

Now you can create the repositories in the svnadmin gui and assign user that have access...
