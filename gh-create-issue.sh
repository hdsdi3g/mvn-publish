#!/bin/bash
#
#    gh-create-issue - create a new Github issue, and return #ref
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

ISSUE_NAME=$(whiptail --title "Create GitHub issue" --inputbox "Enter the issue title:" 0 0 3>&1 1>&2 2>&3);

if [[ "$ISSUE_NAME" == ""  ]]; then
	echo "No issue name, cancel operation"
	exit 1;
fi

ISSUE_LABEL=$(whiptail --title "Choose an issue label" --menu \
	"Select the best label for the new issue:" 0 0 0 \
	"bug" "Declare a bug issue" \
	"enhancement" "Propose an enhancement" \
	"documentation" "Update internal documentation" \
	3>&1 1>&2 2>&3);

if [[ "$ISSUE_LABEL" == ""  ]]; then
	echo "No issue label, cancel operation"
	exit 2;
fi

ISSUE_URL=$(gh issue create --assignee @me --title "$ISSUE_NAME" --label $ISSUE_LABEL --body "" | grep -v "Creating issue" | grep "issues")

basename $(echo "$ISSUE_URL")

exit 0;
