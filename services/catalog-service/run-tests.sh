#!/bin/bash
echo "Running tests for catalog-service..."
# Check if the test directory exists
if [ ! -d "tests" ]; then
  echo "Test directory not found. Please ensure tests are set up correctly."
  exit 1
fi
# Run the tests
go test ./go-tests/...
# Check the exit status of the test command
if [ $? -ne 0 ]; then
  echo "Tests failed. Please check the output above for details."
  exit 1
fi
echo "All tests passed successfully."
exit 0
# End of script
# This script is used to run unit tests for the catalog service.
# It checks for the existence of a test directory and runs all tests found within it.
# If any test fails, it will exit with an error code.
# If all tests pass, it will exit with a success code.
# Ensure that the script has execute permissions before running it:
# chmod +x run-tests.sh
# You can run this script from the command line:
# ./run-tests.sh   

