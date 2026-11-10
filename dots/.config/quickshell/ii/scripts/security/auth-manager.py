#!/usr/bin/env python3
"""
Authentication & Fingerprint Manager for Quickshell
Handles fprintd biometric enrollment, verification, deletion, and PAM password management.
All outputs are streamed or returned as JSON.
"""

import sys
import os
import subprocess
import json
import pty
import select
import signal
import getpass

def get_current_user():
    return os.environ.get("USER") or getpass.getuser()

def cmd_status(user=None):
    if not user:
        user = get_current_user()
    try:
        dev_res = subprocess.run(
            ['busctl', 'call', 'net.reactivated.Fprint', '/net/reactivated/Fprint/Manager', 'net.reactivated.Fprint.Manager', 'GetDefaultDevice'],
            capture_output=True, text=True, timeout=5
        )
        if dev_res.returncode != 0:
            print(json.dumps({
                "available": False,
                "error": "No fingerprint device found on system."
            }))
            return

        dev_path = dev_res.stdout.strip().split()[-1].strip('"')

        name_res = subprocess.run(
            ['busctl', 'get-property', 'net.reactivated.Fprint', dev_path, 'net.reactivated.Fprint.Device', 'name'],
            capture_output=True, text=True, timeout=5
        )
        dev_name = "Fingerprint Sensor"
        if name_res.returncode == 0:
            txt = name_res.stdout.strip()
            first_q = txt.find('"')
            last_q = txt.rfind('"')
            if first_q != -1 and last_q > first_q:
                dev_name = txt[first_q + 1 : last_q]

        stages_res = subprocess.run(
            ['busctl', 'get-property', 'net.reactivated.Fprint', dev_path, 'net.reactivated.Fprint.Device', 'num-enroll-stages'],
            capture_output=True, text=True, timeout=5
        )
        stages = 10
        if stages_res.returncode == 0:
            try:
                stages = int(stages_res.stdout.strip().split()[-1])
            except ValueError:
                pass

        scan_res = subprocess.run(
            ['busctl', 'get-property', 'net.reactivated.Fprint', dev_path, 'net.reactivated.Fprint.Device', 'scan-type'],
            capture_output=True, text=True, timeout=5
        )
        scan_type = "press"
        if scan_res.returncode == 0:
            txt = scan_res.stdout.strip()
            first_q = txt.find('"')
            last_q = txt.rfind('"')
            if first_q != -1 and last_q > first_q:
                scan_type = txt[first_q + 1 : last_q]

        list_res = subprocess.run(
            ['busctl', 'call', 'net.reactivated.Fprint', dev_path, 'net.reactivated.Fprint.Device', 'ListEnrolledFingers', 's', user],
            capture_output=True, text=True, timeout=5
        )
        enrolled = []
        if list_res.returncode == 0:
            parts = list_res.stdout.strip().split()
            if len(parts) >= 3:
                for p in parts[2:]:
                    clean_finger = p.strip('"')
                    if clean_finger:
                        enrolled.append(clean_finger)

        print(json.dumps({
            "available": True,
            "devicePath": dev_path,
            "deviceName": dev_name,
            "numStages": stages,
            "scanType": scan_type,
            "enrolledFingers": enrolled
        }))
    except Exception as e:
        print(json.dumps({
            "available": False,
            "error": str(e)
        }))

