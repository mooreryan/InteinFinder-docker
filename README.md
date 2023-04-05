# InteinFinder Docker Image

Repository for the InteinFinder docker image and scripts.

## Scripts

The `InteinFinder-docker` script can be used to cut down on the boilerplate of using InteinFinder with docker.

- Find it in the `scripts` directory.
- It mounts the directory from which you are running the script.
- It uses that directory as the working directory in the container.
- It sets the user to the current user and group (using `id`)
- Depends on `bash`,  `pwd`, and `id` commands being present
  - If you are on a system without these commands (or w/o `bash`) then you will need to run the docker commands manually

## Hacking

For new releases...

Cut a release on the main InteinFinder GitHub. Then, in this repository, do this:

- Update the version and commit in the justfile
- Run `just update`...this will run a few steps
  - Build the image (`just build`)
  - Update the IF docker shell script (`just write_if_docker_script`)
  - Test new image (`just test`)
  - Push it with push script (`just push`)
