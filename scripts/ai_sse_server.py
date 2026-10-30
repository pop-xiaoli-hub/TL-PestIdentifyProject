#!/usr/bin/env python3
"""Local-only SSE fixture service. No model calls, credentials, or request logging."""
import argparse
import itertools
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import socket
import sys
import threading
import uuid
from ai_job_fixture import JobFixtures, JOB_SCENARIOS


INTRO = """# 流式 Markdown 与手势验收

这里是 **跨增量粗体**、*斜体*、`inline_code()`，以及 é、👍🏽、👨‍👩‍👧‍👦、🇨🇳。这些样式在生成过程中就应该出现，不必等整条回复完成。

- 列表一：普通正文自然展开，纵向滑动由外层消息列表负责。
- 列表二：灰色识别卡保留有界内滚，到边界才交给外层。
- 列表三：图片、长代码和宽表格横滑，纵向起手让给列表。

1. 先在生成时点正文，确认键盘能收起。
2. 再向上阅读，确认新内容不会把你拉回底部。

```objc
    CGFloat targetInnerY = oldInnerY - fingerDeltaY;
    NSString *literal = @"**代码里的符号保持原样**";
    this_is_a_long_line_for_horizontal_scrolling_abcdefghijklmnopqrstuvwxyz_abcdefghijklmnopqrstuvwxyz_abcdefghijklmnopqrstuvwxyz
```

| 滚动面 | 操作方向 | 内容中间 | 到达边界 | 新增内容 |
| --- | --- | --- | --- | --- |
| 普通正文 | 上下拖动 | 外层列表滚动 | 外层正常边界 | 不抢阅读位置 |
| 灰色识别卡 | 上下拖动 | 内层优先 | 剩余位移交给外层 | 不强行追底 |
| 代码和表格 | 左右拖动 | 局部横滑 | 不重复加速 | 已闭合块保持位置 |
| 横向图片条 | 左右拖动 | 查看图片 | 不误触返回 | 不重建图片条 |

> 引用块：保留独立段落和缩进，不要和上下列表挤成一行。

## 操作边界
从灰色识别卡内部起拖时检查边界接力；普通正文没有额外的纵向滚动层。上下拖代码或表格时应滚动聊天列表，左右拖则只移动局部内容。

完成后长按选中文字，检查复制的 emoji、空格与换行；拖动选择手柄时不应误触返回。只有完成态才开放正文选择，生成时仍可正常收起键盘。

长链接：https://example.org/streaming/client/very-long-path/0123456789/abcdefghijklmnopqrstuvwxyz?fixture=gesture

"""
ACTIONS = (
    "从普通正文起拖并停留在中间。正文由外层列表滚动，新增文本不应覆盖用户手势或强制追到底部。",
    "灰色识别卡到顶部后继续下拉，检查剩余位移交给外层。反向拖动时不应突然跳位或出现双倍速度。",
    "灰色识别卡到底部后继续上推，外层可以消费剩余位移。松手后的惯性不能让两个容器重复加速。",
    "从卡片外侧拖动历史列表，识别卡、横向代码和表格各自的阅读位置不应意外变化。",
    "拖动期间让电脑终端发送 done。生成态和完成态都使用相同的自然展开正文，不应在结束时突然解开限高。",
    "先暂停输出，记住这一段，再继续。检查是否重复、漏段、清空正文或意外滚回最底部。",
)
ANSWER = INTRO + "\n\n".join(
    f"### 阅读锚点 {number:02d}\n{ACTIONS[(number - 1) % len(ACTIONS)]}\n"
    "这一段用于扩大可滚动范围：中文、English、👍🏽 与 👨‍👩‍👧‍👦 应保持完整。"
    "请记住段落编号，滑动后确认自己仍在阅读同一段。"
    for number in range(1, 25)
) + "\n\n**最终完整性标记：TLW_STREAM_END_2026**\n"
SPEEDS = {"slow": 0.24, "normal": 0.08, "fast": 0.0}
SCENARIOS = ("normal", "split", "error", "eof", "hold") + JOB_SCENARIOS


