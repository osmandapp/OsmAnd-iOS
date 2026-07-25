#!/usr/bin/env python3
"""Strict local-only receiver for OsmAnd iOS crash diagnostic fixtures."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import tempfile
import uuid
import zlib
from datetime import datetime
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

MAX_REQUEST_BYTES = 2 * 1024 * 1024
MAX_STRING_LENGTH = 512
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
SAFE_ID_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")
PROHIBITED_KEY_PARTS = {
    "account",
    "coordinate",
    "favorite",
    "filepath",
    "installationid",
    "latitude",
    "longitude",
    "notification",
    "query",
    "regionid",
    "routepoints",
    "search",
    "stackmemory",
    "url",
}
PROHIBITED_STRING_PATTERNS = (
    re.compile(r"https?://", re.IGNORECASE),
    re.compile(r"file://", re.IGNORECASE),
    re.compile(r"(^|[\s\"'])/(?:private|var|users|documents|library|tmp)/", re.IGNORECASE),
)


class ValidationError(ValueError):
    pass


def _object(
    value: Any,
    *,
    required: set[str],
    optional: set[str] = frozenset(),
    name: str,
) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValidationError(f"{name} must be an object")
    keys = set(value)
    missing = required - keys
    unknown = keys - required - optional
    if missing:
        raise ValidationError(f"{name} is missing: {', '.join(sorted(missing))}")
    if unknown:
        raise ValidationError(f"{name} has unknown fields: {', '.join(sorted(unknown))}")
    return value


def _string(value: Any, name: str, *, maximum: int = MAX_STRING_LENGTH) -> str:
    if not isinstance(value, str) or not value or len(value) > maximum:
        raise ValidationError(f"{name} must be a non-empty string up to {maximum} characters")
    for pattern in PROHIBITED_STRING_PATTERNS:
        if pattern.search(value):
            raise ValidationError(f"{name} contains prohibited path or URL data")
    return value


def _integer(value: Any, name: str, *, minimum: int = 0, maximum: int = 2**63 - 1) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or not minimum <= value <= maximum:
        raise ValidationError(f"{name} must be an integer between {minimum} and {maximum}")
    return value


def _boolean(value: Any, name: str) -> bool:
    if not isinstance(value, bool):
        raise ValidationError(f"{name} must be a boolean")
    return value


def _identifier(value: Any, name: str, *, maximum: int = 128) -> str:
    result = _string(value, name, maximum=maximum)
    if not SAFE_ID_PATTERN.fullmatch(result):
        raise ValidationError(f"{name} contains unsupported characters")
    return result


def _timestamp(value: Any, name: str) -> str:
    result = _string(value, name, maximum=32)
    try:
        parsed = datetime.fromisoformat(result.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValidationError(f"{name} must be an ISO-8601 timestamp") from error
    if parsed.tzinfo is None:
        raise ValidationError(f"{name} must include a time zone")
    return result


def _optional_integer(
    value: dict[str, Any],
    key: str,
    name: str,
    *,
    minimum: int = 0,
    maximum: int = 2**63 - 1,
) -> None:
    if key in value:
        _integer(value[key], f"{name}.{key}", minimum=minimum, maximum=maximum)


def _optional_string(
    value: dict[str, Any],
    key: str,
    name: str,
    *,
    identifier: bool = False,
    maximum: int = MAX_STRING_LENGTH,
) -> None:
    if key in value:
        validator = _identifier if identifier else _string
        validator(value[key], f"{name}.{key}", maximum=maximum)


def _validate_numeric_metadata(value: Any, name: str) -> None:
    metadata = _object(value, required=set(), optional={
        "attempt_count",
        "bytes",
        "duration_ms",
        "item_count",
        "retry_count",
        "status_code",
    }, name=name)
    for key, number in metadata.items():
        _integer(number, f"{name}.{key}", minimum=-1_000_000_000, maximum=1_000_000_000)


def _validate_frame(value: Any, name: str) -> None:
    frame = _object(
        value,
        required=set(),
        optional={
            "instruction_address",
            "binary_address",
            "binary_offset",
            "binary_name",
            "binary_uuid",
            "symbol_address",
            "symbol_name",
        },
        name=name,
    )
    for key in ("instruction_address", "binary_address", "binary_offset", "symbol_address"):
        _optional_integer(frame, key, name, maximum=2**64 - 1)
    _optional_string(frame, "binary_name", name, identifier=True)
    _optional_string(frame, "symbol_name", name, maximum=256)
    if "binary_uuid" in frame:
        binary_uuid = _string(frame["binary_uuid"], f"{name}.binary_uuid", maximum=40)
        compact = binary_uuid.replace("-", "")
        if len(compact) not in {32, 40} or not all(character in "0123456789abcdefABCDEF" for character in compact):
            raise ValidationError(f"{name}.binary_uuid is invalid")


def _validate_diagnostic(value: Any) -> None:
    diagnostic = _object(
        value,
        required={"kind", "threads", "binary_images"},
        optional={
            "exception_name",
            "exception_type",
            "exception_code",
            "signal",
            "signal_name",
            "termination_reason",
            "crashed_thread",
            "hang_duration_ms",
            "cpu_time_ms",
            "sampled_time_ms",
            "disk_writes_bytes",
            "component",
            "error_code",
            "severity",
            "numeric_metadata",
        },
        name="report.diagnostic",
    )
    kind = _identifier(diagnostic["kind"], "report.diagnostic.kind")
    if kind not in {
        "mach_exception", "signal", "cpp_exception", "objective_c_exception",
        "memory_termination", "crash", "hang", "cpu_exception",
        "disk_write_exception", "non_fatal", "unknown",
    }:
        raise ValidationError("report.diagnostic.kind is unsupported")
    for key in ("exception_name", "signal_name"):
        if key in diagnostic:
            code_identifier = _string(
                diagnostic[key],
                f"report.diagnostic.{key}",
                maximum=128,
            )
            if not re.fullmatch(r"[A-Za-z0-9_.$:+<>()\\[\\]-]+", code_identifier):
                raise ValidationError(f"report.diagnostic.{key} is not a code identifier")
    if "termination_reason" in diagnostic:
        reason = _identifier(
            diagnostic["termination_reason"],
            "report.diagnostic.termination_reason",
        )
        if reason not in {
            "watchdog", "memory_pressure", "resource_limit", "jetsam",
            "namespace_signal", "unknown",
        }:
            raise ValidationError("report.diagnostic.termination_reason is unsupported")
    for key in (
        "exception_type", "exception_code", "hang_duration_ms", "cpu_time_ms",
        "sampled_time_ms", "disk_writes_bytes",
    ):
        _optional_integer(diagnostic, key, "report.diagnostic", maximum=2**64 - 1)
    for key in ("signal", "crashed_thread"):
        _optional_integer(diagnostic, key, "report.diagnostic", maximum=1_000_000)
    _optional_integer(
        diagnostic, "error_code", "report.diagnostic",
        minimum=-1_000_000, maximum=1_000_000,
    )
    if "component" in diagnostic:
        component = _identifier(diagnostic["component"], "report.diagnostic.component")
        if component not in {
            "app_startup", "map_rendering", "navigation", "resources",
            "networking", "storage", "unknown",
        }:
            raise ValidationError("report.diagnostic.component is unsupported")
    if "severity" in diagnostic and diagnostic["severity"] not in {"warning", "error"}:
        raise ValidationError("report.diagnostic.severity is unsupported")
    if "numeric_metadata" in diagnostic:
        _validate_numeric_metadata(diagnostic["numeric_metadata"], "report.diagnostic.numeric_metadata")

    threads = diagnostic["threads"]
    if not isinstance(threads, list) or len(threads) > 64:
        raise ValidationError("report.diagnostic.threads must contain at most 64 entries")
    for thread_index, thread_value in enumerate(threads):
        thread = _object(
            thread_value,
            required={"index", "crashed", "frames"},
            name=f"report.diagnostic.threads[{thread_index}]",
        )
        _integer(thread["index"], f"report.diagnostic.threads[{thread_index}].index", maximum=1_000_000)
        _boolean(thread["crashed"], f"report.diagnostic.threads[{thread_index}].crashed")
        frames = thread["frames"]
        if not isinstance(frames, list) or len(frames) > 512:
            raise ValidationError("a thread contains too many frames")
        for frame_index, frame in enumerate(frames):
            _validate_frame(frame, f"report.diagnostic.threads[{thread_index}].frames[{frame_index}]")

    images = diagnostic["binary_images"]
    if not isinstance(images, list) or len(images) > 512:
        raise ValidationError("report.diagnostic.binary_images must contain at most 512 entries")
    for image_index, image_value in enumerate(images):
        image = _object(
            image_value,
            required={"name"},
            optional={"uuid", "image_address"},
            name=f"report.diagnostic.binary_images[{image_index}]",
        )
        _identifier(image["name"], f"report.diagnostic.binary_images[{image_index}].name")
        _optional_string(image, "uuid", f"report.diagnostic.binary_images[{image_index}]", maximum=40)
        _optional_integer(image, "image_address", f"report.diagnostic.binary_images[{image_index}]", maximum=2**64 - 1)


def _validate_context(value: Any) -> None:
    context = _object(
        value,
        required={
            "navigation_active",
            "route_calculation_state",
            "profile_family",
            "map_source_category",
            "loaded_map_count",
            "built_in_plugin_ids",
            "custom_plugin_count",
            "application_state",
        },
        optional={
            "screen_identifier",
            "zoom_bucket",
            "memory_available_bucket_mb",
            "disk_available_bucket_mb",
        },
        name="report.context",
    )
    _boolean(context["navigation_active"], "report.context.navigation_active")
    allowed_values = {
        "route_calculation_state": {"idle", "calculating", "calculated", "failed", "unknown"},
        "profile_family": {
            "default", "car", "bicycle", "pedestrian", "aircraft", "truck",
            "motorcycle", "moped", "boat", "public_transport", "train", "ski",
            "horse", "custom", "unknown",
        },
        "map_source_category": {"offline_vector", "offline_raster", "online_raster", "unknown"},
        "application_state": {"active", "inactive", "background", "unknown"},
    }
    for key, allowed in allowed_values.items():
        if _identifier(context[key], f"report.context.{key}") not in allowed:
            raise ValidationError(f"report.context.{key} is unsupported")
    _optional_string(context, "screen_identifier", "report.context", identifier=True)
    _optional_integer(context, "zoom_bucket", "report.context", maximum=24)
    _integer(context["loaded_map_count"], "report.context.loaded_map_count", maximum=1_000)
    _integer(context["custom_plugin_count"], "report.context.custom_plugin_count", maximum=100)
    for key in ("memory_available_bucket_mb", "disk_available_bucket_mb"):
        _optional_integer(context, key, "report.context", maximum=1_048_576)
    plugin_ids = context["built_in_plugin_ids"]
    if not isinstance(plugin_ids, list) or len(plugin_ids) > 32:
        raise ValidationError("report.context.built_in_plugin_ids must contain at most 32 entries")
    for index, plugin_id in enumerate(plugin_ids):
        _identifier(plugin_id, f"report.context.built_in_plugin_ids[{index}]")


def _validate_breadcrumbs(value: Any) -> None:
    if not isinstance(value, list) or len(value) > 100:
        raise ValidationError("report.breadcrumbs must contain at most 100 entries")
    for index, item in enumerate(value):
        breadcrumb = _object(
            item,
            required={"elapsed_ms", "event"},
            optional={"numeric_metadata", "screen_identifier"},
            name=f"report.breadcrumbs[{index}]",
        )
        _integer(breadcrumb["elapsed_ms"], f"report.breadcrumbs[{index}].elapsed_ms", maximum=604_800_000)
        event = _identifier(breadcrumb["event"], f"report.breadcrumbs[{index}].event")
        if event not in {
            "app_launched", "app_became_active", "app_entered_background",
            "screen_changed", "navigation_started", "navigation_stopped",
            "route_calculation_started", "route_calculation_finished",
            "profile_changed", "plugin_changed", "map_source_changed",
            "memory_warning",
        }:
            raise ValidationError(f"report.breadcrumbs[{index}].event is unsupported")
        _optional_string(
            breadcrumb,
            "screen_identifier",
            f"report.breadcrumbs[{index}]",
            identifier=True,
        )
        if "numeric_metadata" in breadcrumb:
            _validate_numeric_metadata(
                breadcrumb["numeric_metadata"],
                f"report.breadcrumbs[{index}].numeric_metadata",
            )


def _reject_prohibited_keys(value: Any, path: str = "request") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = re.sub(r"[^a-z]", "", key.lower())
            if any(part in normalized for part in PROHIBITED_KEY_PARTS):
                raise ValidationError(f"{path}.{key} is a prohibited field")
            _reject_prohibited_keys(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _reject_prohibited_keys(child, f"{path}[{index}]")


def validate_upload_request(value: Any) -> tuple[str, dict[str, Any]]:
    request = _object(value, required={"report", "consent"}, name="request")
    _reject_prohibited_keys(request)
    report = _object(
        request["report"],
        required={
            "schema_version", "report_id", "source", "occurred_at",
            "app", "device", "diagnostic", "context", "breadcrumbs",
        },
        name="report",
    )
    if _integer(report["schema_version"], "report.schema_version", minimum=1, maximum=1) != 1:
        raise ValidationError("report.schema_version must equal 1")
    report_id = _string(report["report_id"], "report.report_id", maximum=36)
    try:
        uuid.UUID(report_id)
    except ValueError as error:
        raise ValidationError("report.report_id must be a UUID") from error
    if report_id != report_id.lower():
        raise ValidationError("report.report_id must be lowercase")
    if report["source"] not in {"kscrash", "metrickit", "non_fatal"}:
        raise ValidationError("report.source is unsupported")
    _timestamp(report["occurred_at"], "report.occurred_at")

    app = _object(report["app"], required={"version", "build"}, name="report.app")
    _identifier(app["version"], "report.app.version")
    _identifier(app["build"], "report.app.build")
    device = _object(report["device"], required={"model", "os_version"}, name="report.device")
    device_model = _string(device["model"], "report.device.model", maximum=64)
    if not re.fullmatch(r"[A-Za-z0-9,._-]+", device_model):
        raise ValidationError("report.device.model contains unsupported characters")
    _identifier(device["os_version"], "report.device.os_version")
    _validate_diagnostic(report["diagnostic"])
    _validate_context(report["context"])
    _validate_breadcrumbs(report["breadcrumbs"])

    consent = _object(
        request["consent"],
        required={"mode", "approved_at", "reviewed_payload_sha256"},
        name="consent",
    )
    if consent["mode"] != "per_report":
        raise ValidationError("consent.mode must equal per_report")
    _timestamp(consent["approved_at"], "consent.approved_at")
    reviewed_hash = _string(
        consent["reviewed_payload_sha256"],
        "consent.reviewed_payload_sha256",
        maximum=64,
    )
    if not SHA256_PATTERN.fullmatch(reviewed_hash):
        raise ValidationError("consent.reviewed_payload_sha256 must be a lowercase SHA-256")
    canonical_report = json.dumps(
        report,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    if hashlib.sha256(canonical_report).hexdigest() != reviewed_hash:
        raise ValidationError("consent hash does not match the report payload")
    return report_id, request


class CrashReportRequestHandler(BaseHTTPRequestHandler):
    server_version = "OsmAndCrashReceiver/1"

    def do_GET(self) -> None:  # noqa: N802
        request_path = self.path.partition("?")[0]
        if request_path == "/health":
            self._json_response(HTTPStatus.OK, {"status": "ok"})
            return
        if request_path in {"/", "/review"}:
            self._review_response()
            return
        self._json_response(HTTPStatus.NOT_FOUND, {"error": "not_found"})

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/api/v1/crash-reports":
            self._json_response(HTTPStatus.NOT_FOUND, {"error": "not_found"})
            return
        if self.headers.get_content_type() != "application/json":
            self._json_response(HTTPStatus.UNSUPPORTED_MEDIA_TYPE, {"error": "application_json_required"})
            return
        try:
            content_length = int(self.headers.get("Content-Length", ""))
        except ValueError:
            self._json_response(HTTPStatus.LENGTH_REQUIRED, {"error": "content_length_required"})
            return
        if content_length < 1 or content_length > MAX_REQUEST_BYTES:
            self._json_response(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, {"error": "request_too_large"})
            return

        body = self.rfile.read(content_length)
        encoding = self.headers.get("Content-Encoding", "identity").lower()
        try:
            if encoding == "gzip":
                decompressor = zlib.decompressobj(16 + zlib.MAX_WBITS)
                body = decompressor.decompress(body, MAX_REQUEST_BYTES + 1)
                if (
                    len(body) > MAX_REQUEST_BYTES
                    or decompressor.unconsumed_tail
                    or not decompressor.eof
                ):
                    self._json_response(
                        HTTPStatus.REQUEST_ENTITY_TOO_LARGE,
                        {"error": "request_too_large"},
                    )
                    return
                if decompressor.unused_data:
                    self._json_response(HTTPStatus.BAD_REQUEST, {"error": "invalid_gzip"})
                    return
            elif encoding != "identity":
                self._json_response(HTTPStatus.UNSUPPORTED_MEDIA_TYPE, {"error": "unsupported_content_encoding"})
                return
        except zlib.error:
            self._json_response(HTTPStatus.BAD_REQUEST, {"error": "invalid_gzip"})
            return
        if len(body) > MAX_REQUEST_BYTES:
            self._json_response(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, {"error": "request_too_large"})
            return

        try:
            parsed = json.loads(body)
            report_id, request = validate_upload_request(parsed)
        except (json.JSONDecodeError, UnicodeDecodeError, ValidationError) as error:
            self._json_response(HTTPStatus.BAD_REQUEST, {"error": "invalid_report", "detail": str(error)})
            return

        idempotency_key = self.headers.get("Idempotency-Key")
        if idempotency_key is None:
            self._json_response(HTTPStatus.BAD_REQUEST, {"error": "idempotency_key_required"})
            return
        if idempotency_key != report_id:
            self._json_response(HTTPStatus.CONFLICT, {"error": "idempotency_key_mismatch"})
            return

        output_directory: Path = self.server.output_directory  # type: ignore[attr-defined]
        output_path = output_directory / f"{report_id}.json"
        created = False
        try:
            descriptor = os.open(output_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(descriptor, "w", encoding="utf-8") as output:
                json.dump(request, output, indent=2, sort_keys=True, ensure_ascii=True)
                output.write("\n")
            created = True
        except FileExistsError:
            pass
        self._json_response(
            HTTPStatus.CREATED if created else HTTPStatus.OK,
            {"accepted": True, "created": created, "report_id": report_id},
        )

    def log_message(self, format: str, *args: Any) -> None:
        print(format % args)

    def _json_response(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, sort_keys=True).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _review_response(self) -> None:
        body = Path(__file__).with_name("review.html").read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'none'; style-src 'unsafe-inline'; "
            "script-src 'unsafe-inline'; img-src data:; connect-src 'none'; "
            "base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
        )
        self.end_headers()
        self.wfile.write(body)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default=8080, type=int)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(tempfile.gettempdir()) / "osmand-crash-reports",
        help="Report directory (default: the system temporary directory, outside the repository)",
    )
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    output_directory = arguments.output.expanduser().resolve()
    repository_root = Path(__file__).resolve().parents[2]
    try:
        output_directory.relative_to(repository_root)
    except ValueError:
        pass
    else:
        raise SystemExit("Refusing to write crash reports inside the repository")
    output_directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(output_directory, 0o700)

    server = ThreadingHTTPServer((arguments.host, arguments.port), CrashReportRequestHandler)
    server.output_directory = output_directory  # type: ignore[attr-defined]
    print(f"Listening on http://{arguments.host}:{arguments.port}")
    print(f"Review reports at http://{arguments.host}:{arguments.port}/review")
    print(f"Writing accepted reports to {output_directory}")
    if arguments.host == "0.0.0.0":
        print("Warning: receiver is reachable on all interfaces; use only on a trusted test network.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
