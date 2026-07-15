# Security policy

VeilVote is an educational project and has not been audited. Do not use it to
govern production assets.

## Threat model

The contract aims to hide individual choices, participation state and interim
totals from public observers. It does not hide the public voter allowlist,
transaction sender, transaction timing or final aggregate result. Network-level
metadata may still enable correlation.

The admin can add eligible voters only before voting starts and cannot modify
ballots or totals. There is no emergency cancellation mechanism.

## Reporting a vulnerability

Do not open a public issue for an exploitable vulnerability. Contact the
maintainer privately with reproduction steps, impact and a suggested fix. Allow
reasonable time for remediation before public disclosure.

