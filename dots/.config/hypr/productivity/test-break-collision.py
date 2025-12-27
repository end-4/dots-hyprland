#!/usr/bin/env python3
"""
Test script for break collision detection logic
Simulates various timing scenarios to verify the fix works correctly
"""

import time

# Simulate configuration
config = {
    'eye_care': {
        'enabled': True,
        'interval': 1200  # 20 minutes
    },
    'break_reminders': {
        'enabled': True,
        'interval': 3600  # 60 minutes
    }
}

def simulate_collision_check(current_time, last_eye_care, last_break):
    """
    Simulate the collision detection logic
    Returns: (should_show_eye_care, should_show_break, reason)
    """
    eye_care_due = current_time - last_eye_care >= config['eye_care']['interval']
    break_due = current_time - last_break >= config['break_reminders']['interval']
    
    if not eye_care_due and not break_due:
        return (False, False, "Nothing due")
    
    if break_due:
        return (False, True, "Long break due (resets both timers)")
    
    if eye_care_due:
        # Check collision
        break_interval = config['break_reminders']['interval']
        time_until_break = break_interval - (current_time - last_break)
        
        if abs(time_until_break) <= 30:
            return (False, False, f"Collision detected (break in {time_until_break:.0f}s) - eye care skipped")
        
        return (True, False, "Eye care break (no collision)")
    
    return (False, False, "Unknown state")


def run_test(name, start_time, last_eye, last_break, expected_eye, expected_break):
    """Run a single test case"""
    print(f"\n{'='*70}")
    print(f"TEST: {name}")
    print(f"{'='*70}")
    
    eye, brk, reason = simulate_collision_check(start_time, last_eye, last_break)
    
    print(f"Time since last eye care: {start_time - last_eye:.0f}s ({(start_time - last_eye)/60:.1f}min)")
    print(f"Time since last break:    {start_time - last_break:.0f}s ({(start_time - last_break)/60:.1f}min)")
    print(f"\nResult: {reason}")
    print(f"  Show eye care: {eye}")
    print(f"  Show break:    {brk}")
    
    passed = (eye == expected_eye and brk == expected_break)
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"\n{status}")
    
    if not passed:
        print(f"Expected: eye_care={expected_eye}, break={expected_break}")
    
    return passed


def main():
    """Run all test cases"""
    print("Break Collision Detection Test Suite")
    print("=" * 70)
    
    start = 0
    results = []
    
    # Test 1: Nothing due yet (10 minutes elapsed)
    results.append(run_test(
        "10 minutes - Nothing due",
        start_time=start + 600,
        last_eye=start,
        last_break=start,
        expected_eye=False,
        expected_break=False
    ))
    
    # Test 2: First eye care break (20 minutes)
    results.append(run_test(
        "20 minutes - First eye care",
        start_time=start + 1200,
        last_eye=start,
        last_break=start,
        expected_eye=True,
        expected_break=False
    ))
    
    # Test 3: Second eye care break (40 minutes)
    results.append(run_test(
        "40 minutes - Second eye care",
        start_time=start + 2400,
        last_eye=start + 1200,
        last_break=start,
        expected_eye=True,
        expected_break=False
    ))
    
    # Test 4: COLLISION - Third eye care + long break (60 minutes)
    results.append(run_test(
        "60 minutes - COLLISION (should skip eye care)",
        start_time=start + 3600,
        last_eye=start + 2400,
        last_break=start,
        expected_eye=False,  # Should skip due to collision
        expected_break=True  # Long break takes priority
    ))
    
    # Test 5: After long break, next eye care (80 minutes)
    # Note: After long break, both timers reset to 60min mark
    results.append(run_test(
        "80 minutes - Eye care after long break",
        start_time=start + 4800,
        last_eye=start + 3600,  # Reset by long break
        last_break=start + 3600,
        expected_eye=True,
        expected_break=False
    ))
    
    # Test 6: Edge case - Eye care due 25 seconds before long break
    results.append(run_test(
        "59:35 - Eye care just before long break (should skip)",
        start_time=start + 3575,
        last_eye=start + 2400,
        last_break=start,
        expected_eye=False,  # Within 30s window, should skip
        expected_break=False  # Break not quite due yet
    ))
    
    # Test 7: Edge case - Eye care due 35 seconds before long break
    results.append(run_test(
        "59:25 - Eye care 35s before long break (should show)",
        start_time=start + 3565,
        last_eye=start + 2365,  # 1200s ago = 20 minutes
        last_break=start,
        expected_eye=True,  # Outside 30s window, should show
        expected_break=False
    ))
    
    # Summary
    print(f"\n{'='*70}")
    print("TEST SUMMARY")
    print(f"{'='*70}")
    passed = sum(results)
    total = len(results)
    print(f"Passed: {passed}/{total}")
    print(f"Failed: {total - passed}/{total}")
    
    if passed == total:
        print("\n✅ All tests passed!")
        return 0
    else:
        print("\n❌ Some tests failed")
        return 1


if __name__ == '__main__':
    exit(main())
