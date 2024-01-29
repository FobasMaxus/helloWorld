#!/bin/bash

while getopts "m:" opt
do
  case $opt in
    m) commit_msg=${OPTARG};;
    \?) echo "invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Needs a valid argument"
    exit 1
    ;;
  esac
done
echo "Your commit message: $commit_msg"

echo "Adding files to commit"
git add .


git commit -m "$commit_msg"
printf "Git commited all your changes with following message: \n$commit_msg"
git push
echo "Git pushed your commit"

cd review-him-blog
hugo -t monday-theme
echo "Hugo built static files"

cd public
git add .
git commit -m "$commit_msg"
echo "Git added to commit and commited your build files"

git push
echo "Git released your changes!"




