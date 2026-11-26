# tangle-integration-manifests

Test fixtures for [Tangle](https://github.com/ivanklee86/tangle)'s live end-to-end tests. The live test stack's ArgoCD renders the manifests in this repo, and Tangle diffs them between two refs:

- `main` is the baseline. Every Application tracks it, one directory each.
- `test_gitops` stands in for "a change the user pushed". It is exactly one commit on top of `main`.

The Application definitions (labels, projects, sources, sync policies) live in Tangle under `integration/kubernetes/example/`.

## Scenario apps

| Directory | ArgoCD | Labels | Change on `test_gitops` | What Tangle should report |
| --- | --- | --- | --- | --- |
| `test-1/` (Helm) | `test` | `env:test, foo:bar, bazz:buzz` | `ingress.enabled: true` | A diff that adds one `Ingress` |
| `test-2/` | `test` | `env:preprod, foo:bar, bazz:buzz` | none | No changes |
| `test-3/` (Helm) | `prod` | `env:prod, foo:bar` | `values.yaml` is invalid YAML | A manifest generation error from `helm template` |
| `test-4/` | `prod` | `env:infra, foo:bar` | none | No changes |

## Source-type apps

These Applications are on the `sources` ArgoCD, in their own project, so they never appear in the scenario apps' queries. Each one covers a way an Application can get its manifests.

| Application | Sources | Change on `test_gitops` | Revision to render the change |
| --- | --- | --- | --- |
| `tanka` | `tanka/`, rendered by the Tanka config management plugin | `greeting` changes and `removed` is deleted | `test_gitops` |
| `helm-repo` | The podinfo chart from a Helm repo, with no git source | none (not in this repo) | none: a git ref isn't a chart version |
| `helm-repo-git-values` | 1. the podinfo chart from a Helm repo. 2. `ref: values` from this repo, for `helm-repo-git-values/values.yaml` | `replicaCount: 2` | `test_gitops` on source 2 |
| `git-chart-git-values` | 1. `git-chart-git-values/chart/` from this repo. 2. `ref: values` with `path: git-chart-git-values/extra/` from this repo | `greeting` in `values.yaml` and `extra` in `extra/configmap.yaml` both change | `test_gitops` on sources 1 and 2 |
| `two-repos` | 1. `guestbook/` from `argoproj/argocd-example-apps`, pinned to a commit. 2. `two-repos/` from this repo | `greeting` changes | `test_gitops` on source 2 only, because the other repo has no such branch |

## Changing this repo

Tangle's tests read this repo from GitHub, so every change takes effect immediately for every Tangle branch.

- Keep `test_gitops` exactly one commit ahead of `main`. If you change `main`, rebase `test_gitops` onto it so the only differences are the ones in the tables above. A ruleset blocks force-pushes and deletion on both branches, so disable it for the rebase and turn it back on afterwards.
- Update the tables and Tangle's tests together with any change.
