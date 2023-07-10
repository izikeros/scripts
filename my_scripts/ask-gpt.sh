#!/usr/bin/env bash
#
# ask_gpt.sh
# Usage: ./ask_gpt.sh "What is the meaning of life?"
#
# Description: This script calls the Azure OpenAI API to ask a question and returns the answer.
#
# Arguments:
#   - The question is passed as the first argument to the script.
#
# Requirements:
#   - The jq command line tool must be installed.
#   - The Azure OpenAI API key must be set in the AZURE_OPENAI_API_KEY environment variable.
#   - The Azure OpenAI endpoint must be set in the AZURE_OPENAI_ENDPOINT environment variable.
#   - The Azure OpenAI API version must be set in the OPENAI_API_VERSION environment variable.
#   - The Azure OpenAI deployment name must be set in the CHAT_DEPLOYMENT environment variable.

# Make API call to Azure OpenAI API and print the answer
curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$CHAT_DEPLOYMENT/chat/completions?api-version=$OPENAI_API_VERSION" \
  -H "Content-Type: application/json" \
  -H "api-key: $AZURE_OPENAI_API_KEY" \
  -d "{\"messages\":[{\"role\": \"system\", \"content\": \"You are a helpful assistant.\"},{\"role\": \"user\", \"content\": \"$1\"}]}" \
  | jq '.choices | .[0] | .message | .content' \
  | echo -e "$(cat -)"
