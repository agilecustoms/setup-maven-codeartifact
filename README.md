## Configure access (one time)
1. Go to repository settings
2. In the left sidebar, click  Actions, then click General
3. Under Access, choose one of the access settings:
- Accessible from repositories in the 'agilecustoms' organization
4. Click Save to apply the settings.

## Release
```shell
git tag -a -m "Description of this release" v1
git push --follow-tags
```