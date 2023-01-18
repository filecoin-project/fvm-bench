#!/bin/bash

# Set the output directory to "./contracts-output" and create if it doesn't exist
output_dir="./contracts-output"
if [ ! -d "$output_dir" ]; then
  mkdir "$output_dir"
fi

# Clear directory of previous compiler output
rm "$output_dir"/*

# Find all files in the "./contracts/" directory that end with ".sol"
# Use solcjs to compile each and generate binary+abi output
for file in ./contracts-alex/*.sol; do
  echo "Compiling $file"
  solcjs --optimize --bin --abi "$file" --output-dir "$output_dir"
done

echo "Testing contracts..."
echo " "

# Find all files in the "./contracts-output" directory that end with ".bin"
for bin_file in "$output_dir"/*.bin; do
  # Skip calling any libraries we've added to the libraries dir
  if [[ $bin_file == "$output_dir/libraries_"* ]]; then
    # echo "Skipping library: $bin_file"
    continue
  fi

  # Run fvm-bench on the compiled file
  # Call the `testEntry()` function, and send no other calldata
  output=$(./target/release/fvm-bench -b ../builtin-actors/target/debug/build/fil_builtin_actors_bundle-802024e7b04236d4/out/bundle/bundle.car "$bin_file" c0406226 0000000000000000000000000000000000000000000000000000000000000000)
  # output=$(./target/release/fvm-bench -d -b ../builtin-actors/target/debug/build/fil_builtin_actors_bundle-802024e7b04236d4/out/bundle/bundle.car "$bin_file" c0406226 0000000000000000000000000000000000000000000000000000000000000000)

  # echo "$output"

  # echo "Parsing output for $bin_file:"
  gas_used=$(echo "$output" | grep "Gas Used:")
  # echo "Output:"
  # echo "=========="
  # echo "$gas_used"
  # echo "=========="

  if [ $? -ne 0 ]; then
    exit 1
  fi

  # Parse the output to retrieve the returndata from the "Result" line
  returndata=$(echo "$output" | grep "Result:" | awk '{print $2}')
  # echo "Raw returndata:"
  # echo "=========="
  # echo "$returndata"
  # echo "=========="

  # Use forge-cast to abi-decode the returndata and echo the result
  # Note: right now, you need to manually change the return params
  #       here if you change testEntry() to return something new
  decoded=$(cast --abi-decode "run()(string[])" "0x$returndata")
  echo "Test results for $bin_file:"
  echo "=========="
  echo "$gas_used"
  echo "Failures:"
  echo $decoded | jq -r ".[]"
  echo "=========="
  echo " "
done
