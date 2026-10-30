"""Local stream-job.v1 fixture. No model, authentication, payload or credential logging."""
import hashlib
import json
import socket
import threading
import time
import uuid

PREFIX = "/api/v1/agent/jobs"
PROTOCOL = "stream-job.v1"
JOB_SCENARIOS = ("reconnect", "duplicate", "gap", "expired", "lost-ack", "retry-exhausted")


class Job:
    def __init__(self, client_id, payload_hash, answer, scenario, interval):
        self.identifier = str(uuid.uuid4())
        self.client_id = client_id
        self.payload_hash = payload_hash
        self.answer, self.scenario, self.interval = answer, scenario, interval
        self.condition = threading.Condition()
        self.events, self.cursors, self.parts = [], {}, []
        self.meta, self.diseases, self.completion = {}, [], {}
        self.error = ""
        self.status = "running"
        self.paused = False
        self.requested_terminal = None
        self.subscriptions = self.active_streams = self.disconnect_epoch = 0
        self.expired_once = self.ack_dropped = self.faults_disabled = False

    def append(self, name, payload):
        with self.condition:
            if self.status != "running":
                return
            if name == "plan_delta":
                self.parts.append(payload["text"])
            elif name == "plan":
                self.parts = [payload["controlPlan"]]
            elif name == "meta":
                self.meta = payload
            elif name == "disease":
                self.diseases = payload["diseases"]
            elif name == "done":
                self.status, self.completion = "completed", payload
            elif name == "error":
                self.status = "cancelled" if payload.get("code") == "cancelled" else "failed"
                self.error = payload["message"]
            seq = len(self.events) + 1
            cursor = f"{self.identifier}:{seq}"
            body = json.dumps({"jobId": self.identifier, "seq": seq, "payload": payload}, ensure_ascii=False, separators=(",", ":"))
            wire = f"id: {cursor}\nevent: {name}\ndata: {body}\n\n".encode()
            self.events.append((cursor, wire))
            self.cursors[cursor] = seq
            self.condition.notify_all()

    def snapshot(self):
        with self.condition:
            return {"protocol": PROTOCOL, "jobId": self.identifier, "status": self.status,
                    "snapshotSeq": len(self.events), "resumeCursor": self.events[-1][0] if self.events else "",
                    "canonicalMessage": {"text": "".join(self.parts), "diseases": list(self.diseases),
                                         "meta": dict(self.meta), "completionInfo": dict(self.completion),
                                         "fallbackTexts": [], "errorMessage": self.error}}

    def command(self, command):
        with self.condition:
            if command == "disconnect":
                self.disconnect_epoch += 1
            elif command in ("pause", "resume"):
                self.paused = command == "pause"
                if command == "resume":
                    self.faults_disabled = True
            elif command in ("done", "error"):
                self.requested_terminal = command
            self.condition.notify_all()

    def cancel(self):
        self.append("error", {"code": "cancelled", "message": "本地测试任务已取消"})
        return self.snapshot()

    def finish(self, terminal):
        if terminal == "error":
            self.append("error", {"message": "本地模拟任务失败：保留已经收到的正文"})
        else:
            self.append("plan", {"controlPlan": "".join(self.parts)})
            self.append("done", {"info": "本地任务完成，不是线上模型回答"})

    def produce(self):
        self.append("meta", {"requestId": self.identifier, "fixture": True})
        self.append("disease", {"diseases": [{"diseaseName": f"识别卡第 {n:02d} 行：边界接力与重连测试", "confidence": 80 + n} for n in range(1, 7)]})
        pieces = [self.answer[i:i + 12] for i in range(0, len(self.answer), 12)]
        for index, piece in enumerate(pieces):
            with self.condition:
                while self.paused and self.status == "running" and not self.requested_terminal:
                    self.condition.wait()
                if self.status != "running":
                    return
                terminal = self.requested_terminal
            if terminal:
                self.finish(terminal)
                return
            self.append("plan_delta", {"text": piece})
            if self.scenario == "error" and index == 39:
                self.finish("error")
                return
            with self.condition:
                if self.scenario == "hold" and index == 49:
                    self.paused = True
                self.condition.wait(self.interval)
        with self.condition:
            while self.paused and self.status == "running" and not self.requested_terminal:
                self.condition.wait()
            terminal = self.requested_terminal
        self.finish(terminal or "done")


