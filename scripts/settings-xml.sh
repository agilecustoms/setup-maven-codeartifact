#!/usr/bin/env bash
# Generate Maven settings.xml
# Inputs (env): REPOSITORY, REPO_ID, HOST, TOKEN and SETTINGS_* (XML sections from settings-* inputs)
set -eo pipefail

mkdir -p "$HOME/.m2"
cat <<EOF > "$HOME/.m2/settings.xml"
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <activeProfiles>
    <activeProfile>github</activeProfile>
  </activeProfiles>
  <profiles>
    <profile>
      <id>github</id>
      <properties>$SETTINGS_PROFILE_PROPERTIES</properties>
      <repositories>
        $SETTINGS_REPOSITORIES
        <repository>
          <id>$REPO_ID</id>
          <url>https://$HOST/$REPOSITORY/maven/</url>
        </repository>
      </repositories>
      <pluginRepositories>
        $SETTINGS_PLUGIN_REPOSITORIES
        <pluginRepository>
          <id>$REPO_ID</id>
          <url>https://$HOST/$REPOSITORY/maven/</url>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  <servers>
    <server>
      <id>$REPO_ID</id>
      <username>aws</username>
      <password>$TOKEN</password>
    </server>
  </servers>
  <mirrors>$SETTINGS_MIRRORS</mirrors>
  <pluginGroups>$SETTINGS_PLUGIN_GROUPS</pluginGroups>
  <proxies>$SETTINGS_PROXIES</proxies>
</settings>
EOF
