# Dev Scripts

A collection of shell and Ruby utility scripts for development workflows.

Git
-----------

| Script | Description |
|--------|-------------|
| `branch` | Print current branch name |
| `branchist [n]` | Show n most recent branches (default 5) |
| `recent-branches` | Show branches with commits in the last hour |
| `clean-branches` | Delete local branches merged into develop |
| `ss [n]` | Show stash contents (optional: stash index) |

Search & Files
-------------------

| Script | Description |
|--------|-------------|
| `search word1 word2 [dir]` | Find files containing all keywords, ranked by hits |
| `sub pattern replacement` | Search and replace across files |
| `showme path` | Cat all files in a directory with headers |
| `find-last-updated [dir] [n]` | Show n most recently modified files |
| `dt tablename` | Show Rails schema definition for matching tables |

GitHub
--------------------
 
| Script | Description |
|--------|-------------|
| `tlist [status]` | List tickets from GitHub Project Board. Requires `GITHUB_ORG` and `GITHUB_PROJECT_NUMBER` env vars. |

Rails
--------------------
 
| Script | Description |
|--------|-------------|
| `credit [env]` | Edit Rails credentials (default: development) |

Misc
--------------------
 
| Script | Description |
|--------|-------------|
| `open file` | Open file in default app (WSL) -- Apple had an `open` command that you could use from the command line to open images. Super helpful. Wanted that available when using unix from WSL. |

