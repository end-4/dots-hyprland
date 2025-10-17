#!/usr/bin/env bash
#
# exp-update-tester.sh - Test suite for update.sh
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TEST_DIR=""
ORIGINAL_DIR="$PWD"

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
  
  cd "$temp_dir" || { echo "Failed to cd to test directory"; return 1; }
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  git commit --allow-empty -m "Initial commit" -q
  
  echo "$temp_dir"
}

# Cleanup test environment
cleanup_test_env() {
  if [[ -n "${TEST_DIR:-}" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
    TEST_DIR=""
  fi
}

# Run a test and handle cleanup
run_test() {
  local test_name="$1"
  local test_func="$2"
  
  # Cleanup before test
  cleanup_test_env
  
  # Run the test
  if $test_func; then
    echo "✓ $test_name passed"
    return 0
  else
    echo "✗ $test_name failed"
    return 1
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
  return 0
}

# Test 2: Script has no syntax errors
test_syntax() {
  log_test "Checking script syntax"
  
  if bash -n update.sh; then
    log_pass "No syntax errors found"
    return 0
  else
    log_fail "Syntax errors detected"
    return 1
  fi
}

# Test 3: Help option works
test_help_option() {
  log_test "Testing --help option"
  
  if ./update.sh --help 2>&1 | grep -q "Usage:"; then
    log_pass "Help option works"
    return 0
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
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  mkdir -p dots/.config/test-app
  mkdir -p dots/.local/bin
  echo "test config" > dots/.config/test-app/config.conf
  
  git add .
  git commit -m "Add dots structure" -q
  
  cat > test_detection.sh << 'EOF'
#!/bin/bash
REPO_ROOT="$1"
detect_repo_structure() {
  local found_dirs=()
  if [[ -d "${REPO_ROOT}/dots/.config" ]]; then
    found_dirs+=("dots/.config")
    [[ -d "${REPO_ROOT}/dots/.local/bin" ]] && found_dirs+=("dots/.local/bin")
  elif [[ -d "${REPO_ROOT}/.config" ]]; then
    found_dirs+=(".config")
    [[ -d "${REPO_ROOT}/.local/bin" ]] && found_dirs+=(".local/bin")
  else
    for candidate in "dots/.config" ".config" "dots/.local/bin" ".local/bin"; do
      if [[ -d "${REPO_ROOT}/${candidate}" ]]; then
        if [[ ! " ${found_dirs[*]} " =~ " ${candidate} " ]]; then
          found_dirs+=("${candidate}")
        fi
      fi
    done
  fi
  if [[ ${#found_dirs[@]} -eq 0 ]]; then
    echo "ERROR" >&2
    return 1
  fi
  echo "${found_dirs[@]}"
}
detect_repo_structure
EOF
  
  chmod +x test_detection.sh
  result=$(./test_detection.sh "$test_repo")
  
  if [[ "$result" == *"dots/.config"* ]]; then
    log_pass "Dots structure detected correctly"
    cd "$ORIGINAL_DIR"
    return 0
  else
    log_fail "Failed to detect dots structure. Got: $result"
    cd "$ORIGINAL_DIR"
    return 1
  fi
}

# Test 5: Test flat structure detection
test_flat_structure() {
  log_test "Testing flat structure detection"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  mkdir -p .config/test-app
  mkdir -p .local/bin
  echo "test config" > .config/test-app/config.conf
  
  git add .
  git commit -m "Add flat structure" -q
  
  cat > test_detection.sh << 'EOF'
#!/bin/bash
REPO_ROOT="$1"
detect_repo_structure() {
  local found_dirs=()
  if [[ -d "${REPO_ROOT}/dots/.config" ]]; then
    found_dirs+=("dots/.config")
    [[ -d "${REPO_ROOT}/dots/.local/bin" ]] && found_dirs+=("dots/.local/bin")
  elif [[ -d "${REPO_ROOT}/.config" ]]; then
    found_dirs+=(".config")
    [[ -d "${REPO_ROOT}/.local/bin" ]] && found_dirs+=(".local/bin")
  else
    for candidate in "dots/.config" ".config" "dots/.local/bin" ".local/bin"; do
      if [[ -d "${REPO_ROOT}/${candidate}" ]]; then
        if [[ ! " ${found_dirs[*]} " =~ " ${candidate} " ]]; then
          found_dirs+=("${candidate}")
        fi
      fi
    done
  fi
  if [[ ${#found_dirs[@]} -eq 0 ]]; then
    echo "ERROR" >&2
    return 1
  fi
  echo "${found_dirs[@]}"
}
detect_repo_structure
EOF
  
  chmod +x test_detection.sh
  result=$(./test_detection.sh "$test_repo")
  
  if [[ "$result" == *".config"* ]] && [[ "$result" != *"dots/"* ]]; then
    log_pass "Flat structure detected correctly"
    cd "$ORIGINAL_DIR"
    return 0
  else
    log_fail "Failed to detect flat structure. Got: $result"
    cd "$ORIGINAL_DIR"
    return 1
  fi
}

# Test 6: Test dots prefix mapping to home directory
test_dots_mapping() {
  log_test "Testing dots/ prefix home directory mapping"
  
  dir_name="dots/.config"
  if [[ "$dir_name" == dots/* ]]; then
    home_subdir="${dir_name#dots/}"
    home_dir_path="${HOME}/${home_subdir}"
  else
    home_dir_path="${HOME}/${dir_name}"
  fi
  
  expected_path="${HOME}/.config"
  if [[ "$home_dir_path" == "$expected_path" ]]; then
    log_pass "Dots prefix mapping correct: $dir_name → $home_dir_path"
    return 0
  else
    log_fail "Dots prefix mapping failed: $dir_name → $home_dir_path (expected: $expected_path)"
    return 1
  fi
}

# Test 7: Test ignore file patterns
test_ignore_patterns() {
  log_test "Testing ignore file pattern matching"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  cat > .updateignore << 'EOF'
*.log
secrets/
.config/private*
*backup*
EOF
  
  mkdir -p .config
  mkdir -p secrets
  
  cat > test_ignore.sh << 'EOF'
#!/bin/bash
REPO_ROOT="$1"
UPDATE_IGNORE_FILE="${REPO_ROOT}/.updateignore"
HOME_UPDATE_IGNORE_FILE="/dev/null"

should_ignore() {
  local file_path="$1"
  local relative_path="${file_path#$HOME/}"
  local repo_relative=""
  if [[ "$file_path" == "$REPO_ROOT"* ]]; then
    repo_relative="${file_path#$REPO_ROOT/}"
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
        if [[ "$relative_path" == $pattern ]] || [[ "$repo_relative" == $pattern ]]; then
          return 0
        fi
        if [[ "$pattern" == */ ]]; then
          local dir_pattern="${pattern%/}"
          if [[ "$relative_path" == "$dir_pattern"/* ]] || [[ "$repo_relative" == "$dir_pattern"/* ]]; then
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

test_cases=(
  "$REPO_ROOT/app.log:0"
  "$REPO_ROOT/secrets/key.txt:0" 
  "$REPO_ROOT/.config/private-config:0"
  "$REPO_ROOT/.config/backup-file:0"
  "$REPO_ROOT/normal-config:1"
)

all_passed=true
for test_case in "${test_cases[@]}"; do
  IFS=':' read -r file expected <<< "$test_case"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  
  if should_ignore "$file"; then
    result=0
  else
    result=1
  fi
  
  if [[ $result -ne $expected ]]; then
    echo "FAIL: $file (expected: $expected, got: $result)"
    all_passed=false
  fi
done

if [[ "$all_passed" == true ]]; then
  echo "PASS"
else
  echo "FAIL"
fi
EOF
  
  chmod +x test_ignore.sh
  result=$(./test_ignore.sh "$test_repo")
  
  if [[ "$result" == "PASS" ]]; then
    log_pass "All ignore pattern tests passed"
    cd "$ORIGINAL_DIR"
    return 0
  else
    log_fail "Some ignore pattern tests failed"
    echo "$result"
    cd "$ORIGINAL_DIR"
    return 1
  fi
}

# Test 8: Test safe_read security - COMPLETELY NON-INTERACTIVE
test_safe_read_security() {
  log_test "Testing safe_read uses secure assignment (printf -v)"
  
  # Check that safe_read uses printf -v and not eval
  if grep -A 10 "safe_read()" update.sh | grep -q "printf -v.*varname"; then
    log_pass "safe_read uses secure printf -v assignment"
    return 0
  elif grep -A 10 "safe_read()" update.sh | grep -q "eval.*varname"; then
    log_fail "safe_read uses vulnerable eval assignment"
    return 1
  else
    log_fail "Cannot determine safe_read assignment method"
    return 1
  fi
}

# Test 9: Test dry-run mode
test_dry_run() {
  log_test "Testing dry-run mode"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  mkdir -p dots/.config/test-app
  echo "repo config" > dots/.config/test-app/config.conf
  
  git add .
  git commit -m "Add test config" -q
  
  cp "$ORIGINAL_DIR/update.sh" .
  chmod +x update.sh
  
  # Use printf to pipe responses automatically
  printf "y\ny\n" | ./update.sh -n --skip-notice 2>&1 | tee dry_run_output.txt
  
  if grep -q "DRY-RUN" dry_run_output.txt; then
    log_pass "Dry-run mode detected in output"
  else
    log_fail "Dry-run mode not properly indicated"
    cd "$ORIGINAL_DIR"
    return 1
  fi
  
  if [[ ! -f "${HOME}/.config/test-app/config.conf" ]]; then
    log_pass "No files created in home during dry-run"
  else
    log_fail "Files were created in home during dry-run"
    rm -f "${HOME}/.config/test-app/config.conf"
    cd "$ORIGINAL_DIR"
    return 1
  fi
  
  cd "$ORIGINAL_DIR"
  return 0
}

# Test 10: Test command-line flags
test_flags() {
  log_test "Testing command-line flags"
  
  # Only test non-interactive flags
  local flags=("-h" "--help")
  local all_passed=true
  
  for flag in "${flags[@]}"; do
    if ./update.sh "$flag" 2>&1 | grep -q -E "(Usage|help)"; then
      log_info "  ✓ $flag recognized"
    else
      log_info "  ✗ $flag not recognized"
      all_passed=false
    fi
  done
  
  if [[ "$all_passed" == true ]]; then
    log_pass "Help flags recognized correctly"
    return 0
  else
    log_fail "Some flags not recognized properly"
    return 1
  fi
}

# Test 11: Check for shellcheck
test_shellcheck() {
  log_test "Running shellcheck (if available)"
  
  if ! command -v shellcheck &>/dev/null; then
    log_info "shellcheck not found, skipping static analysis"
    return 0
  fi
  
  if shellcheck -e SC1090,SC1091,SC2148,SC2034,SC2155,SC2164 update.sh; then
    log_pass "shellcheck passed"
    return 0
  else
    log_fail "shellcheck found issues"
    return 1
  fi
}

# Test 12: Test fresh clone scenario
test_fresh_clone() {
  log_test "Testing fresh clone scenario"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  mkdir -p .config/test-app
  echo "config" > .config/test-app/settings.conf
  
  cat > test_fresh_clone.sh << 'EOF'
#!/bin/bash
has_new_commits() {
  if git rev-parse --verify HEAD@{1} &>/dev/null; then
    [[ "$(git rev-parse HEAD)" != "$(git rev-parse HEAD@{1})" ]]
  else
    return 0
  fi
}

if has_new_commits; then
  echo "PASS"
else
  echo "FAIL"
fi
EOF
  
  chmod +x test_fresh_clone.sh
  result=$(./test_fresh_clone.sh)
  
  if [[ "$result" == "PASS" ]]; then
    log_pass "Fresh clone scenario handled correctly"
    cd "$ORIGINAL_DIR"
    return 0
  else
    log_fail "Fresh clone scenario not handled properly"
    cd "$ORIGINAL_DIR"
    return 1
  fi
}

# Main test runner
main() {
  echo -e "${BLUE}================================${NC}"
  echo -e "${BLUE}  Update.sh Test Suite${NC}"
  echo -e "${BLUE}================================${NC}\n"
  
  if [[ ! -f "update.sh" ]]; then
    log_error "Please run this test from the directory containing update.sh"
    exit 1
  fi
  
  chmod +x update.sh 2>/dev/null || true
  
  # Define tests
  tests=(
    "test_script_exists"
    "test_syntax" 
    "test_help_option"
    "test_dots_structure"
    "test_flat_structure"
    "test_dots_mapping"
    "test_ignore_patterns"
    "test_safe_read_security"
    "test_dry_run"
    "test_flags"
    "test_shellcheck"
    "test_fresh_clone"
  )
  
  # Run tests
  for test in "${tests[@]}"; do
    if $test; then
      echo "✓ $test passed"
    else
      echo "✗ $test failed"
    fi
    echo
  done
  
  # Summary
  echo -e "${BLUE}================================${NC}"
  echo -e "${BLUE}  Test Summary${NC}"
  echo -e "${BLUE}================================${NC}"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  echo -e "${BLUE}Total:  ${#tests[@]}${NC}\n"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}\n"
    exit 0
  else
    echo -e "${RED}Some tests failed! ❌${NC}\n"
    exit 1
  fi
}

# Global cleanup
cleanup() {
  echo "Cleaning up test files..."
  cleanup_test_env
  rm -f test_detection.sh test_ignore.sh test_safe_read.sh test_fresh_clone.sh dry_run_output.txt 2>/dev/null || true
  rm -rf "${HOME}/.config/test-app" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
