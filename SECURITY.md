# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | Yes |

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please report security issues by opening a [GitHub Security Advisory](https://github.com/hackertwinten/clair-helm/security/advisories/new) or emailing the address listed on the [hackertwinten GitHub profile](https://github.com/hackertwinten) with the subject line `[SECURITY] clair-helm`.

Include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested remediation if you have one

You will receive an acknowledgement within 48 hours. After the issue is confirmed, we will work on a fix and coordinate a disclosure timeline with you. We aim to release a patch within 14 days of confirmation for critical issues.

## Scope

This security policy covers the Helm chart itself — the Kubernetes manifests, templates, and default configuration values. Vulnerabilities in the Clair application or its upstream container images should be reported to the [Clair project](https://github.com/quay/clair/security).

## Chart security defaults

The chart ships with the following security posture by default:

- All pods run as non-root (`runAsNonRoot: true`, `runAsUser: 65534`)
- `readOnlyRootFilesystem: true` on all containers
- All Linux capabilities dropped (`capabilities.drop: [ALL]`)
- `allowPrivilegeEscalation: false` on all containers
- Database credentials and Clair config stored in Kubernetes `Secret` objects, not `ConfigMap`
- Auto-generated passwords use 32 random alphanumeric characters
