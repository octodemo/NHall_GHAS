#!/bin/bash

# Define file paths and git config variables
file_path="./routes/showProductReviews.ts"
vuln_file_path="./repo_reset/vuln/showProductReviews.ts"
git_name="Jack G Kafaty"
git_email="jackgkafaty@github.com"
# Generate timestamp for branch name to avoid PR name duplication
timestamp=$(date +%S%3N)

# Unzip vuln file to be replaced
mkdir -p ./repo_reset/vuln/ 
unzip ./repo_reset/showProductReviews.zip -d ./repo_reset/vuln/

# Fetch all remote branches
git fetch origin
git reset --hard origin/main

# List all open pull requests and get their IDs, then close them
gh pr list --state open --json number -q '.[].number' | xargs -I {} gh pr close {}

# Delete all local branches except main
for branch in $(git branch | grep -vE "main|HEAD"); do
    if git show-ref --verify --quiet refs/heads/$branch; then
        git branch -D $branch
    fi
done

# Delete all remote branches except main
for branch in $(git branch -r | grep -vE "main|HEAD"); do
    if [[ $branch == origin/* ]]; then
        branch=${branch#origin/}
        if git ls-remote --exit-code --heads origin $branch; then
            git push origin --delete $branch
        fi
    fi
done

# Create a new branch 
new_branch="ProductReview_$timestamp"
git checkout -b $new_branch

#Introduce Code Injection Vulnerability
rm -f "$file_path"
cp "$vuln_file_path" "$file_path"

# Set Git global config
git config --global user.name "$git_name"
git config --global user.email "$git_email"

# Commit changes
git add .
git commit -m "Show Product Review update to measure the time it takes to execute a database query"
git push --set-upstream origin $new_branch

# Create pull request
gh pr create --title "$new_branch" --body "Updated Product Review to measure the time it takes to execute a database query, which is used later to check for potential NoSQL denial-of-service (DoS) attacks " --base main --head $new_branch
