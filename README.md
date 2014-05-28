# Capistrano - Docker Appliance Deploy

This project aims to make it simple to deploy multiple apps inside Docker containers to an overall Docker Host.

### Opinionated File Structure

To make the process as simple as possible this project specifies an opinianated file structure, it will be much easier to start with a clean slate rather than trying to backport this to legacy file setup.

Apps are namespaced by an account and an application, in a similar concept to Github account/repo structure.

### Persistent Data Support

There is support for persistent storage via configuration of volumes. Multiple volumes are supported for each project.

### Installation & Required Configuration

To get started you will need the following setup.

    1. A local git repo that stores your project file
    2. The root of the project needs a Dockerfile that handles the container build
    3. A remote server with Docker installed and a preferably empty filesystem for the specified user.
    4. A local Capfile that handles the configuration for the deploy.
    
Here's an example of the minimum requirements for your local Capfile.

```
require 'rubygems'
require 'bundler/setup'
require 'capistrano/setup'
require 'capistrano/docker'

set :namespace,         "yournamespace"
set :application,       "yourapp"
set :port,              "59999"
set :stage,             "production"

task :production do
    set :branch,        "master"
    server 'docker.yourserver.com', user: 'docker', roles: %w{host}
end

```