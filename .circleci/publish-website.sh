#!/bin/bash

if [[ -v CIRCLE_TAG ]]; then
    echo "Deploying website updates for $CIRCLE_TAG"
else
    if [ "$CIRCLE_BRANCH" = "main" ]; then
        echo "Deploying website updates for main branch"
    else
        echo "Website updates are not published for $CIRCLE_BRANCH commits"
        exit
    fi
fi

if [ `git branch -r | grep "origin/gh-pages" | wc -l` = 0 ]; then
    echo "No gh-pages branch for publication"
    exit
fi

if [ `set | grep GIT_EMAIL | wc -l` = 0 -o `set | grep GIT_USER | wc -l` = 0 ]; then
    echo "No identity configured with GIT_USER/GIT_EMAIL"
    exit
fi

git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_USER

# Remember the SHA of the current build.
SHA=$(git rev-parse --verify HEAD)

# Save the website files
cd build/html

tar cf - . | gzip > /tmp/html.$$.tar.gz
cd ../..

# Switch to the gh-pages branch
git checkout --track origin/gh-pages
git fetch origin
git rebase origin/gh-pages

# Unpack the website files
tar zxf /tmp/html.$$.tar.gz
rm /tmp/html.$$.tar.gz

# Push the changes back to the repo
git status

#git add .
#git commit -m "Deploy gh-pages for ${CIRCLE_PROJECT_USERNAME}: ${SHA}"
#git push -q origin HEAD

# Go back to the main branch
git checkout main
