# prepare-java-build
Reusable GitHub Action `prepare-java-build`
1. Setup Java + Maven
2. Login to AWS with role "deployer" in shared account
3. Generate CodeArtifact token, so Maven can download dependencies

## Configure access (one time)
1. Go to repository settings
2. In the left sidebar, click  Actions, then click General
3. Under Access, choose one of the access settings:
- Accessible from repositories in the 'agilecustoms' organization
4. Click Save to apply the settings

## Release
```shell
git tag -a -m "Release description: use shared account from org env variables" v2.0.0
git push --follow-tags
```