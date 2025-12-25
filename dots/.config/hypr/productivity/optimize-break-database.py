#!/usr/bin/env python3
"""
Optimize Break Enforcer Database Schema
- Removes redundant data storage
- Adds proper indexes for performance
- Adds constraints for data integrity
- Migrates existing data to optimized schema
"""

import sqlite3
import sys
from datetime import datetime
from pathlib import Path

# Configuration
HOME = Path.home()
DATA_DIR = HOME / ".local" / "share" / "digital-wellbeing"
DB_PATH = DATA_DIR / "usage.db"
BACKUP_PATH = DATA_DIR / f"usage.db.backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"


def backup_database():
    """Create a backup before optimization"""
    import shutil
    if DB_PATH.exists():
        shutil.copy2(DB_PATH, BACKUP_PATH)
        print(f"✓ Backup created: {BACKUP_PATH}")
        return True
    return False


def optimize_schema(conn):
    """Optimize database schema for better performance and storage"""
    cursor = conn.cursor()
    
    print("\n📊 Optimizing database schema...")
    
    # 1. Create optimized break_responses table
    print("  • Creating optimized break_responses table...")
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS break_responses_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TIMESTAMP NOT NULL,
            break_type TEXT NOT NULL CHECK(break_type IN ('eye_care', 'break_reminder')),
            duration INTEGER NOT NULL CHECK(duration > 0),
            question_id INTEGER NOT NULL,
            answer_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            UNIQUE(timestamp, question_id)
        )
    ''')
    
    # 2. Migrate existing data (remove answer_value redundancy)
    print("  • Migrating existing responses...")
    cursor.execute('''
        INSERT INTO break_responses_new 
        (id, timestamp, break_type, duration, question_id, answer_id, date)
        SELECT id, timestamp, break_type, duration, question_id, 
               COALESCE(answer_id, 0), date
        FROM break_responses
    ''')
    
    # Drop view before altering table
    cursor.execute('DROP VIEW IF EXISTS break_analytics')
    
    # 3. Drop old table and rename new one
    cursor.execute('DROP TABLE break_responses')
    cursor.execute('ALTER TABLE break_responses_new RENAME TO break_responses')
    
    # 4. Add performance indexes
    print("  • Adding indexes for performance...")
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_break_responses_date 
        ON break_responses(date)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_break_responses_type 
        ON break_responses(break_type)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_break_responses_question 
        ON break_responses(question_id)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_break_responses_timestamp 
        ON break_responses(timestamp DESC)
    ''')
    
    # 5. Optimize break_stats table
    print("  • Optimizing break_stats table...")
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS break_stats_new (
            date TEXT PRIMARY KEY,
            eye_care_count INTEGER DEFAULT 0 CHECK(eye_care_count >= 0),
            break_reminder_count INTEGER DEFAULT 0 CHECK(break_reminder_count >= 0),
            total_responses INTEGER DEFAULT 0 CHECK(total_responses >= 0),
            avg_productivity_score REAL DEFAULT 0 CHECK(avg_productivity_score >= 0 AND avg_productivity_score <= 10),
            compliance_rate REAL DEFAULT 0 CHECK(compliance_rate >= 0 AND compliance_rate <= 1)
        )
    ''')
    
    # Migrate existing stats (add total_responses column)
    cursor.execute('''
        INSERT INTO break_stats_new 
        (date, eye_care_count, break_reminder_count, total_responses, avg_productivity_score, compliance_rate)
        SELECT 
            date, 
            eye_care_count, 
            break_reminder_count,
            eye_care_count + break_reminder_count as total_responses,
            avg_productivity_score, 
            compliance_rate
        FROM break_stats
    ''')
    
    cursor.execute('DROP TABLE break_stats')
    cursor.execute('ALTER TABLE break_stats_new RENAME TO break_stats')
    
    # 6. Create materialized view for quick stats queries
    print("  • Creating optimized queries...")
    cursor.execute('''
        CREATE VIEW IF NOT EXISTS break_analytics AS
        SELECT 
            date,
            break_type,
            COUNT(*) as response_count,
            COUNT(DISTINCT question_id) as questions_answered,
            AVG(CASE question_id 
                WHEN 1 THEN CASE answer_id
                    WHEN 1 THEN 10
                    WHEN 2 THEN 6
                    WHEN 3 THEN 2
                    WHEN 4 THEN 0
                    ELSE 0
                END
                ELSE NULL
            END) as productivity_score
        FROM break_responses
        GROUP BY date, break_type
    ''')
    
    conn.commit()
    print("✓ Schema optimization complete!")


def clean_test_data(conn, dry_run=False):
    """Remove test data from the database"""
    cursor = conn.cursor()
    
    print("\n🧹 Cleaning test data...")
    
    # Find test data
    cursor.execute('''
        SELECT COUNT(*) FROM break_responses 
        WHERE date = ?
    ''', (datetime.now().strftime('%Y-%m-%d'),))
    
    count = cursor.fetchone()[0]
    
    if count == 0:
        print("  • No test data found")
        return
    
    print(f"  • Found {count} test responses from today")
    
    if dry_run:
        print("  • DRY RUN: Would delete these responses")
        cursor.execute('''
            SELECT id, timestamp, break_type, question_id, answer_id 
            FROM break_responses 
            WHERE date = ?
            ORDER BY timestamp DESC
            LIMIT 10
        ''', (datetime.now().strftime('%Y-%m-%d'),))
        
        for row in cursor.fetchall():
            print(f"    - ID {row[0]}: {row[1]} | {row[2]} | Q{row[3]} A{row[4]}")
    else:
        # Delete test responses
        cursor.execute('''
            DELETE FROM break_responses 
            WHERE date = ?
        ''', (datetime.now().strftime('%Y-%m-%d'),))
        
        # Delete test stats
        cursor.execute('''
            DELETE FROM break_stats 
            WHERE date = ?
        ''', (datetime.now().strftime('%Y-%m-%d'),))
        
        conn.commit()
        print(f"✓ Deleted {count} test responses")


def analyze_storage(conn):
    """Show storage statistics"""
    cursor = conn.cursor()
    
    print("\n📈 Storage Analysis:")
    
    # Get table sizes
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    
    total_size = 0
    for table in tables:
        table_name = table[0]
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        
        # Get page count (approximate size)
        cursor.execute(f"SELECT SUM(pgsize) FROM dbstat WHERE name='{table_name}'")
        result = cursor.fetchone()
        size = result[0] if result[0] else 0
        total_size += size
        
        print(f"  • {table_name}: {count} rows (~{size/1024:.2f} KB)")
    
    print(f"  • Total DB size: ~{total_size/1024:.2f} KB")
    
    # Show indexes
    cursor.execute("""
        SELECT name, tbl_name FROM sqlite_master 
        WHERE type='index' AND name LIKE 'idx_%'
    """)
    indexes = cursor.fetchall()
    
    print(f"\n📑 Indexes ({len(indexes)}):")
    for idx in indexes:
        print(f"  • {idx[0]} on {idx[1]}")


def verify_data_integrity(conn):
    """Verify data integrity after optimization"""
    cursor = conn.cursor()
    
    print("\n✅ Verifying data integrity...")
    
    # Check for orphaned data
    cursor.execute('''
        SELECT COUNT(*) FROM break_responses
        WHERE answer_id IS NULL OR answer_id = 0
    ''')
    orphaned = cursor.fetchone()[0]
    
    if orphaned > 0:
        print(f"  ⚠️  Warning: {orphaned} responses with missing answer_id")
    else:
        print("  ✓ No orphaned responses")
    
    # Check date consistency
    cursor.execute('''
        SELECT COUNT(*) FROM break_responses
        WHERE date != date(timestamp)
    ''')
    inconsistent = cursor.fetchone()[0]
    
    if inconsistent > 0:
        print(f"  ⚠️  Warning: {inconsistent} responses with inconsistent dates")
    else:
        print("  ✓ Date consistency verified")
    
    # Check stats vs responses
    cursor.execute('''
        SELECT 
            br.date,
            COUNT(*) as responses,
            bs.total_responses
        FROM break_responses br
        LEFT JOIN break_stats bs ON br.date = bs.date
        GROUP BY br.date
        HAVING responses != COALESCE(bs.total_responses, 0)
    ''')
    
    mismatches = cursor.fetchall()
    if mismatches:
        print(f"  ⚠️  Warning: Stats mismatch on {len(mismatches)} dates")
    else:
        print("  ✓ Stats match response counts")


def main():
    """Main optimization routine"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Optimize Break Enforcer Database')
    parser.add_argument('--clean', action='store_true', help='Clean test data')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be deleted without deleting')
    parser.add_argument('--analyze', action='store_true', help='Analyze storage only')
    parser.add_argument('--no-backup', action='store_true', help='Skip backup creation')
    
    args = parser.parse_args()
    
    if not DB_PATH.exists():
        print(f"❌ Database not found: {DB_PATH}")
        sys.exit(1)
    
    # Create backup unless disabled
    if not args.no_backup:
        backup_database()
    
    # Connect to database
    conn = sqlite3.connect(DB_PATH)
    
    try:
        if args.analyze:
            analyze_storage(conn)
        else:
            # Run optimization
            optimize_schema(conn)
            
            if args.clean:
                clean_test_data(conn, dry_run=args.dry_run)
            
            verify_data_integrity(conn)
            analyze_storage(conn)
            
            print("\n✅ Database optimization complete!")
            print(f"\nBackup saved to: {BACKUP_PATH}")
            
    except Exception as e:
        print(f"\n❌ Error during optimization: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn.close()


if __name__ == '__main__':
    main()
