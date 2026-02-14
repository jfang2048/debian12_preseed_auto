# Legacy Notes (Sanitized)

This file keeps historical pointers that were used while developing the automation workflow.
Secrets, private credentials, and environment-specific values were removed for open-source publication.

## References

- Debian preseed examples: https://preseed.debian.net/debian-preseed/
- FAI image builder: https://fai-project.org/FAIme/
- ISO injection workflow reference: https://www.librebyte.net/en/systems-deployment/unattended-debian-installation/

## Useful Commands

```bash
sudo apt-get update && sudo apt-get install debconf-utils
sudo debconf-get-selections --installer > debian.preseed
```

## Notes

- Use encrypted password hashes in preseed whenever possible.
- Do not commit plaintext credentials, SSH keys, certificates, or internal domains.
- Keep private preseed variants in `config/preseed_internal.cfg` (ignored by Git).
