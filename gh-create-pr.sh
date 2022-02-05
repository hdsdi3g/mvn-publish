#!/bin/bash
#
#    gh-create-pr - Create a Github pull request from current branch name if based on "issue[ref]".
#    Copyright (C) hdsdi3g for hd3g.tv 2021
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or any
#    later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <https://www.gnu.org/licenses/>.
#
#    Usage: just run this script from a github local repository
#           you must have a valid setup of:
#             - gh
#             - whiptail
#             - git
#             - perl
#             - mktemp
#

set -eu

PR_STATUS=$(NO_COLOR=1 gh pr status | grep "There is no pull request associated with" | wc -l);

if [ "$PR_STATUS" -eq 1 ]; then
    # Display PR
    gh pr status
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD);
RELATIVE_DIR=$(dirname $(realpath "$0"));
BRANCH_REF=$($RELATIVE_DIR/git-get-base-branch);
if [[ "$BRANCH_REF" == ""  ]]; then
    echo "Can't found a branch ref..."
    exit 1;
fi

if [[ $BRANCH != "issue"* ]]; then
    echo "Can't found the issue relative to current branch $BRANCH"
    exit 2;    
fi
ISSUE_REF=${BRANCH:5}

ISSUE_VIEW_FILE=$(mktemp /tmp/gh-issue-status.XXXXXX)
exec 3>"$ISSUE_VIEW_FILE"

NO_COLOR=1 gh issue view $ISSUE_REF > $ISSUE_VIEW_FILE
ISSUE_TITLE=$(cat $ISSUE_VIEW_FILE | head -1 | cut -f 2);
ISSUE_LABELS=$(cat $ISSUE_VIEW_FILE | grep "labels" | cut -f 2 | cut -f 1 -d ",");
rm "$ISSUE_VIEW_FILE"

gh pr create \
    --assignee "@me" \
    --base "$BRANCH_REF" \
    --title "$ISSUE_TITLE" \
    --label "$ISSUE_LABELS" \
    --body "Close #$ISSUE_REF"

exit 0;
