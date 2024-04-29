# aws-hosting

service = 
    the code
    the secrets
    the infra settings (task def)

    --- these 3 things should change atomically (in 1 commit + pipeline actions)

* dockerize the code
* secrets => AWS SM as a single k=v file; upload with commit as version stage
* task definition: has mem, cpu, etc... 
    also needs to have TF identifiers hardcoded (👎🏼)

    conflict: want to have in TF repo to avoid hardcoded identifiers
    but want to have in Service repo to properly use commit hash in version stage for secrets manager...

    although, do you actually want to use commit-versioned secrets?

    arguably you might want to rollback the code without rolling back (for example) a revoked+rotated Sentry Token
    it's likely better for secrets to exist independent of the code, and to manually fix secrets if there's an issue, 
    or separately rollback the secretsmanager version of those secrets
* 
