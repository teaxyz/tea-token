# Contributing to tea-token

Thanks for your interest in contributing! This repository uses standard tools for Solidity development and Foundry for testing.

## Code of Conduct

All contributors are expected to follow a respectful, inclusive Code of Conduct. Be professional and courteous in discussions and PRs.

## Getting started

1. Fork the repository and create a topic branch from `main` (or the default branch):

   - Use descriptive branch names like `feat/add-foo` or `fix/breaking-bug`.

2. Run tests locally before opening a PR.

   - Install Foundry (https://book.getfoundry.sh/getting-started/installation)
   - Run the test suite:

```bash
forge test
```

3. Linting and formatting

- If the project includes a linter/formatter (e.g., `solhint`, `prettier`), run it and fix warnings before submitting. If not present, try to match the repository's existing style.

## Making changes

- Keep changes small and focused.
- Add tests for new functionality and bug fixes. Tests should live in `test/` and use the existing test harness (Foundry/PRBTest/forge).
- Update or add contract and function-level NatSpec comments where appropriate.
- If you modify public behavior, include changelog notes or mention the breaking change in the PR description.

## Commit messages

- Use concise, meaningful commit messages. A suggested format:

```
<type>(scope): short description

Longer description if necessary.
```

Where `type` is one of `feat`, `fix`, `chore`, `docs`, `test`, `refactor`.

## Pull requests

- Open a PR against the `main` (or default) branch.
- Provide a clear title and description that explains: what changed, why, and how to test it.
- Link related issues or PRs.
- Ensure the test suite passes and there are no obvious security regressions.

## Reviews

- Be responsive to review feedback. Keep PRs up-to-date with the target branch if requested.
- For large changes, consider opening an RFC or draft PR to get early feedback.

## Security-sensitive changes

- If your change affects security-sensitive code (token logic, access control, recovery, etc.), mention it explicitly in the PR and consider opening a PR as draft until security reviewers have had time to examine the change.
- For urgent security fixes, coordinate with maintainers to ensure responsible disclosure and patching.

## Adding examples and docs

- Documentation updates are welcome. Add short examples or README updates where helpful.

## Questions

If you're unsure how to proceed, open an issue describing your planned change and ask maintainers for guidance.

Thank you for contributing! Your help improves the project for everyone.
