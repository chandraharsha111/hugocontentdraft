#!/bin/sh

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the project.
hugo # if using a theme, replace with `hugo -t <YOURTHEME>`
hugo -d ../chandraharsha111.github.io

# Try deploying to public site
cd ../chandraharsha111.github.io # Goes to your public site repo
git add . # Adds changes


# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

# Push source and build repos to deployed site on Github.
git push origin main
printf "\033[0;32m Deployed the website ...\033[0m\n"

cd ../hugocontentdraft
git add . # Adds changes

# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi

git commit -m "$msg" # Makes your commit to hugocontentdraft repo
git push origin main # Pushes the code to hugocontentdraft repo
