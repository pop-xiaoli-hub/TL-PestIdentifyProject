"""Run with: python3 -m unittest discover -s scripts -p 'test_*.py'."""
import contextlib
import http.client
import json
from pathlib import Path
import select
import subprocess
import sys
import time
import unittest

SCRIPT = Path(__file__).with_name("ai_sse_server.py")


@contextlib.contextmanager
def running_server(scenario="normal", speed="fast"):
    process = subprocess.Popen(
        [sys.executable, "-u", str(SCRIPT), "--port", "0", "--scenario", scenario, "--speed", speed],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    try:
        ready, _, _ = select.select([process.stdout], [], [], 5)
        line = process.stdout.readline() if ready else ""
        if not line.startswith("READY "):
            process.terminate()
            _, stderr = process.communicate(timeout=5)
            raise AssertionError(f"SSE service did not start: {line} {stderr}")
        port = int(line.split()[1].split(":")[-1].split("/")[0])
        yield process, port
    finally:
        if process.poll() is None:
            process.stdin.write("quit\n")
            process.stdin.flush()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        for stream in (process.stdin, process.stdout, process.stderr):
            stream.close()


def connect(port, text="arbitrary question", headers=None):
    connection = http.client.HTTPConnection("127.0.0.1", port, timeout=8)
    body = json.dumps({"text": text, "useSingleModel": True, "saveHistory": False})
    connection.request("POST", "/api/v1/agent/chat/stream", body,
                       {"Content-Type": "application/json", **(headers or {})})
    return connection, connection.getresponse()


def frames(raw):
    result = []
    for frame in raw.decode("utf-8").replace("\r\n", "\n").split("\n\n"):
        event, values = "message", []
        for line in frame.split("\n"):
            if line.startswith("event:"):
                event = line[6:].strip()
            if line.startswith("data:"):
                values.append(line[5:].removeprefix(" "))
        if values:
            result.append((event, "\n".join(values)))
    return result


class SSEServiceTests(unittest.TestCase):
    def test_success_is_input_independent_and_final_snapshot_matches_deltas(self):
        with running_server() as (_, port):
            answers = []
            for question in ("first private question", "another unrelated question"):
                connection, response = connect(port, question)
                self.assertEqual(response.status, 200)
                events = frames(response.read())
                connection.close()
                self.assertEqual(events[0][0], "meta")
                self.assertEqual(events[-1][0], "done")
                text = "".join(json.loads(data)["text"] for event, data in events if event == "plan_delta")
                final = next(json.loads(data)["controlPlan"] for event, data in events if event == "plan")
                self.assertEqual(final, text)
                self.assertEqual(text.count("TLW_STREAM_END_2026"), 1)
                self.assertNotIn(question, text)
                answers.append(text)
            self.assertEqual(answers[0], answers[1])

    def test_split_packets_recover_same_unicode_and_terminal_sequence(self):
        answers = []
        for scenario in ("normal", "split"):
            with running_server(scenario) as (_, port):
                connection, response = connect(port)
                events = frames(response.read())
                connection.close()
                self.assertEqual(events[-1][0], "done")
                answer = "".join(json.loads(data)["text"] for event, data in events if event == "plan_delta")
                self.assertIn("👨‍👩‍👧‍👦", answer)
                self.assertIn("e\u0301", answer)
                answers.append(answer)
        self.assertEqual(answers[0], answers[1])

    def test_error_and_eof_never_emit_success_or_final_snapshot(self):
        for scenario, expected_error in (("error", True), ("eof", False)):
            with self.subTest(scenario=scenario), running_server(scenario) as (_, port):
                connection, response = connect(port)
                events = frames(response.read())
                connection.close()
                names = [name for name, _ in events]
                self.assertIn("plan_delta", names)
                self.assertEqual("error" in names, expected_error)
                self.assertNotIn("done", names)
                self.assertNotIn("plan", names)

    def test_terminal_pause_sends_only_heartbeats_until_completed(self):
        with running_server(speed="slow") as (process, port):
            connection, response = connect(port)
            prefix = bytearray()
            while b"event: plan_delta" not in prefix:
                line = response.readline()
                self.assertTrue(line, "stream ended before its first delta")
                prefix.extend(line)
            process.stdin.write("pause\n")
            process.stdin.flush()
            while True:
                line = response.readline()
                self.assertTrue(line, "stream ended before pause took effect")
                prefix.extend(line)
                if line.startswith(b": paused"):
                    prefix.extend(response.readline())
                    break
            self.assertEqual(response.readline(), b": paused\n")
            self.assertEqual(response.readline(), b"\n")
            process.stdin.write("done\n")
            process.stdin.flush()
            events = frames(bytes(prefix) + response.read())
            connection.close()
            text = "".join(json.loads(data)["text"] for name, data in events if name == "plan_delta")
            final = next(json.loads(data)["controlPlan"] for name, data in events if name == "plan")
            self.assertEqual(final, text)
            self.assertEqual(events[-1][0], "done")
            self.assertNotIn("TLW_STREAM_END_2026", text)

    def test_paused_stream_can_resume_or_finish_or_fail_or_disconnect_from_terminal(self):
        for command in ("resume", "done", "error", "disconnect"):
            with self.subTest(command=command), running_server("hold") as (process, port):
                connection, response = connect(port)
                prefix = bytearray()
                while True:
                    line = response.readline()
                    self.assertTrue(line, "connection closed before the pause boundary")
                    prefix.extend(line)
                    if line.startswith(b": paused"):
                        response.readline()
                        break
                process.stdin.write(command + "\n")
                process.stdin.flush()
                events = frames(bytes(prefix) + response.read())
                connection.close()
                names = [name for name, _ in events]
                self.assertEqual("done" in names, command in ("done", "resume"))
                self.assertEqual("error" in names, command == "error")
                if command in ("done", "resume"):
                    text = "".join(json.loads(data)["text"] for event, data in events if event == "plan_delta")
                    final = next(json.loads(data)["controlPlan"] for event, data in events if event == "plan")
                    self.assertEqual(final, text)
                    self.assertEqual("TLW_STREAM_END_2026" in text, command == "resume")

    def test_credentials_are_rejected_without_echoing_them(self):
        with running_server() as (_, port):
            connection, response = connect(port, headers={"Authorization": "Bearer do-not-echo-this", "Cookie": "session=do-not-echo-this"})
            self.assertEqual(response.status, 403)
            body = response.read().decode()
            self.assertNotIn("do-not-echo-this", body)
            self.assertEqual(json.loads(body)["code"], "credentials_not_allowed")
            connection.close()

    def test_client_cancel_releases_stream_before_next_request(self):
        with running_server("hold") as (_, port):
            connection, response = connect(port)
            while True:
                line = response.readline()
                self.assertTrue(line, "stream closed before the cancellation boundary")
                if line.startswith(b": paused"):
                    break
            response.close()
            connection.close()
            deadline = time.monotonic() + 5
            while True:
                health = http.client.HTTPConnection("127.0.0.1", port, timeout=2)
                health.request("GET", "/health")
                active = json.loads(health.getresponse().read())["activeStreams"]
                health.close()
                if active == 0 or time.monotonic() >= deadline:
                    break
                time.sleep(0.05)
            self.assertEqual(active, 0)


def job_request(port, method, path, payload=None, headers=None):
    connection = http.client.HTTPConnection("127.0.0.1", port, timeout=8)
    body = json.dumps(payload) if payload is not None else None
    connection.request(method, path, body,
                       {"Content-Type": "application/json", **(headers or {})})
    response = connection.getresponse()
    status, raw = response.status, response.read()
    connection.close()
    return status, raw


def job_frames(raw):
    events = []
    for block in raw.decode("utf-8").replace("\r\n", "\n").split("\n\n"):
        event_id, name, data = "", "", []
        for line in block.splitlines():
            if line.startswith("id:"):
                event_id = line[3:].strip()
            elif line.startswith("event:"):
                name = line[6:].strip()
            elif line.startswith("data:"):
                data.append(line[5:].removeprefix(" "))
        if data:
            events.append((event_id, name, json.loads("\n".join(data))))
    return events


class RecoverableJobServiceTests(unittest.TestCase):
    key = "00000000-0000-4000-8000-000000000001"
    payload = {"text": "controlled fixture", "useSingleModel": True, "saveHistory": False}

    def create_job(self, port):
        status, raw = job_request(port, "POST", "/api/v1/agent/jobs", self.payload,
                                  {"Idempotency-Key": self.key})
        self.assertEqual(status, 201, raw)
        return json.loads(raw)

    def test_repeated_create_cannot_start_another_generation(self):
        with running_server() as (_, port):
            created = self.create_job(port)
            status, raw = job_request(port, "POST", "/api/v1/agent/jobs", self.payload,
                                      {"Idempotency-Key": self.key})
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(raw)["jobId"], created["jobId"])
            status, raw = job_request(port, "GET", "/health")
            self.assertEqual(json.loads(raw)["createdJobs"], 1)

    def test_same_key_with_changed_input_is_rejected_without_another_job(self):
        with running_server() as (_, port):
            self.create_job(port)
            status, raw = job_request(port, "POST", "/api/v1/agent/jobs",
                                      {**self.payload, "text": "different input"},
                                      {"Idempotency-Key": self.key})
            self.assertEqual(status, 409)
            status, raw = job_request(port, "GET", "/health")
            self.assertEqual(json.loads(raw)["createdJobs"], 1)

    def test_resume_cursor_replays_exact_missing_suffix_and_complete_tail_once(self):
        with running_server() as (_, port):
            created = self.create_job(port)
            route = f'/api/v1/agent/jobs/{created["jobId"]}/events'
            status, raw = job_request(port, "GET", route)
            self.assertEqual(status, 200)
            original = job_frames(raw)
            text = "".join(data["payload"]["text"] for _, name, data in original
                           if name == "plan_delta")
            self.assertEqual(text.count("TLW_STREAM_END_2026"), 1)
            self.assertEqual(original[-1][1], "done")
            status, raw = job_request(port, "GET", route,
                                      headers={"Last-Event-ID": original[4][0]})
            self.assertEqual(status, 200)
            self.assertEqual(job_frames(raw), original[5:])

    def test_cancel_before_create_ack_prevents_late_task_creation(self):
        with running_server() as (_, port):
            status, raw = job_request(port, "POST", "/api/v1/agent/jobs/cancel",
                                      {"clientRequestId": self.key})
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(raw)["status"], "cancelled")
            status, raw = job_request(port, "POST", "/api/v1/agent/jobs", self.payload,
                                      {"Idempotency-Key": self.key})
            self.assertEqual(status, 409)
            status, raw = job_request(port, "GET", "/health")
            self.assertEqual(json.loads(raw)["createdJobs"], 0)

    def test_restarted_unknown_creation_can_lookup_without_another_job(self):
        with running_server() as (_, port):
            created = self.create_job(port)
            status, raw = job_request(port, "GET", f"/api/v1/agent/jobs/by-client-request/{self.key}")
            self.assertEqual(status, 200, raw)
            found = json.loads(raw)
            self.assertEqual(found["jobId"], created["jobId"])
            self.assertEqual(found["clientRequestId"], self.key)
            self.assertEqual(found["protocol"], "stream-job.v1")
            status, raw = job_request(port, "GET", "/api/v1/agent/jobs/by-client-request/missing-request")
            self.assertEqual(status, 404, raw)
            status, raw = job_request(port, "GET", "/health")
            self.assertEqual(json.loads(raw)["createdJobs"], 1)


if __name__ == "__main__":
    unittest.main()