def cmd_enroll(finger, user=None):
    if not user:
        user = get_current_user()

    # Get total stages
    total_stages = 10
    try:
        dev_res = subprocess.run(
            ['busctl', 'call', 'net.reactivated.Fprint', '/net/reactivated/Fprint/Manager', 'net.reactivated.Fprint.Manager', 'GetDefaultDevice'],
            capture_output=True, text=True, timeout=5
        )
        if dev_res.returncode == 0:
            dev_path = dev_res.stdout.strip().split()[-1].strip('"')
            stages_res = subprocess.run(
                ['busctl', 'get-property', 'net.reactivated.Fprint', dev_path, 'net.reactivated.Fprint.Device', 'num-enroll-stages'],
                capture_output=True, text=True, timeout=5
            )
            if stages_res.returncode == 0:
                total_stages = int(stages_res.stdout.strip().split()[-1])
    except Exception:
        pass

    cmd = ['fprintd-enroll', '-f', finger, user]
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    current_stage = 0
    sys.stdout.reconfigure(line_buffering=True)
    print(json.dumps({
        "event": "start",
        "finger": finger,
        "stage": 0,
        "total": total_stages,
        "message": "Place your finger on the sensor to begin."
    }), flush=True)

    try:
        for line in iter(proc.stdout.readline, ''):
            line = line.strip()
            if not line:
                continue

            if "enroll-stage-passed" in line:
                current_stage += 1
                print(json.dumps({
                    "event": "stage",
                    "finger": finger,
                    "stage": current_stage,
                    "total": total_stages,
                    "message": f"Stage {current_stage}/{total_stages} passed! Lift and touch again."
                }), flush=True)
            elif "enroll-completed" in line:
                current_stage = total_stages
                print(json.dumps({
                    "event": "completed",
                    "finger": finger,
                    "stage": total_stages,
                    "total": total_stages,
                    "message": "Fingerprint enrolled successfully!"
                }), flush=True)
            elif "enroll-retry-scan" in line or "enroll-swipe-too-short" in line:
                print(json.dumps({
                    "event": "retry",
                    "finger": finger,
                    "stage": current_stage,
                    "total": total_stages,
                    "message": "Scan failed or swipe too short. Place your finger firmly and try again."
                }), flush=True)
            elif "enroll-finger-not-removed" in line:
                print(json.dumps({
                    "event": "not_removed",
                    "finger": finger,
                    "stage": current_stage,
                    "total": total_stages,
                    "message": "Please lift your finger from the sensor."
                }), flush=True)
            elif "enroll-unknown-error" in line or "error" in line.lower() or "failed" in line.lower():
                print(json.dumps({
                    "event": "error",
                    "finger": finger,
                    "stage": current_stage,
                    "total": total_stages,
                    "message": line
                }), flush=True)

        proc.stdout.close()
        rc = proc.wait()
        if rc != 0 and current_stage < total_stages:
            print(json.dumps({
                "event": "error",
                "finger": finger,
                "stage": current_stage,
                "total": total_stages,
                "message": "Enrollment process terminated or timed out."
            }), flush=True)
    except Exception as e:
        print(json.dumps({
            "event": "error",
            "finger": finger,
            "message": str(e)
        }), flush=True)
    finally:
        if proc.poll() is None:
            proc.terminate()

def cmd_delete(finger=None, user=None):
    if not user:
        user = get_current_user()
    cmd = ['fprintd-delete', user]
    if finger:
        cmd.extend(['-f', finger])
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if res.returncode == 0:
            print(json.dumps({
                "success": True,
                "message": f"Fingerprint '{finger}' deleted." if finger else "All fingerprints deleted."
            }))
        else:
            print(json.dumps({
                "success": False,
                "error": res.stderr.strip() or res.stdout.strip() or "Failed to delete fingerprint."
            }))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }))

def cmd_verify(finger=None, user=None):
    if not user:
        user = get_current_user()
    cmd = ['fprintd-verify', user]
    if finger:
        cmd.extend(['-f', finger])
    
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    sys.stdout.reconfigure(line_buffering=True)
    print(json.dumps({
        "event": "start",
        "message": "Place your enrolled finger on the sensor to verify."
    }), flush=True)

    try:
        for line in iter(proc.stdout.readline, ''):
            line = line.strip()
            if not line:
                continue
            if "verify-match" in line:
                print(json.dumps({
                    "event": "matched",
                    "message": "Fingerprint verified successfully! Match confirmed."
                }), flush=True)
            elif "verify-no-match" in line:
                print(json.dumps({
                    "event": "no_match",
                    "message": "Fingerprint did not match any enrolled finger."
                }), flush=True)
            elif "verify-retry-scan" in line or "verify-swipe-too-short" in line:
                print(json.dumps({
                    "event": "retry",
                    "message": "Scan failed. Place finger firmly and try again."
                }), flush=True)
            elif "error" in line.lower() or "failed" in line.lower():
                print(json.dumps({
                    "event": "error",
                    "message": line
                }), flush=True)
        proc.stdout.close()
        proc.wait()
    except Exception as e:
        print(json.dumps({
            "event": "error",
            "message": str(e)
        }), flush=True)
    finally:
        if proc.poll() is None:
            proc.terminate()

