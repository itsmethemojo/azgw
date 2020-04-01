# azgw
cli tool to retrieve kubectl config by login with azure AD and [heptio gangway](https://github.com/heptiolabs/gangway)

azgw uses [puppeteer](https://github.com/puppeteer/puppeteer/) in a docker container to do the whole login process in a headless chrome browser for you

## Requirements

* [docker](https://hub.docker.com/?overlay=onboarding)
* [git bash](https://gitforwindows.org/) (only on windows)

## get started

```
# download
wget https://raw.githubusercontent.com/itsmethemojo/azgw/master/azgw.sh
# make executable
chmod +x azgw.sh
# run
./azgw.sh --help
```
