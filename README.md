# About
Reusable GitHub Action `prepare-java`
1. Setup Java + Maven
2. Login to AWS Account "Shared" with role "deployer"
3. Generate CodeArtifact token and URL and put in env variables
4. Forge `settings.xml` and put in a place where Maven can find it

## Test
```shell
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j {step}
```

## Release
```shell
git tag -a -m "Release description: use shared account from org env variables" v2.0.0
git push --follow-tags
```