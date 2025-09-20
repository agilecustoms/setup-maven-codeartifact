# About

A GitHub action to build maven projects while pulling dependencies from AWS CodeArtifact

What it does:
1. Setup Java + Maven
2. Authorize in AWS Account with a provided role
3. Generate CodeArtifact token and URL and put in env variables
4. Compose `settings.xml` and put in `~/.m2`

## Usage

Below is an example of how to use this action in the **build** workflow.
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
        uses: actions/checkout@v5

      - name: Setup Java
        uses: agilecustoms/setup-maven-codeartifact@v1
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

This action is designed for use in a **build** workflow when you need to access packages from CodeArtifact.
In **release** workflow you need to bump a version in `pom.xml` file and add some git tags,
so please check the [agilecustoms/release](https://github.com/agilecustoms/release) action —
it represents a holistic release action (uses `setup-maven-codeartifact` under the hood)

For build and release workflows it is recommended to use different IAM roles: `/ci/builder` and `/ci/publisher`.
Builder has read-only access to CodeArtifact, while publisher has write access.
Below there are two terraform modules that have all necessary permissions to work with CodeArtifact:
- **ci-builder** - [github](https://github.com/agilecustoms/terraform-aws-ci-builder) - [terraform registry module](https://registry.terraform.io/modules/agilecustoms/ci-builder/aws/latest)
- **ci-publisher** - [github](https://github.com/agilecustoms/terraform-aws-ci-publisher) - [terraform registry module](https://registry.terraform.io/modules/agilecustoms/ci-publisher/aws/latest)

And this is [example](https://github.com/agilecustoms/terraform-aws-ci-publisher?tab=readme-ov-file#how-to-create-a-role-with-this-policy)
how to create an AWS IAM role based on these policies with a password-less trust policy,
so you do not need to store `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your repository secrets

Read more about software distribution in AWS in my [LinkedIn article](https://www.linkedin.com/pulse/software-distribution-aws-alexey-chekulaev-ubl0e)

## Inputs

This action is a combination of few other actions mainly `actions/setup-java` and `aws-actions/configure-aws-credentials`.
All `java-*` inputs are pass through parameters to `actions/setup-java` action, so please refer to [setup-java documentation](https://github.com/actions/setup-java?tab=readme-ov-file#usage)

| Name                            | Default       | Description                                                                                             |
|---------------------------------|---------------|---------------------------------------------------------------------------------------------------------|
| **aws-account** (required)      |               | AWS account number where the CodeArtifact domain is located                                             |
| aws-login                       | _true_        | Whether to login to AWS. Set to _false_ if you handle AWS login separately                              |
| **aws-codeartifact-domain**     |               | CodeArtifact domain name                                                                                |
| **aws-codeartifact-repository** | maven         | CodeArtifact repository name                                                                            |
| **aws-region**                  |               | AWS region where the CodeArtifact domain is located                                                     |
| aws-role                        | ci/builder    | IAM role to assume for CodeArtifact access                                                              |
| java-cache                      | maven         | Enable Maven dependency caching. Use empty string `""` to disable                                       |
| java-cachedependency-path`      | (see doc.)    | See description at [actions/setup-java](https://github.com/actions/setup-java?tab=readme-ov-file#usage) |
| java-distribution               | temurin       | Java distribution. Default is Temurin as it is pre-cached in ubuntu-latest                              |
| java-version                    | 21            | Java version to use. Default is latest LTS (21 as of June 2025)                                         |
| settings-mirrors                |               | Maven settings.xml mirrors section (XML format)                                                         |
| settings-pluginGroups           |               | Maven settings.xml pluginGroups section (XML format)                                                    |
| settings-pluginRepositories     | Maven Central | Additional plugin repositories in XML format to be placed in front of CodeArtifact                      |
| settings-profileproperties`     |               | Maven settings.xml profile properties section (XML format)                                              |
| settings-proxies                |               | Maven settings.xml proxies section (XML format)                                                         |
| settings-repositories           | Maven Central | Additional Maven repositories in XML format to be placed before CodeArtifact                            |

Notes:
1. for `aws-account` it is recommended to have a dedicated AWS account (not dev, not prod) to store artifacts (S3 binaries, CodeArtifact, Docker images)
2. default settings for `settings-pluginRepositories` and `settings-repositories` are good for projects
that take 95% of dependencies from Maven Central and left 5% from corporate CodeArtifact.
Come companies opt in to store all dependencies in CodeArtifact with Maven Central as an _upstream_.
In this configuration you would want to set `settings-pluginRepositories` and `settings-repositories` to empty string `""`

## Local development

Under the hood, this action generates a [settings.xml](./ci.settings.xml) file with CodeArtifact repository and credentials.
Note:
- maven central and its mirror are used as primary and secondary repositories for dependencies and plugins, your company CodeArtifact is in 3rd place.
If you use CodeArtifact upstream feature, feel free to remove maven central and its mirror from `repositories` and `pluginRepositories` sections
- your company repository id has format `{aws-codeartifact-domain}-{aws-codeartifact-repository}` like `mycompany-maven`

With this knowledge, you can place a local version of [settings.xml](./local.settings.xml) on developers' machines
to give them read-only access to maven packages in corporate CodeArtifact.
As you can see this `settings.xml` file has two env variables: `ARTIFACT_STORE_HOST` and `ARTIFACT_STORE_TOKEN`.
Host is fixed (after you create CodeArtifact domain), you can place these two lines in your shell configuration (`.zshrc`, `.bashrc`):
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

## Security

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
        uses: actions/checkout@v5

      - name: Proxy with a secret
        id: proxy
        run: |
          # generate a SECRET
          PROXY_CONFIG="<config><username>abc</username><password>$SECRET</password></config>"
          echo "::add-mask::$PROXY_CONFIG"
          echo "CONFIG=$PROXY_CONFIG" >> $GITHUB_OUTPUT

      - name: Setup Java
        uses: agilecustoms/setup-maven-codeartifact@v1
        with:
          aws-account: ${{ vars.AWS_ACCOUNT_DIST }}
          aws-region: us-east-1
          aws-codeartifact-domain: mycompany
          settings-proxies: ${{ steps.proxy.outputs.CONFIG }}
```

## Misc

- [Troubleshooting](./docs/troubleshooting.md)

## License

This project is released under the [MIT License](./LICENSE)

## Acknowledgements

- https://github.com/s4u/maven-settings-action — first action I tried, but it doesn't support pluginRepositories
- https://github.com/whelk-io/maven-settings-xml-action — used this during 2024, then wrote my own action 
