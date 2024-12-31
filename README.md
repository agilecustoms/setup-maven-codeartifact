# About
Reusable GitHub Action `prepare-java`
1. Setup Java + Maven
2. Login to AWS Account "Shared" with role "builder"
3. Generate CodeArtifact token and URL and put in env variables
4. Forge `settings.xml` and put in a place where Maven can find it

## Test via 'test' workflow
1. Make a branch 'feature' (this repo unlikely incur many changes)
2. Push branch and get feedback
3. Once satisfied, revert any debug changes and merge to `main` 

## Test via local run
This doesn't work yet, need to find out how to overcome "AWS Login" step
```shell
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j Test --container-architecture linux/amd64
```

## Release
```shell
git tag -a -m "Release description: use shared account from org env variables" v2.0.0
git push --follow-tags
```