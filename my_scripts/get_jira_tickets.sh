#!/usr/bin/env zsh
echo "Downloading Jira tickets."
time curl -D- -u ">>>>>>username_here<<<<<<<:>>>>>>my_password_here<<<<<<<" -X GET -H "Content-Type: application/json" "https://jira.com/rest/api/2/search?jql=project=BRAIN&maxResults=1000" | grep "^{" >! jira_tickers.json
echo "Tickets downloaded."

