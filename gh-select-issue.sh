#!/bin/bash
#
#    gh-select-issue - get Github issue #ref.
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
#

set -eu

ISSUES=$(NO_COLOR=1 gh issue list --state open --limit 50);
RELATIVE_DIR=$(dirname $(realpath "$0"));

if [ "$(echo $ISSUES | grep OPEN | wc -l)" -eq 0 ]; then
    $RELATIVE_DIR/gh-create-issue.sh
	exit 0;
fi

cmd=(whiptail --title "Select GitHub issue" --menu "What do you want to work on ?" 0 0 0);
while IFS= read -r ISSUE; do
    ISSUE_REF=$(echo "$ISSUE" | cut -f 1);
    ISSUE_NAME=$(echo "$ISSUE" | cut -f 3);
    ISSUE_TYPE=$(echo "$ISSUE" | cut -f 4);
    cmd+=("$ISSUE_REF" "$ISSUE_NAME ($ISSUE_TYPE)")
done <<< "$ISSUES"

cmd+=("0" "Create new issue...")

set +e

SELECTED_ISSUE=$("${cmd[@]}" 3>&1 1>&2 2>&3);

if [[ "$SELECTED_ISSUE" == ""  ]]; then
    exit 0;
fi
if [[ "$SELECTED_ISSUE" == "0"  ]]; then
    $RELATIVE_DIR/gh-create-issue.sh
    exit 0;
fi

echo $SELECTED_ISSUE
exit 0;
