# Security at Agent0S

## Report a vulnerability

If you believe you've found a security vulnerability in Agent0S, please report it privately through [GitHub's private vulnerability reporting](https://github.com/eli-labz/AgentOS/security/advisories/new) so it can be investigated and fixed before it is made public.

Please don't report potential vulnerabilities publicly in GitHub Issues, Discord, or social media before they've been resolved.

If the issue also affects upstream [Omarchy](https://github.com/omacom/omarchy), please report it to the Omarchy security team as well, following [their security policy](https://github.com/omacom/omarchy/security/policy).

## What is a vulnerability?

We consider a bug a security vulnerability when it can be exploited to cross a meaningful security boundary: an untrusted or lower-privileged party gains access, permissions, or control they didn’t already have.

Code that could be more robust but does not cross a security boundary is an improvement rather than a security vulnerability. We may still merge a proposed fix and credit the reporter in our release notes.

## What to include

Give us enough information to understand and reproduce the issue:

- The affected component and Agent0S version.
- An explanation of what an attacker can do before and after exploitation.
- Steps to reproduce the issue and any proof of concept.
- Your preferred contact details for follow-up.

## Responsible disclosure

Please act in good faith while investigating and reporting vulnerabilities:

- Only test systems and accounts you own or have explicit permission to test.
- Avoid privacy violations, disruption, data destruction, and service degradation.
- Don’t exploit a vulnerability beyond what is needed to demonstrate it.
- Give us a reasonable opportunity to investigate and address the issue before publishing details.

We’ll review your report and keep you informed as we’re able while we work toward a resolution.

## Credits

Researchers who privately report a confirmed security vulnerability and give us the chance to ship a fix will be thanked in the release notes.

## Regular bugs and support

For anything that isn’t a security vulnerability, please use the [Agent0S issue tracker](https://github.com/eli-labz/AgentOS/issues).
