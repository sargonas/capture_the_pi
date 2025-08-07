#!/bin/bash

# MODULE 4: Create CTF Scorer

echo "[Module 4] Creating CTF scorer..."

cat > /home/pi/honeypot_ctf/ctf_scorer.py << 'SCORER_EOF'
#!/usr/bin/env python3
import sqlite3
import json
import time
import threading
from pathlib import Path
from flask import Flask, render_template_string
import re
from datetime import datetime

class HoneypotCTF:
    def __init__(self):
        self.db_path = "/var/lib/honeypot_ctf/scores.db"
        self.log_path = "/var/tmp/opencanary.log"
        self.setup_database()
        self.scoring_rules = {
            "port_scan_detected": 10,
            "service_probe": 20,
            "ssh_login_attempt": 30,
            "http_request": 25,
            "ftp_login_attempt": 35,
            "telnet_login_attempt": 40,
            "mysql_connection": 45,
            "redis_connection": 50,
            "first_blood": 200,
            "persistence": 150,
        }
        self.flags = {
            # Easy flags
            "FLAG{welcome_to_honeypot}": 100,
            "FLAG{web_explorer}": 150,
            "FLAG{config_hunter}": 200,
            "FLAG{admin_access}": 150,
            "FLAG{hidden_discovery}": 200,
            
            # Medium flags  
            "FLAG{source_code_reviewer}": 250,
            "FLAG{backup_file_exposed}": 300,
            "FLAG{api_enumeration}": 350,
            "FLAG{log_file_leakage}": 400,
            "FLAG{directory_listing}": 300,
            "FLAG{temp_file_exposure}": 350,
            
            # Hard flags
            "FLAG{git_exposure}": 500,
            "FLAG{git_history_leak}": 600,
            "FLAG{environment_variables}": 550,
            "FLAG{xml_parsing}": 600,
            "FLAG{debug_info_disclosure}": 650,
            "FLAG{legacy_code}": 500,
            "FLAG{test_environment}": 550,
            
            # Expert flags
            "FLAG{jwt_secret_exposed}": 800,
            "FLAG{sql_dump_analysis}": 900,
            "FLAG{encryption_key_exposure}": 850,
            "FLAG{docker_secrets}": 900,
            "FLAG{kubernetes_config}": 950,
            
            # Ninja flags
            "FLAG{steganography}": 1200,
            "FLAG{reverse_engineering}": 1500,
        }
        
    def setup_database(self):
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute('''CREATE TABLE IF NOT EXISTS players (
            id INTEGER PRIMARY KEY,
            username TEXT UNIQUE,
            ip_address TEXT,
            total_score INTEGER DEFAULT 0,
            first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY,
            player_id INTEGER,
            event_type TEXT,
            points INTEGER,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            details TEXT,
            FOREIGN KEY (player_id) REFERENCES players (id)
        )''')
        
        conn.commit()
        conn.close()
    
    def get_or_create_player(self, ip_address):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        username = f"player_{ip_address.replace('.', '_')}"
        
        c.execute("SELECT id FROM players WHERE ip_address = ?", (ip_address,))
        player = c.fetchone()
        
        if not player:
            c.execute("INSERT INTO players (username, ip_address) VALUES (?, ?)", 
                     (username, ip_address))
            player_id = c.lastrowid
        else:
            player_id = player[0]
            c.execute("UPDATE players SET last_activity = CURRENT_TIMESTAMP WHERE id = ?", 
                     (player_id,))
        
        conn.commit()
        conn.close()
        return player_id
    
    def award_points(self, player_id, event_type, points, details=""):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        
        c.execute("INSERT INTO events (player_id, event_type, points, details) VALUES (?, ?, ?, ?)",
                 (player_id, event_type, points, details))
        
        c.execute("UPDATE players SET total_score = total_score + ? WHERE id = ?",
                 (points, player_id))
        
        conn.commit()
        conn.close()
    
    def process_log_entry(self, log_line):
        try:
            data = json.loads(log_line)
            src_ip = data.get('src_host', '127.0.0.1')
            
            if src_ip in ['127.0.0.1', '::1']:
                return
                
            player_id = self.get_or_create_player(src_ip)
            event_type = data.get('logtype', 'unknown')
            
            points = self.scoring_rules.get(event_type, 5)
            details = json.dumps(data)
            
            self.award_points(player_id, event_type, points, details)
            print(f"Awarded {points} points to {src_ip} for {event_type}")
            
        except Exception as e:
            print(f"Error processing log: {e}")
    
    def get_leaderboard(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("SELECT username, total_score FROM players ORDER BY total_score DESC LIMIT 10")
        results = c.fetchall()
        conn.close()
        return results
    
    def get_recent_events(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('''SELECT p.username, e.event_type, e.points, e.timestamp 
                    FROM events e JOIN players p ON e.player_id = p.id 
                    ORDER BY e.timestamp DESC LIMIT 20''')
        results = c.fetchall()
        conn.close()
        return results

app = Flask(__name__)
ctf = HoneypotCTF()

SCOREBOARD_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Honeypot CTF Scoreboard</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: 'Courier New', monospace; background: #000; color: #0f0; margin: 0; padding: 20px; }
        h1 { text-align: center; color: #ff0; text-shadow: 0 0 10px #ff0; }
        .container { max-width: 1200px; margin: 0 auto; }
        .section { margin: 30px 0; padding: 20px; border: 1px solid #0f0; background: #001100; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #0f0; }
        th { background: #002200; color: #ff0; }
        .rank-1 { color: #ffd700; }
        .rank-2 { color: #c0c0c0; }
        .rank-3 { color: #cd7f32; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🍯 HONEYPOT CTF SCOREBOARD 🍯</h1>
        
        <div class="section">
            <h2>🏆 LEADERBOARD</h2>
            <table>
                <tr><th>Rank</th><th>Player</th><th>Score</th></tr>
                {% for i, (username, score) in enumerate(leaderboard) %}
                <tr class="rank-{{ i+1 if i < 3 else 'other' }}">
                    <td>{{ i+1 }}</td>
                    <td>{{ username }}</td>
                    <td>{{ score }}</td>
                </tr>
                {% endfor %}
            </table>
        </div>
        
        <div class="section">
            <h2>📊 RECENT ACTIVITY</h2>
            <table>
                <tr><th>Player</th><th>Action</th><th>Points</th><th>Time</th></tr>
                {% for username, event_type, points, timestamp in recent_events %}
                <tr>
                    <td>{{ username }}</td>
                    <td>{{ event_type }}</td>
                    <td>+{{ points }}</td>
                    <td>{{ timestamp }}</td>
                </tr>
                {% endfor %}
            </table>
        </div>
        
        <div class="section">
            <h2>🎯 AVAILABLE FLAGS</h2>
            <ul>
                <li>25 flags total ranging from 100-1500 points each</li>
                <li>Easy flags: robots.txt, HTML comments, config files</li>
                <li>Medium flags: backup files, APIs, log files</li>
                <li>Hard flags: Git exposure, environment files, XML parsing</li>
                <li>Expert flags: JWT secrets, SQL dumps, encryption keys</li>
                <li>Ninja flags: Steganography and reverse engineering</li>
            </ul>
        </div>
    </div>
</body>
</html>
'''

@app.route('/')
def scoreboard():
    leaderboard = ctf.get_leaderboard()
    recent_events = ctf.get_recent_events()
    return render_template_string(SCOREBOARD_TEMPLATE, 
                                leaderboard=leaderboard,
                                recent_events=recent_events)

def monitor_logs():
    Path(ctf.log_path).touch(exist_ok=True)
    with open(ctf.log_path, 'r') as f:
        f.seek(0, 2)
        while True:
            line = f.readline()
            if line:
                ctf.process_log_entry(line.strip())
            else:
                time.sleep(0.1)

if __name__ == '__main__':
    log_thread = threading.Thread(target=monitor_logs, daemon=True)
    log_thread.start()
    app.run(host='0.0.0.0', port=8080, debug=False)
SCORER_EOF

chmod +x /home/pi/honeypot_ctf/ctf_scorer.py

echo "[Module 4] Scorer created"