def event(name, data, newline="\n"):
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")) if not isinstance(data, str) else data
    lines = [f"event: {name}"] + [f"data: {line}" for line in payload.split("\n")]
    return (newline.join(lines) + newline * 2).encode("utf-8")


class StreamControl:
    def __init__(self):
        self.condition = threading.Condition()
        self.paused = False
        self.terminal = None


class State:
    def __init__(self, scenario, speed):
        self.lock = threading.Lock()
        self.scenario = scenario
        self.speed = speed
        self.active = {}
        self.jobs = JobFixtures(ANSWER, SPEEDS)

    def command(self, command):
        parts = command.strip().split()
        if not parts:
            return
        with self.lock:
            if len(parts) == 2 and parts[0] == "scenario" and parts[1] in SCENARIOS:
                self.scenario = parts[1]
                print(f"SCENARIO {self.scenario} (new requests only)", flush=True)
                return
            if len(parts) == 2 and parts[0] == "speed" and parts[1] in SPEEDS:
                self.speed = parts[1]
                print(f"SPEED {self.speed} (new requests only)", flush=True)
                return
            controls = list(self.active.values())
        if parts[0] == "status":
            jobs = self.jobs.health()
            print(f"STATUS active={len(controls) + jobs['jobStreams']} jobs={jobs['createdJobs']} scenario={self.scenario} speed={self.speed}", flush=True)
        elif command.strip() in ("pause", "resume", "done", "error", "disconnect"):
            self.jobs.command(command.strip())
            for control in controls:
                with control.condition:
                    if command.strip() in ("pause", "resume"):
                        control.paused = command.strip() == "pause"
                    else:
                        control.terminal = command.strip()
                    control.condition.notify_all()
            print(f"CONTROL {command.strip()} active={len(controls)}", flush=True)
        else:
            print("Commands: pause | resume | done | error | disconnect | status | scenario " + "/".join(SCENARIOS) + " | speed slow/normal/fast | quit", flush=True)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *_):
        # Never log URLs, request bodies, cookies, or authorization values.
        pass

    def json_response(self, status, value):
        data = json.dumps(value).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(data)
        self.close_connection = True

    def do_GET(self):
        if self.server.state.jobs.handle(self):
            return
        if self.headers.get("Authorization") is not None or self.headers.get("Cookie") is not None:
            self.json_response(403, {"code": "credentials_not_allowed"})
            return
        if self.path != "/health":
            self.json_response(404, {"code": "not_found"})
            return
        with self.server.state.lock:
            active = len(self.server.state.active)
        jobs = self.server.state.jobs.health()
        active += jobs.pop("jobStreams")
        self.json_response(200, {"service": "tlw-sse-fixture", "activeStreams": active, **jobs})

    def do_POST(self):
        if self.server.state.jobs.handle(self):
            return
        self.connection.settimeout(5)
        if self.path != "/api/v1/agent/chat/stream":
            self.json_response(404, {"code": "not_found"})
            return
        if self.headers.get("Authorization") is not None or self.headers.get("Cookie") is not None:
            self.json_response(403, {"code": "credentials_not_allowed", "message": "Do not send real credentials to the fixture service."})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 65536:
                raise ValueError("body size")
            if not isinstance(json.loads(self.rfile.read(length)), dict):
                raise ValueError("object required")
        except (ValueError, OSError):
            self.json_response(400, {"code": "invalid_json_request"})
            return
        self.close_connection = True
        control = StreamControl()
        identifier = str(uuid.uuid4())
        state = self.server.state
        with state.lock:
            scenario, speed = state.scenario, state.speed
            state.active[identifier] = control
        print(f"START requestId={identifier} scenario={scenario} speed={speed}", flush=True)
        reason = "closed"
        try:
            self.connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "close")
            self.end_headers()
            self.run_stream(control, identifier, scenario, speed)
        except (OSError, TimeoutError):
            reason = "client_disconnected"
        finally:
            with state.lock:
                state.active.pop(identifier, None)
            print(f"CLOSED requestId={identifier} reason={reason}", flush=True)

    def write_wire(self, data, split=False):
        if not split:
            self.wfile.write(data)
            self.wfile.flush()
            return
        offset = 0
        for size in itertools.cycle((1, 2, 7, 13, 64)):
            self.wfile.write(data[offset:offset + size])
            self.wfile.flush()
            offset += size
            if offset >= len(data):
                return

    def gate(self, control):
        while True:
            with control.condition:
                paused, terminal = control.paused, control.terminal
            if terminal or not paused:
                return terminal
            self.write_wire(b": paused\n\n")
            with control.condition:
                control.condition.wait(0.5)

    def finish_stream(self, terminal, text):
        if terminal == "done":
            self.write_wire(event("plan", {"controlPlan": text}) + event("done", {"info": "本地测试完成，不是线上模型回答"}))
        elif terminal == "error":
            self.write_wire(event("error", "本地模拟错误：已收到的正文应保留"))
        # EOF/disconnect intentionally close the connection without plan/done.

    def run_stream(self, control, identifier, scenario, speed):
        split = scenario == "split"
        self.write_wire(event("meta", {"requestId": identifier, "singleModel": True, "hasImage": False, "extraInfoLength": 0, "fixture": True}), split)
        self.write_wire(event("disease", [{"diseaseName": f"识别卡第 {number:02d} 行：灰色卡片内部可上下滑，不应带动正文", "confidence": 80 + number} for number in range(1, 7)]), split)
        pieces = [ANSWER[i:i + 12] for i in range(0, len(ANSWER), 12)]
        emitted = []
        for index in range(0, len(pieces), 3 if split else 1):
            terminal = self.gate(control)
            if terminal:
                self.finish_stream(terminal, "".join(emitted))
                return
            batch = pieces[index:index + (3 if split else 1)]
            newline = "\r\n" if split and index % 2 == 0 else "\n"
            self.write_wire(b"".join(event("plan_delta", {"text": piece}, newline) for piece in batch), split)
            emitted.extend(batch)
            if scenario in ("error", "eof") and len(emitted) >= 40:
                self.finish_stream("error" if scenario == "error" else "disconnect", "".join(emitted))
                return
            if scenario == "hold" and len(emitted) == 50:
                with control.condition:
                    control.paused = True
            with control.condition:
                control.condition.wait(SPEEDS[speed])
        terminal = self.gate(control)
        self.finish_stream(terminal or "done", "".join(emitted))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1", help="use 0.0.0.0 for a trusted LAN iPhone")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--scenario", choices=SCENARIOS, default="normal")
    parser.add_argument("--speed", choices=SPEEDS, default="slow")
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    server.daemon_threads = True
    server.state = State(args.scenario, args.speed)
    address, port = server.server_address[:2]
    print(f"READY http://{address}:{port}/api/v1/agent/chat/stream", flush=True)
    print(f"JOB_PROTOCOL http://{address}:{port}/api/v1/agent/jobs (explicit stream-job.v1 fixtures)", flush=True)
    print("Local fixtures only; request bodies and credentials are never logged. Type help for controls.", flush=True)

    def terminal():
        for line in sys.stdin:
            if line.strip() == "quit":
                server.state.command("disconnect")
                server.shutdown()
                return
            server.state.command(line)

    threading.Thread(target=terminal, daemon=True).start()
    try:
        server.serve_forever(poll_interval=0.1)
    except KeyboardInterrupt:
        pass
    finally:
        server.state.command("disconnect")
        server.server_close()


if __name__ == "__main__":
    main()
