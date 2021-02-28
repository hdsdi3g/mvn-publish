#!/bin/bash
#
#    is-gh - checks if "gh" (Github cli) is installed and can run from here.
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
#    Usage: just run this script from a git repository
#           you must have a valid setup of:
#             - command / grep / wc
#

if ! [ -x "$(command -v gh)" ]; then
    echo "0";
	return;
fi
if [ ! -f ".git/config" ]; then
	echo "0";
	return;
fi
if [ "$(cat ".git/config" | grep "github.com" | grep "url = " | wc -l)" -eq 0 ]; then
	echo "0";
	return;
fi

echo "1";
