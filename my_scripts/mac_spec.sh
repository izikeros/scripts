#!/bin/bash
# Save as mac_specs.sh and run with: bash mac_specs.sh

OUTPUT=~/Desktop/mac_specs_report.txt

echo "==== MacBook Full Specification Report ====" > "$OUTPUT"
echo "Generated on: $(date)" >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "---- Hardware Overview ----" >> "$OUTPUT"
system_profiler SPHardwareDataType >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---- CPU ----" >> "$OUTPUT"
sysctl -n machdep.cpu.brand_string >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---- Memory ----" >> "$OUTPUT"
system_profiler SPMemoryDataType >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---- Graphics/Displays ----" >> "$OUTPUT"
system_profiler SPDisplaysDataType >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---- Storage ----" >> "$OUTPUT"
system_profiler SPStorageDataType >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---- Battery ----" >> "$OUTPUT"
system_profiler SPPowerDataType | grep -A20 "Battery Information" >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---- Network ----" >> "$OUTPUT"
system_profiler SPNetworkDataType >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---- Software ----" >> "$OUTPUT"
system_profiler SPSoftwareDataType >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "==== End of Report ====" >> "$OUTPUT"

echo "Report saved to: $OUTPUT"
