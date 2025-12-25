#!/usr/bin/env python3
"""
Save Break Enforcer Questionnaire Responses to Database

This script is called by break-enforcer.qml after each question is answered.
It stores the response in SQLite and updates daily statistics.

Usage:
    save-break-response.py <break_type> <duration> <question_id> <answer_id> [answer_text]

Arguments:
    break_type: "eye_care" or "break_reminder"
    duration: Break duration in seconds
    question_id: Question ID (1-3)
    answer_id: Selected answer ID
    answer_text: Optional text for text-type questions

Database Tables:
    - break_responses: Individual question responses
    - break_stats: Daily aggregated statistics
"""

import json
import sqlite3
import sys
from datetime import datetime
from pathlib import Path

# Configuration
HOME = Path.home()
DATA_DIR = HOME / ".local" / "share" / "digital-wellbeing"
DB_PATH = DATA_DIR / "usage.db"
CONFIG_DIR = HOME / ".config" / "hypr" / "productivity"
QUESTIONS_FILE = CONFIG_DIR / "break-questions.json"


def load_questions():
    """Load question definitions"""
    if not QUESTIONS_FILE.exists():
        return None
    with open(QUESTIONS_FILE, 'r') as f:
        return json.load(f)


def save_response(break_type, duration, question_id, answer_id, answer_text):
    """
    Save questionnaire response to database
    
    Args:
        break_type: Type of break ("eye_care" or "break_reminder")
        duration: Break duration in seconds
        question_id: Question ID from questions array
        answer_id: Selected answer ID
        answer_text: Text answer for text-type questions, None for choice questions
    
    Returns:
        bool: True if save successful, False otherwise
    """
    # Ensure data directory exists
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    
    # Connect to database
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get current timestamp and date
    now = datetime.now()
    timestamp = now.isoformat()
    date_str = now.strftime('%Y-%m-%d')
    
    try:
        # Insert response (store text for text-type questions, null for choice questions)
        cursor.execute('''
            INSERT INTO break_responses 
            (timestamp, break_type, duration, question_id, answer_id, answer_text, date)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (timestamp, break_type, duration, question_id, answer_id, answer_text if answer_text else None, date_str))
        
        conn.commit()
        
        # Update break stats
        update_break_stats(cursor, date_str, break_type)
        conn.commit()
        
        print(f"✓ Saved Q{question_id} A{answer_id} for {break_type}", file=sys.stderr)
        return True
        
    except Exception as e:
        print(f"✗ Error saving response: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return False
    finally:
        conn.close()


def update_break_stats(cursor, date_str, break_type):
    """
    Update daily break statistics efficiently
    
    This function:
    1. Creates stats entry for the day if not exists
    2. Increments break counters based on type
    3. Calculates average productivity score from Q1 responses
    
    Args:
        cursor: SQLite cursor object
        date_str: Date string in YYYY-MM-DD format
        break_type: Type of break for counter increment
    """
    # Create or update stats for the day (include total_responses)
    cursor.execute('''
        INSERT INTO break_stats (date, eye_care_count, break_reminder_count, total_responses)
        VALUES (?, 0, 0, 0)
        ON CONFLICT(date) DO NOTHING
    ''', (date_str,))
    
    # Increment counters in a single query
    if break_type == 'eye_care':
        cursor.execute('''
            UPDATE break_stats 
            SET eye_care_count = eye_care_count + 1,
                total_responses = total_responses + 1
            WHERE date = ?
        ''', (date_str,))
    elif break_type == 'break_reminder':
        cursor.execute('''
            UPDATE break_stats 
            SET break_reminder_count = break_reminder_count + 1,
                total_responses = total_responses + 1
            WHERE date = ?
        ''', (date_str,))
    
    # Calculate average productivity score using indexed query
    cursor.execute('''
        SELECT AVG(
            CASE answer_id
                WHEN 1 THEN 10
                WHEN 2 THEN 6
                WHEN 3 THEN 2
                WHEN 4 THEN 0
                ELSE 0
            END
        ) as avg_score
        FROM break_responses
        WHERE date = ? AND question_id = 1
    ''', (date_str,))
    
    result = cursor.fetchone()
    if result and result[0] is not None:
        cursor.execute('''
            UPDATE break_stats 
            SET avg_productivity_score = ?
            WHERE date = ?
        ''', (result[0], date_str))


def get_question_by_id(question_id):
    """Get question details by ID"""
    questions_data = load_questions()
    if not questions_data:
        return None
    
    for question in questions_data['questions']:
        if question['id'] == question_id:
            return question
    return None


def get_answer_by_id(question_id, answer_id):
    """Get answer details by ID"""
    question = get_question_by_id(question_id)
    if not question:
        return None
    
    for answer in question['answers']:
        if answer['id'] == answer_id:
            return answer
    return None


if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage: save-break-response.py <break_type> <duration> <question_id> <answer_id> [answer_text]", file=sys.stderr)
        sys.exit(1)
    
    break_type = sys.argv[1]
    duration = int(sys.argv[2])
    question_id = int(sys.argv[3])
    answer_id = int(sys.argv[4])
    
    # Use provided answer text or get from questions.json
    if len(sys.argv) > 5:
        answer_text = sys.argv[5]
    else:
        answer = get_answer_by_id(question_id, answer_id)
        answer_text = answer['text'] if answer else f"Answer {answer_id}"
    
    success = save_response(break_type, duration, question_id, answer_id, answer_text)
    sys.exit(0 if success else 1)
