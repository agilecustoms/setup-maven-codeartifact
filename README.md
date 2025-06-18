# About
Allows to use Maven backed by AWS CodeArtifact repository in GitHub Actions:
1. Setup Java + Maven
2. Authorize in AWS Account with provided role
3. Generate CodeArtifact token and URL and put in env variables
4. Forge `settings.xml` and put in a place where Maven can find it

Designed to be used in your build workflow (when you need to access packages from CodeArtifact)
and also it a release workflow (when you publish packages in CodeArtifact).
It is recommended to use different IAM roles: `/ci/builder` and `/ci/publisher` respectfully.
For release workflow you likely want to update version in `pom.xml` file and add some git tags,
so please check the `agilecustoms/release` action - it represents a holistic release action (uses `setup-java-codeartifact` under the hood). 

This action is a combination of few other actions mainly `actions/setup-java` and `aws-actions/configure-aws-credentials`,
hence all parameters have prefix either `aws-` for authorization in aws or `java-` for java-specific settings

## Usage in build workflow
```yaml
jobs:
  Build:
    runs-on: ubuntu-latest
    permissions:
      id-token: write # to request JWT from GitHub OIDC provider
      contents: read # required for actions/checkout
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: agilecustoms/setup-java-codeartifact@1.0.0
        with:
          aws-account: 123456789012 # or use ${{ vars.AWS_ACCOUNT_DIST }}
          aws-region: us-east-1
          aws-role: ci/builder
          aws-codeartifact-domain: your-company-name
          java-version: 21

      - name: Maven build
        run: mvn verify --no-transfer-progress
```

## settings.xml


## using in local computer
(If I ever do `setup-node|python-codeartifact` action, it should be similar to this)
