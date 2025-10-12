#!/usr/bin/env python3
"""
Event Traffic Simulator
Generates realistic analytics events to populate the dashboard
"""

import requests
import random
import time
import uuid
from datetime import datetime

API_URL = "http://localhost:8000"

# Sample data
COUNTRIES = ["United States", "United Kingdom", "Canada", "Germany", "France", "Japan", "Australia", "India", "Brazil", "Spain"]
PAGES = ["/", "/products", "/about", "/contact", "/pricing", "/blog", "/features", "/demo", "/docs", "/login"]
EVENT_TYPES = ["pageview", "click", "scroll", "engagement", "conversion"]

# Generate some consistent user IDs and session IDs
USERS = [f"user_{i}" for i in range(1, 51)]
SESSIONS = {}

def get_or_create_session(user_id):
    """Get existing session or create new one for user"""
    if user_id not in SESSIONS or random.random() < 0.3:  # 30% chance of new session
        SESSIONS[user_id] = f"session_{uuid.uuid4().hex[:8]}"
    return SESSIONS[user_id]

def generate_event():
    """Generate a random analytics event"""
    user_id = random.choice(USERS)
    session_id = get_or_create_session(user_id)

    # Weight event types (more pageviews than conversions)
    event_type = random.choices(
        EVENT_TYPES,
        weights=[50, 25, 15, 8, 2],  # Pageviews are most common
        k=1
    )[0]

    event = {
        "event_type": event_type,
        "user_id": user_id,
        "session_id": session_id,
        "page_url": random.choice(PAGES),
        "country": random.choice(COUNTRIES),
        "properties": {
            "app_name": "traffic_simulator",
            "app_version": "1.0.0",
            "domain": "simulator.local",
            "timestamp": datetime.utcnow().isoformat(),
            "user_agent": "Mozilla/5.0 (Analytics Simulator)"
        }
    }

    return event

def send_event(event):
    """Send event to the analytics API"""
    try:
        response = requests.post(f"{API_URL}/api/events", json=event, timeout=5)
        if response.status_code == 200:
            print(f"✓ Sent {event['event_type']} event for {event['user_id']} - {event['country']}")
        else:
            print(f"✗ Failed to send event: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"✗ Error sending event: {e}")

def simulate_continuous_traffic(events_per_minute=10, duration_minutes=None):
    """
    Simulate continuous traffic

    Args:
        events_per_minute: Number of events to generate per minute
        duration_minutes: How long to run (None = infinite)
    """
    print(f"Starting traffic simulation...")
    print(f"Events per minute: {events_per_minute}")
    print(f"Duration: {'Infinite' if duration_minutes is None else f'{duration_minutes} minutes'}")
    print(f"Target API: {API_URL}")
    print("-" * 60)

    start_time = time.time()
    event_count = 0
    delay = 60.0 / events_per_minute  # Delay between events

    try:
        while True:
            if duration_minutes and (time.time() - start_time) > (duration_minutes * 60):
                break

            event = generate_event()
            send_event(event)
            event_count += 1

            time.sleep(delay)

    except KeyboardInterrupt:
        print("\n" + "-" * 60)
        print("Simulation stopped by user")

    elapsed = time.time() - start_time
    print(f"\nTotal events sent: {event_count}")
    print(f"Duration: {elapsed:.1f} seconds")
    print(f"Average rate: {event_count / (elapsed / 60):.1f} events/minute")

def simulate_burst(num_events=100):
    """
    Send a burst of events quickly

    Args:
        num_events: Number of events to send
    """
    print(f"Sending burst of {num_events} events...")
    print("-" * 60)

    for i in range(num_events):
        event = generate_event()
        send_event(event)
        time.sleep(0.1)  # Small delay to avoid overwhelming the server

    print(f"\nBurst complete! Sent {num_events} events.")

if __name__ == "__main__":
    import sys

    print("Analytics Traffic Simulator")
    print("=" * 60)
    print()
    print("Options:")
    print("  1. Continuous traffic (default: 10 events/min)")
    print("  2. Burst mode (send 100 events quickly)")
    print("  3. Custom continuous (specify events/min)")
    print()

    choice = input("Select mode (1/2/3) [1]: ").strip() or "1"

    if choice == "1":
        simulate_continuous_traffic(events_per_minute=10)
    elif choice == "2":
        simulate_burst(num_events=100)
    elif choice == "3":
        try:
            rate = int(input("Events per minute: "))
            duration = input("Duration in minutes (leave empty for infinite): ").strip()
            duration = int(duration) if duration else None
            simulate_continuous_traffic(events_per_minute=rate, duration_minutes=duration)
        except ValueError:
            print("Invalid input. Using defaults.")
            simulate_continuous_traffic(events_per_minute=10)
    else:
        print("Invalid choice. Exiting.")
