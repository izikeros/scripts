#!/usr/bin/env bash
echo "1. install Sync Settings Package"
echo "2. Obtain github access_token (generate or take existing). Access to gist is sufficient"
echo "3. Sync Settings: Edit User Settings, add content (see source of this script)"
content="
{
 "access_token": "",
 "gist_id": "5edbd74e95afa9b457eda5d15dc91ebc",
 "auto_upgrade": true
}
"
echo $content
echo "4. Sync Settings: Download"
echo "5. Create projects:"
echo " - vimwiki: ~/vimwiki, ~/projects/priv/blog/contents/notes"
echo " - blog: ~/vimwiki, ~/projects/priv/blog/contents"
echo " - scripts and dotfiles: ~/scripts, ~/dotfiles"
