#!/usr/bin/env python3

import re
import sys

pattern = r"^[a-zA-Z0-9_]+ \d+ (?:day|month|year)s? ago \| (?:root \| )?(?:parent \| )?(?:prev \| )?(?:next \[–\])?(?:\[–\])?"

for line in sys.stdin:
    line = line.strip()
    if line:
        modified_line = re.sub(pattern, "---", line)
        if modified_line != "---":
            print(modified_line)
