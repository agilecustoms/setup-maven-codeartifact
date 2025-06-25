# About
Allows to use Maven backed by AWS CodeArtifact repository in GitHub Actions:
1. Setup Java + Maven
2. Authorize in AWS Account with a provided role
3. Generate CodeArtifact token and URL and put in env variables
4. Compose `settings.xml` and put in a place where Maven can find it

Designed to be used in your build workflow (when you need to access packages from CodeArtifact)
and also it a release workflow (when you publish packages in CodeArtifact).
It is recommended to use different IAM roles: `/ci/builder` and `/ci/publisher` respectfully.
For release workflow you likely want to update a version in `pom.xml` file and add some git tags,
so please check the `agilecustoms/release` action - it represents a holistic release action (uses `setup-maven-codeartifact` under the hood). 

This action is a combination of few other actions mainly `actions/setup-java` and `aws-actions/configure-aws-credentials`,
hence all parameters have prefix either `aws-` (for authorization in aws) or `java-` (for java-specific settings)

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
        uses: agilecustoms/setup-maven-codeartifact@1.0.0
        with:
          aws-account: ${{ vars.AWS_ACCOUNT_DIST }}
          aws-region: us-east-1
          aws-role: ci/builder # default 
          aws-codeartifact-domain: mycompany
          java-version: 21 # default

      - name: Maven build
        run: mvn verify --no-transfer-progress
```

## settings.xml for local development
Under the hood, this action generates [settings.xml](./ci.settings.xml) file with CodeArtifact repository and credentials. Note:
- maven central and its mirror are used as primary repositories for dependencies and plugins, your company CodeArtifact is in 3rd place
- your company repository id has format `{aws-codeartifact-domain}-maven`

With this knowledge, you can place a local version of [settings.xml](./local.settings.xml) on developers' machines
to give them read-only access to maven packages in corporate CodeArtifact.
As you can see this `settings.xml` file has two env variables: `ARTIFACT_STORE_HOST` and `ARTIFACT_STORE_TOKEN`.
Host is fixed (after you create CodeArtifact domain), you can place these two lines in your shell configuration (`.zshrc`, `.bashrc`):
```shell
export AWS_ACCOUNT_DIST=123456789012
export ARTIFACT_STORE_HOST="mycompany-$AWS_ACCOUNT_DIST.d.codeartifact.us-east-1.amazonaws.com"
```
For `ARTIFACT_STORE_TOKEN` you'd need to generate it once a day with command like this:
```shell
TOKEN=$(aws codeartifact get-authorization-token --domain mycompany --query authorizationToken --output text)
export ARTIFACT_STORE_TOKEN=$TOKEN
```

