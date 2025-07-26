# Troubleshooting

### Common Issues

1. **"Unable to locate credentials" error**
    - Ensure `id-token: write` permission is set
    - Verify the IAM role trust policy allows GitHub OIDC

2. **"Repository not found" error**
    - Check CodeArtifact domain and repository names
    - Ensure the IAM role has `codeartifact:GetAuthorizationToken` permission
