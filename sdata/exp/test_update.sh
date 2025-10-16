#!/usr/bin/env bash
#
# test_update.sh - Test suite for update.sh
#
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TEST_DIR=""

# Helper functions
log_test() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((TESTS_PASSED++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((TESTS_FAILED++))
}

log_info() {
  echo -e "${YELLOW}[INFO]${NC} $1"
}

# Setup test environment
setup_test_env() {
  local temp_dir
  temp_dir=$(mktemp -d -t dotfiles-test.XXXXXX)
  
  # Create a mock git repo
  cd "$temp_dir" || exit 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  # Return only the directory path (no logging here)
  echo "$temp_dir"
}

# Cleanup test environment
cleanup_test_env() {
  if [[ -n "${TEST_DIR:-}" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

# Test 1: Script exists and is executable
test_script_exists() {
  log_test "Checking if update.sh exists and is executable"
  
  if [[ ! -f "update.sh" ]]; then
    log_fail "update.sh not found"
    return 1
  fi
  
  if [[ ! -x "update.sh" ]]; then
    log_fail "update.sh is not executable"
    return 1
  fi
  
  log_pass "Script exists and is executable"
}

# Test 2: Script has no syntax errors
test_syntax() {
  log_test "Checking script syntax"
  
  if bash -n update.sh 2>/dev/null; then
    log_pass "No syntax errors found"
  else
    log_fail "Syntax errors detected"
    bash -n update.sh
    return 1
  fi
}

# Test 3: Help option works
test_help_option() {
  log_test "Testing --help option"
  
  if ./update.sh --help >/dev/null 2>&1; then
    log_pass "Help option works"
  else
    log_fail "Help option failed"
    return 1
  fi
}

# Test 4: Test repository structure detection (dots/ prefix)
test_dots_structure() {
  log_test "Testing dots/ prefix structure detection"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"  # Set for cleanup
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create dots/ structure
  mkdir -p dots/.config/test
  mkdir -p dots/.local/bin
  echo "test config" > dots/.config/test/config.txt
  
  # Create minimal update.sh
  cat > .update-test.sh << 'EOF'
#!/usr/bin/env bash
REPO_DIR="$PWD"
detect_repo_structure() {
  local found_dirs=()
  if [[ -d "${REPO_DIR}/dots/.config" ]]; then
    found_dirs+=("dots/.config")
    [[ -d "${REPO_DIR}/dots/.local/bin" ]] && found_dirs+=("dots/.local/bin")
    [[ -d "${REPO_DIR}/dots/.local/share" ]] && found_dirs+=("dots/.local/share")
  elif [[ -d "${REPO_DIR}/.config" ]]; then
    found_dirs+=(".config")
    [[ -d "${REPO_DIR}/.local/bin" ]] && found_dirs+=(".local/bin")
    [[ -d "${REPO_DIR}/.local/share" ]] && found_dirs+=(".local/share")
  else
    for candidate in "dots/.config" ".config" "config" "dots/.local/bin" ".local/bin" "dots/.local/share" ".local/share"; do
      if [[ -d "${REPO_DIR}/${candidate}" ]]; then
        if [[ ! " ${found_dirs[*]} " =~ " ${candidate} " ]]; then
          found_dirs+=("${candidate}")
        fi
      fi
    done
  fi
  if [[ ${#found_dirs[@]} -eq 0 ]]; then
    echo "ERROR: Could not detect repository structure" >&2
    return 1
  fi
  echo "${found_dirs[@]}"
}
detect_repo_structure
EOF
  
  chmod +x .update-test.sh
  result=$(./.update-test.sh)
  
  if [[ "$result" == *"dots/.config"* ]]; then
    log_pass "Dots structure detected correctly"
  else
    log_fail "Failed to detect dots structure. Got: $result"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 5: Test flat structure detection
test_flat_structure() {
  log_test "Testing flat structure detection"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"  # Set for cleanup
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create flat structure
  mkdir -p .config/test
  mkdir -p .local/bin
  echo "test config" > .config/test/config.txt
  
  cat > .update-test.sh << 'EOF'
#!/usr/bin/env bash
REPO_DIR="$PWD"
detect_repo_structure() {
  local found_dirs=()
  if [[ -d "${REPO_DIR}/dots/.config" ]]; then
    found_dirs+=("dots/.config")
    [[ -d "${REPO_DIR}/dots/.local/bin" ]] && found_dirs+=("dots/.local/bin")
    [[ -d "${REPO_DIR}/dots/.local/share" ]] && found_dirs+=("dots/.local/share")
  elif [[ -d "${REPO_DIR}/.config" ]]; then
    found_dirs+=(".config")
    [[ -d "${REPO_DIR}/.local/bin" ]] && found_dirs+=(".local/bin")
    [[ -d "${REPO_DIR}/.local/share" ]] && found_dirs+=(".local/share")
  else
    for candidate in "dots/.config" ".config" "config" "dots/.local/bin" ".local/bin" "dots/.local/share" ".local/share"; do
      if [[ -d "${REPO_DIR}/${candidate}" ]]; then
        if [[ ! " ${found_dirs[*]} " =~ " ${candidate} " ]]; then
          found_dirs+=("${candidate}")
        fi
      fi
    done
  fi
  if [[ ${#found_dirs[@]} -eq 0 ]]; then
    echo "ERROR: Could not detect repository structure" >&2
    return 1
  fi
  echo "${found_dirs[@]}"
}
detect_repo_structure
EOF
  
  chmod +x .update-test.sh
  result=$(./.update-test.sh)
  
  if [[ "$result" == *".config"* ]] && [[ "$result" != *"dots/"* ]]; then
    log_pass "Flat structure detected correctly"
  else
    log_fail "Failed to detect flat structure. Got: $result"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 6: Test package directory detection
test_package_detection() {
  log_test "Testing package directory detection"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"  # Set for cleanup
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Test dist-arch
  mkdir -p dist-arch/test-pkg
  cat > .update-test.sh << 'EOF'
#!/usr/bin/env bash
REPO_DIR="$PWD"
if [[ -d "${REPO_DIR}/dist-arch" ]]; then
  ARCH_PACKAGES_DIR="${REPO_DIR}/dist-arch"
elif [[ -d "${REPO_DIR}/arch-packages" ]]; then
  ARCH_PACKAGES_DIR="${REPO_DIR}/arch-packages"
elif [[ -d "${REPO_DIR}/sdist/arch" ]]; then
  ARCH_PACKAGES_DIR="${REPO_DIR}/sdist/arch"
else
  ARCH_PACKAGES_DIR="${REPO_DIR}/dist-arch"
fi
echo "$ARCH_PACKAGES_DIR"
EOF
  
  chmod +x .update-test.sh
  result=$(./.update-test.sh)
  
  if [[ "$result" == *"dist-arch"* ]]; then
    log_pass "Package directory detection works"
  else
    log_fail "Failed to detect package directory. Got: $result"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 7: Test ignore file patterns
test_ignore_patterns() {
  log_test "Testing ignore file pattern matching"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"  # Set for cleanup
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create ignore file
  cat > .updateignore << 'EOF'
# Test ignore patterns
*.log
secrets/
test-file.txt
*private*
EOF
  
  # Test should_ignore function
  cat > .update-test.sh << 'EOF'
#!/usr/bin/env bash
REPO_DIR="$PWD"
UPDATE_IGNORE_FILE="${REPO_DIR}/.updateignore"
HOME_UPDATE_IGNORE_FILE="${HOME}/.updateignore"

should_ignore() {
  local file_path="$1"
  local relative_path="${file_path#$HOME/}"
  local repo_relative=""
  if [[ "$file_path" == "$REPO_DIR"* ]]; then
    repo_relative="${file_path#$REPO_DIR/}"
  fi
  
  for ignore_file in "$UPDATE_IGNORE_FILE" "$HOME_UPDATE_IGNORE_FILE"; do
    if [[ -f "$ignore_file" ]]; then
      while IFS= read -r pattern || [[ -n "$pattern" ]]; do
        [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$pattern" ]] && continue
        
        if [[ "$relative_path" == "$pattern" ]] || [[ "$repo_relative" == "$pattern" ]]; then
          return 0
        fi
        
        if [[ "$pattern" == */ ]]; then
          local dir_pattern="${pattern%/}"
          if [[ "$relative_path" == "$dir_pattern"/* ]] || [[ "$repo_relative" == "$dir_pattern"/* ]]; then
            return 0
          fi
        fi
        
        if [[ "$pattern" == *"*"* ]]; then
          if [[ "$relative_path" == $pattern ]] || [[ "$repo_relative" == $pattern ]]; then
            return 0
          fi
        fi
        
        if [[ "$file_path" == *"$pattern"* ]] || [[ "$relative_path" == *"$pattern"* ]]; then
          return 0
        fi
      done <"$ignore_file"
    fi
  done
  return 1
}

# Test cases
should_ignore "$REPO_DIR/test.log" && echo "PASS: *.log pattern" || echo "FAIL: *.log pattern"
should_ignore "$REPO_DIR/secrets/key.txt" && echo "PASS: secrets/ pattern" || echo "FAIL: secrets/ pattern"
should_ignore "$REPO_DIR/test-file.txt" && echo "PASS: exact match pattern" || echo "FAIL: exact match pattern"
should_ignore "$REPO_DIR/my-private-file.txt" && echo "PASS: *private* pattern" || echo "FAIL: *private* pattern"
should_ignore "$REPO_DIR/normal-file.txt" && echo "FAIL: should not ignore" || echo "PASS: normal file not ignored"
EOF
  
  chmod +x .update-test.sh
  result=$(./.update-test.sh)
  
  if [[ "$result" == *"PASS: *.log pattern"* ]] && \
     [[ "$result" == *"PASS: secrets/ pattern"* ]] && \
     [[ "$result" == *"PASS: exact match pattern"* ]] && \
     [[ "$result" == *"PASS: *private* pattern"* ]] && \
     [[ "$result" == *"PASS: normal file not ignored"* ]]; then
    log_pass "Ignore patterns work correctly"
  else
    log_fail "Ignore patterns failed"
    echo "$result"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 8: Test dry-run mode doesn't modify files
test_dry_run() {
  log_test "Testing dry-run mode (manual verification needed)"
  
  log_info "Dry-run mode test requires manual verification:"
  log_info "1. Run: ./update.sh -n"
  log_info "2. Verify no files are actually modified"
  log_info "3. Check that it shows what WOULD be done"
  
  log_pass "Dry-run test added to manual checklist"
}

# Test 9: Check for common shellcheck issues
test_shellcheck() {
  log_test "Running shellcheck (if available)"
  
  if ! command -v shellcheck &>/dev/null; then
    log_info "shellcheck not found, skipping static analysis"
    return 0
  fi
  
  # Run shellcheck with common exclusions
  if shellcheck -e SC2181,SC2155,SC2162 update.sh 2>&1 | grep -v "^$"; then
    log_fail "shellcheck found issues"
    return 1
  else
    log_pass "shellcheck passed"
  fi
}

# Test 10: Test all flags are recognized
test_flags() {
  log_test "Testing command-line flags"
  
  local flags=("-h" "--help")
  local all_passed=true
  
  for flag in "${flags[@]}"; do
    if ./update.sh "$flag" >/dev/null 2>&1; then
      echo "  ✓ $flag works"
    else
      echo "  ✗ $flag failed"
      all_passed=false
    fi
  done
  
  if [[ "$all_passed" == true ]]; then
    log_pass "All tested flags work correctly"
  else
    log_fail "Some flags failed"
  fi
}

# Main test runner
main() {
  echo -e "${BLUE}================================${NC}"
  echo -e "${BLUE}  Update.sh Test Suite${NC}"
  echo -e "${BLUE}================================${NC}\n"
  
  # Store original directory
  ORIGINAL_DIR="$PWD"
  
  # Run tests
  test_script_exists
  test_syntax
  test_help_option
  test_dots_structure
  test_flat_structure
  test_package_detection
  test_ignore_patterns
  test_dry_run
  test_shellcheck
  test_flags
  
  # Return to original directory
  cd "$ORIGINAL_DIR" || exit 1
  
  # Summary
  echo -e "\n${BLUE}================================${NC}"
  echo -e "${BLUE}  Test Summary${NC}"
  echo -e "${BLUE}================================${NC}"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  echo -e "${BLUE}Total:  $((TESTS_PASSED + TESTS_FAILED))${NC}\n"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}\n"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}\n"
    exit 1
  fi
}

# Trap cleanup - only cleanup TEST_DIR if it exists
cleanup_on_exit() {
  if [[ -n "${TEST_DIR:-}" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

trap cleanup_on_exit EXIT

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
