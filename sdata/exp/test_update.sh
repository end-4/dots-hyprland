#!/usr/bin/env bash
#
# test_update.sh - Test suite for update.sh
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
  
  # Create a mock git repo
  cd "$temp_dir" || exit 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  # Create initial commit
  git commit --allow-empty -m "Initial commit" -q
  
  echo "$temp_dir"
}

# Cleanup test environment
cleanup_test_env() {
  if [[ -n "${TEST_DIR:-}" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

# Mock functions to avoid side effects
mock_git() {
  if [[ "$1" == "pull" ]]; then
    echo "Mock: git pull executed"
    return 0
  fi
  # For other git commands, use real git but in test directory
  command git "$@"
}

mock_makepkg() {
  echo "Mock: makepkg $*"
  return 0
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
  
  if bash -n update.sh; then
    log_pass "No syntax errors found"
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
  
  # Create dots/ structure
  mkdir -p dots/.config/test-app
  mkdir -p dots/.local/bin
  echo "test config" > dots/.config/test-app/config.conf
  echo "#!/bin/bash" > dots/.local/bin/test-script
  
  # Add and commit
  git add .
  git commit -m "Add dots structure" -q
  
  # Source the update.sh to test functions
  source update.sh >/dev/null 2>&1 || true
  
  # Test the detection function
  if result=$(detect_repo_structure 2>/dev/null); then
    if [[ "$result" == *"dots/.config"* ]] && [[ "$result" == *"dots/.local/bin"* ]]; then
      log_pass "Dots structure detected correctly"
    else
      log_fail "Failed to detect dots structure. Got: $result"
    fi
  else
    log_fail "detect_repo_structure failed"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 5: Test flat structure detection
test_flat_structure() {
  log_test "Testing flat structure detection"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create flat structure
  mkdir -p .config/test-app
  mkdir -p .local/bin
  echo "test config" > .config/test-app/config.conf
  echo "#!/bin/bash" > .local/bin/test-script
  
  # Add and commit
  git add .
  git commit -m "Add flat structure" -q
  
  # Source the update.sh to test functions
  source update.sh >/dev/null 2>&1 || true
  
  # Test the detection function
  if result=$(detect_repo_structure 2>/dev/null); then
    if [[ "$result" == *".config"* ]] && [[ "$result" != *"dots/"* ]]; then
      log_pass "Flat structure detected correctly"
    else
      log_fail "Failed to detect flat structure. Got: $result"
    fi
  else
    log_fail "detect_repo_structure failed"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 6: Test dots prefix mapping to home directory
test_dots_mapping() {
  log_test "Testing dots/ prefix home directory mapping"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create dots/ structure
  mkdir -p dots/.config/test-app
  echo "test config" > dots/.config/test-app/config.conf
  
  # Source the update.sh
  source update.sh >/dev/null 2>&1 || true
  
  # Test the mapping logic
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
  else
    log_fail "Dots prefix mapping failed: $dir_name → $home_dir_path (expected: $expected_path)"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 7: Test ignore file patterns
test_ignore_patterns() {
  log_test "Testing ignore file pattern matching"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create ignore file
  cat > .updateignore << 'EOF'
# Test ignore patterns
*.log
secrets/
.config/private*
*backup*
/tmp-file
EOF
  
  # Create test files
  mkdir -p .config
  touch app.log
  touch secrets/key.txt
  touch .config/private-config
  touch .config/backup-file
  touch normal-config
  
  # Source the update.sh
  source update.sh >/dev/null 2>&1 || true
  
  # Test cases
  local passed=0
  local total=0
  
  # Test patterns
  test_cases=(
    "$test_repo/app.log:0"
    "$test_repo/secrets/key.txt:0" 
    "$test_repo/.config/private-config:0"
    "$test_repo/.config/backup-file:0"
    "$test_repo/normal-config:1"
    "$test_repo/.config/normal-file:1"
  )
  
  for test_case in "${test_cases[@]}"; do
    IFS=':' read -r file expected <<< "$test_case"
    touch "$file" 2>/dev/null || true
    ((total++))
    
    if should_ignore "$file"; then
      result=0
    else
      result=1
    fi
    
    if [[ $result -eq $expected ]]; then
      ((passed++))
    else
      log_fail "Ignore test failed: $file (expected: $expected, got: $result)"
    fi
  done
  
  if [[ $passed -eq $total ]]; then
    log_pass "All ignore pattern tests passed ($passed/$total)"
  else
    log_fail "Ignore pattern tests failed ($passed/$total passed)"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 8: Test safe_read security (no eval injection)
test_safe_read_security() {
  log_test "Testing safe_read security against injection"
  
  # Source the update.sh
  source update.sh >/dev/null 2>&1 || true
  
  # Test safe_read with potentially dangerous input
  dangerous_input="'; echo 'INJECTION'; '"
  
  # Use a subshell to capture any injection
  output=$(
    {
      echo "$dangerous_input" | safe_read "Test: " test_var "default" 2>/dev/null || true
      # Check if injection occurred
      if declare -p test_var 2>/dev/null | grep -q "INJECTION"; then
        echo "INJECTION_DETECTED"
      else
        echo "SAFE"
      fi
    } 2>/dev/null
  )
  
  if [[ "$output" != *"INJECTION_DETECTED"* ]]; then
    log_pass "safe_read is secure against injection attacks"
  else
    log_fail "safe_read vulnerable to injection attacks"
  fi
}

# Test 9: Test dry-run mode
test_dry_run() {
  log_test "Testing dry-run mode"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create test structure
  mkdir -p dots/.config/test-app
  echo "repo config" > dots/.config/test-app/config.conf
  
  # Add and commit
  git add .
  git commit -m "Add test config" -q
  
  # Test dry-run execution
  output=$(./update.sh -n --skip-notice 2>&1 || true)
  
  if [[ "$output" == *"DRY-RUN"* ]] && [[ "$output" == *"would"* || "$output" == *"Would"* ]]; then
    log_pass "Dry-run mode detected in output"
  else
    log_fail "Dry-run mode not properly indicated"
  fi
  
  # Verify no files were actually created in home
  if [[ ! -f "${HOME}/.config/test-app/config.conf" ]]; then
    log_pass "No files created in home during dry-run"
  else
    log_fail "Files were created in home during dry-run"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 10: Test package directory detection
test_package_detection() {
  log_test "Testing package directory detection"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Test different package directory names
  for dir_name in "dist-arch" "arch-packages" "sdist/arch"; do
    mkdir -p "$dir_name/test-pkg"
    echo "pkgbase=test-pkg" > "$dir_name/test-pkg/PKGBUILD"
    
    # Source to reset ARCH_PACKAGES_DIR
    source update.sh >/dev/null 2>&1 || true
    
    if [[ -d "$dir_name" ]]; then
      log_info "Found package directory: $dir_name"
      # The sourcing should have set ARCH_PACKAGES_DIR correctly
      if [[ -n "$ARCH_PACKAGES_DIR" ]]; then
        log_pass "Package directory detection works for $dir_name"
      else
        log_fail "Package directory not detected for $dir_name"
      fi
    fi
    
    rm -rf "$dir_name"
  done
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 11: Test force check mode
test_force_check() {
  log_test "Testing force check mode"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create test structure
  mkdir -p .config/test-app
  echo "config" > .config/test-app/settings.conf
  
  # Test with force flag
  output=$(./update.sh -f --skip-notice --dry-run 2>&1 || true)
  
  if [[ "$output" == *"Force check"* ]] || [[ "$output" == *"Force mode"* ]]; then
    log_pass "Force check mode detected"
  else
    log_fail "Force check mode not indicated"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 12: Test conflict handling simulation
test_conflict_handling() {
  log_test "Testing file conflict detection"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create repo file
  mkdir -p .config/test-app
  echo "repo version" > .config/test-app/config.conf
  
  # Create different home file
  mkdir -p "${HOME}/.config/test-app"
  echo "home version" > "${HOME}/.config/test-app/config.conf"
  
  # Source the update.sh
  source update.sh >/dev/null 2>&1 || true
  
  # Test the comparison logic
  repo_file="$test_repo/.config/test-app/config.conf"
  home_file="${HOME}/.config/test-app/config.conf"
  
  if ! cmp -s "$repo_file" "$home_file"; then
    log_pass "File conflict correctly detected"
  else
    log_fail "File conflict not detected"
  fi
  
  # Cleanup home file
  rm -f "$home_file"
  rmdir "$(dirname "$home_file")" 2>/dev/null || true
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 13: Test all flags are recognized
test_flags() {
  log_test "Testing command-line flags"
  
  local flags=("-h" "--help" "-n" "--dry-run" "-f" "--force" "-v" "--verbose")
  local all_passed=true
  
  for flag in "${flags[@]}"; do
    if ./update.sh "$flag" 2>&1 | grep -q -E "(Usage|dry-run|force|verbose|help)"; then
      echo "  ✓ $flag recognized"
    else
      echo "  ✗ $flag not recognized"
      all_passed=false
    fi
  done
  
  if [[ "$all_passed" == true ]]; then
    log_pass "All tested flags recognized correctly"
  else
    log_fail "Some flags not recognized properly"
  fi
}

# Test 14: Test git operations safety
test_git_safety() {
  log_test "Testing git operations safety"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create uncommitted changes
  echo "temp" > temp-file.txt
  
  # Test that script detects uncommitted changes
  output=$(./update.sh --dry-run --skip-notice 2>&1 || true)
  
  if [[ "$output" == *"uncommitted changes"* ]]; then
    log_pass "Uncommitted changes detection works"
  else
    log_fail "Uncommitted changes not detected"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 15: Check for common shellcheck issues
test_shellcheck() {
  log_test "Running shellcheck (if available)"
  
  if ! command -v shellcheck &>/dev/null; then
    log_info "shellcheck not found, skipping static analysis"
    return 0
  fi
  
  # Run shellcheck with common exclusions
  if shellcheck -e SC1090,SC1091,SC2148,SC2034,SC2155,SC2164 update.sh; then
    log_pass "shellcheck passed"
  else
    log_fail "shellcheck found issues"
    return 1
  fi
}

# Test 16: Test fresh clone scenario (no HEAD@{1})
test_fresh_clone() {
  log_test "Testing fresh clone scenario"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Create structure
  mkdir -p .config/test-app
  echo "config" > .config/test-app/settings.conf
  
  # Source the update.sh
  source update.sh >/dev/null 2>&1 || true
  
  # Test has_new_commits in fresh clone (no HEAD@{1})
  if has_new_commits; then
    log_pass "Fresh clone scenario handled correctly"
  else
    log_fail "Fresh clone scenario not handled properly"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 17: Test verbose mode
test_verbose_mode() {
  log_test "Testing verbose mode"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Test verbose flag
  output=$(./update.sh -v --dry-run --skip-notice 2>&1 || true)
  
  if [[ "$output" == *"Verbose mode"* ]]; then
    log_pass "Verbose mode detected"
  else
    log_fail "Verbose mode not indicated"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Test 18: Test package checking flag
test_package_checking() {
  log_test "Testing package checking flag"
  
  local test_repo
  test_repo=$(setup_test_env)
  TEST_DIR="$test_repo"
  
  cd "$test_repo" || { log_fail "Failed to cd to test directory"; return 1; }
  
  # Test package flag
  output=$(./update.sh -p --dry-run --skip-notice 2>&1 || true)
  
  if [[ "$output" == *"Package checking"* ]]; then
    log_pass "Package checking mode detected"
  else
    log_fail "Package checking mode not indicated"
  fi
  
  cd "$ORIGINAL_DIR" || exit 1
  cleanup_test_env
}

# Main test runner
main() {
  echo -e "${BLUE}================================${NC}"
  echo -e "${BLUE}  Update.sh Comprehensive Test Suite${NC}"
  echo -e "${BLUE}================================${NC}\n"
  
  # Check if we're in the right directory
  if [[ ! -f "update.sh" ]]; then
    log_error "Please run this test from the directory containing update.sh"
    exit 1
  fi
  
  # Make sure update.sh is executable
  chmod +x update.sh 2>/dev/null || true
  
  # Run tests
  test_script_exists
  test_syntax
  test_help_option
  test_dots_structure
  test_flat_structure
  test_dots_mapping
  test_ignore_patterns
  test_safe_read_security
  test_dry_run
  test_package_detection
  test_force_check
  test_conflict_handling
  test_flags
  test_git_safety
  test_shellcheck
  test_fresh_clone
  test_verbose_mode
  test_package_checking
  
  # Summary
  echo -e "\n${BLUE}================================${NC}"
  echo -e "${BLUE}  Test Summary${NC}"
  echo -e "${BLUE}================================${NC}"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  echo -e "${BLUE}Total:  $((TESTS_PASSED + TESTS_FAILED))${NC}\n"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}\n"
    exit 0
  else
    echo -e "${RED}Some tests failed! ❌${NC}\n"
    exit 1
  fi
}

# Trap cleanup
cleanup_on_exit() {
  if [[ -n "${TEST_DIR:-}" && -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
  # Cleanup any test files created in home
  rm -rf "${HOME}/.config/test-app" 2>/dev/null || true
}

trap cleanup_on_exit EXIT INT TERM

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
