#!/bin/sh

num_args=$#

filesdir=$1
searchstr=$2

if [ "$num_args" -ne 2 ]; then

	echo "invalid number of arguments!"
	exit 1
fi

if [ -d "$filesdir" ]; then

	n_files=$(grep -rl "$searchstr" "$filesdir" | wc -l)
        n_lines=$(grep -rh "$searchstr" "$filesdir" | wc -l)

	echo "The number of files are "$n_files" and the number of matching lines are "$n_lines""

else
	echo "Directory $filesdir does not exist!"
exit 1

fi
