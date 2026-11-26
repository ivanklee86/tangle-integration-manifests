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
| `two-repos` | 1. `kustomize/` from `stefanprodan/podinfo` at tag `6.17.0`. 2. `two-repos/` from this repo | `greeting` changes | `test_gitops` on source 2 only, because the other repo has no such branch |
| `same-repo-pinned` | 1. `same-repo-pinned/branch/` from this repo at `main`. 2. `same-repo-pinned/tag/` from this repo at tag `fixture-pinned-v1` | `greeting` changes in both | `test_gitops` on sources 1 and 2: every source in the target repo moves, even one pinned to a tag |
| `multi-source-cmp` | 1. `multi-source-cmp/tanka/`, rendered by the Tanka plugin. 2. `multi-source-cmp/extra/` from this repo | `greeting` changes in the jsonnet | `test_gitops` on sources 1 and 2 (only source 1 changes) |
| `three-repos` | 1. `kustomize/` from `stefanprodan/podinfo` at `6.17.0`. 2. `integration/kubernetes/example/manifests/4/` from `ivanklee86/tangle` at commit `309da00`. 3. `three-repos/` from this repo | `greeting` changes | `test_gitops` on source 3 only. Neither other repo has a `test_gitops` branch |

## Tags

| Tag | Points at | Used for |
| --- | --- | --- |
| `fixture-pinned-v1` | A commit on `main` | Source 2 of `same-repo-pinned`, a source pinned to a tag. It never moves |
| `fixture-target` | The `test_gitops` commit | Diffing against a tag instead of a branch. Tangle's live tests also diff against this commit's SHA, which they look up at run time |

## Changing this repo

Tangle's tests read this repo from GitHub, so every change takes effect immediately for every Tangle branch.

- Keep `test_gitops` exactly one commit ahead of `main`. If you change `main`, rebase `test_gitops` onto it so the only differences are the ones in the tables above. The rebase gives that commit a new SHA, so move `fixture-target` to it afterwards (`git tag -f fixture-target test_gitops` and force-push the tag). Tangle's live tests check that the tag and the branch agree. A ruleset blocks force-pushes and deletion on both branches and both tags, so disable it for the rebase and turn it back on afterwards.
- Update the tables and Tangle's tests together with any change.