def cmd_change_password():
    try:
        raw_input = sys.stdin.read().strip()
        data = json.loads(raw_input)
        current_pass = data.get("currentPassword", "")
        new_pass = data.get("newPassword", "")

        if not current_pass:
            print(json.dumps({"success": False, "error": "Current password cannot be empty."}))
            return
        if not new_pass:
            print(json.dumps({"success": False, "error": "New password cannot be empty."}))
            return

        master, slave = pty.openpty()
        proc = os.fork()
        if proc == 0:
            os.close(master)
            os.setsid()
            os.dup2(slave, 0)
            os.dup2(slave, 1)
            os.dup2(slave, 2)
            os.close(slave)
            os.execlp('passwd', 'passwd')
            sys.exit(1)

        os.close(slave)
        output = b""
        stage = 0  # 0: waiting for current password prompt, 1: waiting for new password, 2: waiting for confirm
        success = False
        error_msg = ""

        try:
            while True:
                r, _, _ = select.select([master], [], [], 6.0)
                if not r:
                    error_msg = "Password change process timed out."
                    break
                try:
                    chunk = os.read(master, 1024)
                except OSError as e:
                    if e.errno == 5:
                        break
                    raise
                if not chunk:
                    break
                output += chunk
                lower_out = output.lower()

                if stage == 0 and (b"current password:" in lower_out or b"old password:" in lower_out):
                    os.write(master, (current_pass + "\n").encode('utf-8'))
                    output = b""
                    stage = 1
                elif stage == 1 and (b"new password:" in lower_out):
                    os.write(master, (new_pass + "\n").encode('utf-8'))
                    output = b""
                    stage = 2
                elif stage == 2 and (b"retype new password:" in lower_out or b"re-enter new password:" in lower_out):
                    os.write(master, (new_pass + "\n").encode('utf-8'))
                    output = b""
                    stage = 3
        finally:
            os.close(master)
            _, status = os.waitpid(proc, 0)
            exit_code = os.waitstatus_to_exitcode(status)

        all_text = output.decode('utf-8', errors='replace').strip()

        if exit_code == 0:
            print(json.dumps({
                "success": True,
                "message": "Password updated successfully."
            }))
        else:
            if not error_msg:
                if "Authentication failure" in all_text or "authentication token" in all_text.lower() or "incorrect" in all_text.lower():
                    error_msg = "Incorrect current password."
                elif "password unchanged" in all_text.lower() or "did not match" in all_text.lower():
                    error_msg = "Passwords do not match or password remained unchanged."
                elif all_text:
                    error_msg = all_text
                else:
                    error_msg = f"Failed to update password (exit code {exit_code})."
            print(json.dumps({
                "success": False,
                "error": error_msg
            }))

    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": f"Error executing password change: {str(e)}"
        }))

def main():
    if len(sys.argv) < 2:
        print("Usage: auth-manager.py <status|enroll|delete|verify|change-password> [args...]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "status":
        cmd_status()
    elif cmd == "enroll":
        finger = "right-index-finger"
        if len(sys.argv) >= 4 and sys.argv[2] in ["-f", "--finger"]:
            finger = sys.argv[3]
        elif len(sys.argv) >= 3:
            finger = sys.argv[2]
        cmd_enroll(finger)
    elif cmd == "delete":
        finger = None
        if len(sys.argv) >= 4 and sys.argv[2] in ["-f", "--finger"]:
            finger = sys.argv[3]
        elif len(sys.argv) >= 3:
            finger = sys.argv[2]
        cmd_delete(finger)
    elif cmd == "verify":
        finger = None
        if len(sys.argv) >= 4 and sys.argv[2] in ["-f", "--finger"]:
            finger = sys.argv[3]
        cmd_verify(finger)
    elif cmd == "change-password":
        cmd_change_password()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
