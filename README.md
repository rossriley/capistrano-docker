# Capistrano - Docker Appliance Deploy

This project aims to make it simple to deploy multiple apps inside Docker containers to an overall Docker Host.

### Opinionated File Structure

To make the process as simple as possible this project specifies an opinianated file structure, it will be much easier to start with a clean slate rather than trying to backport this to legacy file setup.

Apps are namespaced by an account and an application, in a similar concept to Github account/repo structure.

### Persistent Data Support

There is support for persistent storage via configuration of volumes. Multiple volumes are supported for each project.