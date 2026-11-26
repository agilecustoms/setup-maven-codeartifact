# setup-maven-codeartifact

A GitHub action used as pre-requisite step in **build** workflows (`mvn package`)
 to configure maven to pull dependencies from AWS CodeArtifact.
Also used as pre-requisite step in **release** workflows (`mvn deploy`) to push artifacts to AWS CodeArtifact

What it does:
1. Setup Java + Maven
2. Authorize in AWS Account with a provided role
3. Generate CodeArtifact token and URL and put in env variables
4. Compose `settings.xml` and put in `~/.m2`

## Usage

Below is an example of how to use this action in the **build** workflow
(when you need to pull artifacts from AWS CodeArtifact):
For release/publish workflows use [agilecustoms/release](https://github.com/agilecustoms/release)

```yaml
jobs:
  Build:
    runs-on: ubuntu-latest
    permissions:
      id-token: write # to request JWT from GitHub OIDC provider
      contents: read # required for actions/checkout
    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Setup Maven
        uses: agilecustoms/setup-maven-codeartifact@v2
        with:
          aws-account: ${{ vars.AWS_ACCOUNT_DIST }}
          aws-region: us-east-1
          aws-role: ci/builder # default 
          aws-codeartifact-domain: mycompany
          java-version: 21 # default

      # now you can run maven while pulling dependencies from AWS CodeArtifact
      - name: Maven build
        run: mvn verify --no-transfer-progress
```

**release** workflow is more complex, it requires version bump in `pom.xml` and setting git tags.
To release/publish artifacts in AWS CodeArtifact please use [agilecustoms/release][release] action
and specifically [AWS CodeArtifact Maven][release-maven] section

For build and release workflows it is recommended to use different IAM roles: `/ci/builder` and `/ci/publisher`.
Builder has read-only access to CodeArtifact, while publisher has write access.
Below there are two terraform modules that have all necessary permissions to work with CodeArtifact:
- **ci-builder** - [github][ci-builder-github] - [terraform registry module][ci-builder-registry]
- **ci-publisher** - [github][ci-publisher-github] - [terraform registry module][ci-publisher-registry]

And this is [example][ci-publisher-role]
 how to create an AWS IAM role based on these policies with a password-less trust policy,
 so you do not need to store `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your repository secrets

[release]: https://github.com/agilecustoms/release
[release-maven]: https://github.com/agilecustoms/release/blob/main/docs/artifact-types/aws-codeartifact-maven.md
[ci-builder-github]: https://github.com/agilecustoms/terraform-aws-ci-builder
[ci-builder-registry]: https://registry.terraform.io/modules/agilecustoms/ci-builder/aws/latest
[ci-publisher-github]: https://github.com/agilecustoms/terraform-aws-ci-publisher
[ci-publisher-registry]: https://registry.terraform.io/modules/agilecustoms/ci-publisher/aws/latest
[ci-publisher-role]: https://github.com/agilecustoms/terraform-aws-ci-publisher?tab=readme-ov-file#how-to-create-a-role-with-this-policy
[setup-java]: https://github.com/actions/setup-java?tab=readme-ov-file#usage

### Inputs

This action is a combination of few other actions mainly `actions/setup-java` and
`aws-actions/configure-aws-credentials`.
All `java-*` inputs are pass through parameters to `actions/setup-java` action,
so please refer to [setup-java documentation][setup-java]

| Name                        | Required | Default       | Description                                                 |
|-----------------------------|----------|---------------|-------------------------------------------------------------|
| aws-account                 | yes      |               | AWS account number where the CodeArtifact domain is located |
| aws-codeartifact-domain     | yes      |               | CodeArtifact domain name                                    |
| aws-codeartifact-repository | no       | maven         | CodeArtifact repository name                                |
| aws-login                   | no       | _true_        | Login to AWS, _false_ if you handle AWS login separately    |
| aws-region                  | yes      |               | AWS region where the CodeArtifact domain is located         |
| aws-role                    | no       | ci/builder    | IAM role to assume for CodeArtifact access                  |
| java-cache                  | no       | maven         | Maven dependency cache, empty string `""` disables it       |
| java-cache-dependency-path  | no       | (see doc.)    | See description at [actions/setup-java][setup-java]         |
| java-distribution           | no       | temurin       | Java distribution, Temurin is pre-cached in ubuntu-latest   |
| java-setup                  | no       | true          | Setup Java with actions/setup-java, false if done outside   |
| java-version                | no       | 21            | Java version to use                                         |
| settings-mirrors            | no       |               | Maven settings.xml mirrors section (XML format)             |
| settings-pluginGroups       | no       |               | Maven settings.xml pluginGroups section (XML format)        |
| settings-pluginRepositories | no       | Maven Central | Plugin repositories (XML) placed in front of CodeArtifact   |
| settings-profile-properties | no       |               | Maven settings.xml profile properties section (XML format)  |
| settings-proxies            | no       |               | Maven settings.xml proxies section (XML format)             |
| settings-repositories       | no       | Maven Central | Maven repositories (XML) placed in front of CodeArtifact    |

Notes:
1. For `aws-account` it is recommended to have a dedicated AWS account (not dev, not prod) to store artifacts
   (S3 binaries, CodeArtifact, Docker images)
2. Default settings for `settings-pluginRepositories` and `settings-repositories` are good for projects
 that take 95% of dependencies from Maven Central and left 5% from corporate CodeArtifact.
 Some companies opt in to store all dependencies in CodeArtifact with Maven Central as an _upstream_.
 In this configuration you would want to set `settings-pluginRepositories` and `settings-repositories` to `""`

### Local development

Under the hood, this action generates a [settings.xml](./ci.settings.xml) file
with CodeArtifact repository and credentials.
Note:
- maven central and its mirror are used as primary and secondary repositories for dependencies and plugins,
  your company CodeArtifact is in 3rd place.
If you use CodeArtifact upstream feature,
feel free to remove maven central and its mirror from `repositories` and `pluginRepositories` sections
- your company repository id has format `{aws-codeartifact-domain}-{aws-codeartifact-repository}` like `mycompany-maven`

With this knowledge, you can place a local version of [settings.xml](./local.settings.xml) on developers' machines
to give them read-only access to maven packages in corporate CodeArtifact.
As you can see this `settings.xml` file has two env variables: `ARTIFACT_STORE_HOST` and `ARTIFACT_STORE_TOKEN`.
Host is fixed (after you create CodeArtifact domain), you can place these two lines 
in your shell configuration (`.zshrc`, `.bashrc`):
```shell
export AWS_ACCOUNT_DIST=123456789012
export ARTIFACT_STORE_HOST="mycompany-$AWS_ACCOUNT_DIST.d.codeartifact.us-east-1.amazonaws.com"
```
CodeArtifact token is _NOT_ long living, max lifetime is 12 hours.
So if you need to resolve new maven dependencies on local dev machine,
you'd need to regenerate `ARTIFACT_STORE_TOKEN` (at most once a day) with command like this:
```shell
TOKEN=$(aws codeartifact get-authorization-token --domain mycompany --query authorizationToken --output text)
export ARTIFACT_STORE_TOKEN=$TOKEN
```

### Security

If you ever find yourself generating and passing a secret in any of the `settings-*` inputs, please mask it first:

```yaml
jobs:
  Build:
    runs-on: ubuntu-latest
    permissions:
      id-token: write # to request JWT from GitHub OIDC provider
      contents: read # required for actions/checkout
    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Proxy with a secret
        id: proxy
        run: |
          # generate a SECRET
          PROXY_CONFIG="<config><username>abc</username><password>$SECRET</password></config>"
          echo "::add-mask::$PROXY_CONFIG"
          echo "CONFIG=$PROXY_CONFIG" >> "$GITHUB_OUTPUT"

      - name: Setup Java
        uses: agilecustoms/setup-maven-codeartifact@v2
        with:
          aws-account: ${{ vars.AWS_ACCOUNT_DIST }}
          aws-region: us-east-1
          aws-codeartifact-domain: mycompany
          settings-proxies: ${{ steps.proxy.outputs.CONFIG }}
```

## License

This project is released under the [MIT License](./LICENSE)

## Misc

- [Troubleshooting](./docs/troubleshooting.md)

## Articles

- [Software distribution in AWS](https://www.linkedin.com/pulse/software-distribution-aws-alexey-chekulaev-ubl0e)
- [GitFlow vs Build-and-deploy](https://www.linkedin.com/pulse/gitflow-build-and-deploy-alex-chekulaev-lvive)

## Acknowledgements

- https://github.com/s4u/maven-settings-action — first action I tried, but it doesn't support pluginRepositories
- https://github.com/whelk-io/maven-settings-xml-action — used this during 2024, then wrote my own action 