class JobFixtures:
    def __init__(self, answer, speeds):
        self.answer, self.speeds = answer, speeds
        self.lock = threading.Lock()
        self.jobs, self.keys = {}, {}
        self.cancelled_keys = set()

    def command(self, command):
        with self.lock:
            jobs = list(self.jobs.values())
        for job in jobs:
            job.command(command)

    def health(self):
        with self.lock:
            jobs = list(self.jobs.values())
        active = streams = cancelled = 0
        for job in jobs:
            with job.condition:
                active += job.status == "running"
                streams += job.active_streams
                cancelled += job.status == "cancelled"
        return {"createdJobs": len(jobs), "activeJobs": active, "jobStreams": streams, "cancelledJobs": cancelled}

    def create(self, handler):
        try:
            length = int(handler.headers.get("Content-Length", "0"))
            if not 0 < length <= 65536:
                raise ValueError()
            payload = json.loads(handler.rfile.read(length))
            if not isinstance(payload, dict):
                raise ValueError()
        except (ValueError, OSError):
            handler.json_response(400, {"code": "invalid_json_request"})
            return
        key = handler.headers.get("Idempotency-Key", "")
        if not key or len(key) > 128:
            handler.json_response(400, {"code": "missing_idempotency_key"})
            return
        digest = hashlib.sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()
        with handler.server.state.lock:
            scenario, speed = handler.server.state.scenario, handler.server.state.speed
        with self.lock:
            if key in self.cancelled_keys:
                handler.json_response(409, {"code": "request_cancelled"})
                return
            job = self.keys.get(key)
            created = job is None
            if created:
                job = Job(key, digest, self.answer, scenario, self.speeds[speed])
                self.jobs[job.identifier] = self.keys[key] = job
            elif job.payload_hash != digest:
                handler.json_response(409, {"code": "idempotency_conflict"})
                return
        if created:
            threading.Thread(target=job.produce, daemon=True).start()
        with job.condition:
            drop_ack = job.scenario == "lost-ack" and not job.ack_dropped
            if drop_ack:
                job.ack_dropped = True
            response = {"protocol": PROTOCOL, "jobId": job.identifier, "clientRequestId": key, "status": job.status}
        if drop_ack:
            handler.close_connection = True
            handler.connection.shutdown(socket.SHUT_RDWR)
            return
        handler.json_response(201 if created else 200, response)
    def lookup(self, handler, client_id):
        allowed = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        if not client_id or len(client_id) > 128 or any(character not in allowed for character in client_id):
            handler.json_response(400, {"code": "invalid_client_request"})
            return
        with self.lock:
            job = self.keys.get(client_id)
        if job is None:
            handler.json_response(404, {"code": "job_not_found"})
            return
        with job.condition:
            body = {"protocol": PROTOCOL, "jobId": job.identifier, "clientRequestId": client_id, "status": job.status}
        handler.json_response(200, body)

    def handle(self, handler):
        path = handler.path
        if path != PREFIX and not path.startswith(PREFIX + "/"):
            return False
        if handler.headers.get("Authorization") is not None or handler.headers.get("Cookie") is not None:
            handler.json_response(403, {"code": "credentials_not_allowed"})
            return True
        handler.connection.settimeout(5)
        if path == PREFIX and handler.command == "POST":
            self.create(handler)
            return True
        lookup_prefix = PREFIX + "/by-client-request/"
        if path.startswith(lookup_prefix) and handler.command == "GET":
            self.lookup(handler, path[len(lookup_prefix):])
            return True
        if path == PREFIX + "/cancel" and handler.command == "POST":
            try:
                length = int(handler.headers.get("Content-Length", "0"))
                if not 0 < length <= 1024:
                    raise ValueError()
                value = json.loads(handler.rfile.read(length))
                key = value.get("clientRequestId") if isinstance(value, dict) else None
                if not isinstance(key, str) or not key or len(key) > 128:
                    raise ValueError()
            except (ValueError, OSError):
                handler.json_response(400, {"code": "invalid_cancel_request"})
                return True
            with self.lock:
                self.cancelled_keys.add(key)
                job = self.keys.get(key)
            handler.json_response(200, job.cancel() if job else
                                  {"protocol": PROTOCOL, "clientRequestId": key, "status": "cancelled"})
            return True
        components = path[len(PREFIX) + 1:].split("/")
        with self.lock:
            job = self.jobs.get(components[0])
        if not job:
            handler.json_response(404, {"code": "job_not_found"})
        elif len(components) == 1 and handler.command == "GET":
            handler.json_response(200, job.snapshot())
        elif components[1:] == ["cancel"] and handler.command == "POST":
            handler.json_response(200, job.cancel())
        elif components[1:] == ["events"] and handler.command == "GET":
            self.subscribe(handler, job)
        else:
            handler.json_response(404, {"code": "not_found"})
        return True

    def subscribe(self, handler, job):
        cursor = handler.headers.get("Last-Event-ID", "")
        with job.condition:
            expired = cursor and job.scenario == "expired" and not job.expired_once
            if expired:
                job.expired_once = True
            if expired or (cursor and cursor not in job.cursors):
                handler.json_response(410, {"code": "cursor_expired"})
                return
            offset = job.cursors.get(cursor, 0)
            job.subscriptions += 1
            subscription = job.subscriptions
            job.active_streams += 1
            epoch = job.disconnect_epoch
        handler.close_connection = True
        try:
            handler.connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            handler.send_response(200)
            handler.send_header("Content-Type", "text/event-stream; charset=utf-8")
            handler.send_header("Cache-Control", "no-cache")
            handler.send_header("Connection", "close")
            handler.end_headers()
            sent, duplicated = 0, False
            while True:
                with job.condition:
                    if epoch != job.disconnect_epoch:
                        return
                    if not job.faults_disabled and job.scenario == "retry-exhausted" and subscription > 1:
                        return
                    available = list(job.events[offset:])
                    terminal = job.status != "running"
                    if not available and not terminal:
                        job.condition.wait(0.5)
                        available = list(job.events[offset:])
                        terminal = job.status != "running"
                if not available:
                    if terminal:
                        return
                    handler.write_wire(b": job-heartbeat\n\n")
                    continue
                for event_id, wire in available:
                    offset += 1
                    if job.scenario == "gap" and subscription == 1 and offset == 5:
                        continue
                    handler.write_wire(wire, job.scenario == "split")
                    sent += 1
                    if job.scenario == "duplicate" and offset == 12 and not duplicated:
                        handler.write_wire(wire)
                        duplicated = True
                    if not job.faults_disabled and sent >= 30 and (
                            job.scenario == "retry-exhausted" or
                            (job.scenario in ("reconnect", "eof", "expired") and subscription == 1)):
                        return
        except (OSError, TimeoutError):
            pass
        finally:
            with job.condition:
                job.active_streams -= 1
                job.condition.notify_all()
