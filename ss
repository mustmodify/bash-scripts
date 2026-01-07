#!/bin/bash

# Check if the user has provided an optional offset parameter
if [ -n "$1" ]; then
  # If an offset is provided, use it with the 'git show' command
  git show "stash@{$1}"
else
  # If no offset is provided, use the 'git stash show' command
  git stash show -p
fi
