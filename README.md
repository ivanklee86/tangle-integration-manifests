# tangle-integration-manifests

Test fixtures for [Tangle](https://github.com/ivanklee86/tangle)'s live end-to-end tests. The live test stack's ArgoCD renders the manifests in this repo, and Tangle diffs them between two refs:

- `main` is the baseline. ArgoCD Applications `test-1` to `test-4` track it, one directory each.
- `test_gitops` stands in for "a change the user pushed". It is exactly one commit on top of `main`.

| Directory | ArgoCD | Labels | Change on `test_gitops` | What Tangle should report |
| --- | --- | --- | --- | --- |
| `test-1/` (Helm) | `test` | `env:test, foo:bar, bazz:buzz` | `ingress.enabled: true` | A diff that adds one `Ingress` |
| `test-2/` | `test` | `env:preprod, foo:bar, bazz:buzz` | none | No changes |
| `test-3/` (Helm) | `prod` | `env:prod, foo:bar` | `values.yaml` is invalid YAML | A manifest generation error from `helm template` |
| `test-4/` | `prod` | `env:infra, foo:bar` | none | No changes |

The Application definitions (labels, projects, sync policies) live in Tangle under `integration/kubernetes/example/`.

## Changing this repo

Tangle's tests read this repo from GitHub, so every change takes effect immediately for every Tangle branch.

- Keep `test_gitops` exactly one commit ahead of `main`. If you change `main`, rebase `test_gitops` onto it so the only difference is still the table above. A ruleset blocks force-pushes and deletion on both branches, so disable it for the rebase and turn it back on afterwards.
- Update the table and Tangle's tests together with any change.
