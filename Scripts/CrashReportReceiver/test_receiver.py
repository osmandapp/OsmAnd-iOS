import copy
import gzip
import hashlib
import http.client
import json
import tempfile
import threading
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path

from receiver import (
    MAX_REQUEST_BYTES,
    CrashReportRequestHandler,
    ValidationError,
    validate_upload_request,
)


def valid_request():
    request = {
        "report": {
            "schema_version": 1,
            "report_id": "12345678-1234-4234-8234-123456789abc",
            "source": "kscrash",
            "occurred_at": "2026-07-24T12:00:00Z",
            "app": {"version": "5.2.0", "build": "5200"},
            "device": {"model": "iPhone16.2", "os_version": "18.5"},
            "diagnostic": {
                "kind": "signal",
                "signal": 6,
                "threads": [
                    {
                        "index": 0,
                        "crashed": True,
                        "frames": [
                            {
                                "instruction_address": 4096,
                                "binary_name": "OsmAnd",
                                "binary_uuid": "00112233445566778899AABBCCDDEEFF",
                            }
                        ],
                    }
                ],
                "binary_images": [
                    {
                        "name": "OsmAnd",
                        "uuid": "00112233445566778899AABBCCDDEEFF",
                        "image_address": 4096,
                    }
                ],
            },
            "context": {
                "navigation_active": False,
                "route_calculation_state": "idle",
                "profile_family": "car",
                "map_source_category": "offline_vector",
                "loaded_map_count": 2,
                "built_in_plugin_ids": ["osmand.nautical"],
                "custom_plugin_count": 0,
                "application_state": "active",
            },
            "breadcrumbs": [{"elapsed_ms": 1200, "event": "app_became_active"}],
        },
        "consent": {
            "mode": "per_report",
            "approved_at": "2026-07-24T12:01:00Z",
            "reviewed_payload_sha256": "pending",
        },
    }
    canonical_report = json.dumps(
        request["report"],
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    request["consent"]["reviewed_payload_sha256"] = hashlib.sha256(canonical_report).hexdigest()
    return request


class ReceiverValidationTests(unittest.TestCase):
    def test_accepts_valid_envelope(self):
        report_id, _ = validate_upload_request(valid_request())
        self.assertEqual(report_id, "12345678-1234-4234-8234-123456789abc")

    def test_rejects_unknown_field(self):
        request = valid_request()
        request["report"]["coordinates"] = [51.5, -0.1]
        with self.assertRaises(ValidationError):
            validate_upload_request(request)

    def test_rejects_sensitive_keys_at_any_depth(self):
        for key in ("search_query", "file_path", "notification_contents", "custom_plugin_name"):
            request = valid_request()
            request["report"]["diagnostic"][key] = "private"
            with self.subTest(key=key), self.assertRaises(ValidationError):
                validate_upload_request(request)

    def test_rejects_paths_and_urls_in_allowed_string_fields(self):
        for value in ("https://tiles.example/private", "/private/var/mobile/secret"):
            request = copy.deepcopy(valid_request())
            request["report"]["diagnostic"]["exception_name"] = value
            with self.subTest(value=value), self.assertRaises(ValidationError):
                validate_upload_request(request)

    def test_rejects_unapproved_numeric_metadata(self):
        request = valid_request()
        request["report"]["diagnostic"]["numeric_metadata"] = {"latitude": 51500000}
        with self.assertRaises(ValidationError):
            validate_upload_request(request)

    def test_rejects_payload_changed_after_consent(self):
        request = valid_request()
        request["report"]["context"]["loaded_map_count"] = 3
        with self.assertRaisesRegex(ValidationError, "consent hash"):
            validate_upload_request(request)


class ReceiverHTTPTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), CrashReportRequestHandler)
        self.server.output_directory = Path(self.temporary_directory.name)
        self.server_thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.server_thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.server_thread.join(timeout=2)
        self.temporary_directory.cleanup()

    def request(self, method, path, body=None, headers=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.server.server_port, timeout=5)
        connection.request(method, path, body=body, headers=headers or {})
        response = connection.getresponse()
        payload = json.loads(response.read())
        connection.close()
        return response.status, payload

    def test_health(self):
        status, payload = self.request("GET", "/health")
        self.assertEqual(status, 200)
        self.assertEqual(payload, {"status": "ok"})

    def test_review_page_is_local_only(self):
        connection = http.client.HTTPConnection(
            "127.0.0.1", self.server.server_port, timeout=5
        )
        connection.request("GET", "/review")
        response = connection.getresponse()
        body = response.read()
        content_security_policy = response.getheader("Content-Security-Policy")
        connection.close()

        self.assertEqual(response.status, 200)
        self.assertEqual(response.getheader("Content-Type"), "text/html; charset=utf-8")
        self.assertIn(b"OsmAnd crash report reviewer", body)
        self.assertIsNotNone(content_security_policy)
        self.assertIn("connect-src 'none'", content_security_policy)

    def test_gzip_and_idempotency(self):
        report_id = valid_request()["report"]["report_id"]
        body = gzip.compress(json.dumps(valid_request()).encode("utf-8"))
        headers = {
            "Content-Type": "application/json",
            "Content-Encoding": "gzip",
            "Idempotency-Key": report_id,
        }

        first_status, first_payload = self.request(
            "POST", "/api/v1/crash-reports", body, headers
        )
        second_status, second_payload = self.request(
            "POST", "/api/v1/crash-reports", body, headers
        )

        self.assertEqual(first_status, 201)
        self.assertTrue(first_payload["created"])
        self.assertEqual(second_status, 200)
        self.assertFalse(second_payload["created"])
        self.assertEqual(len(list(Path(self.temporary_directory.name).glob("*.json"))), 1)

    def test_rejects_request_over_two_mib(self):
        body = b" " * (MAX_REQUEST_BYTES + 1)
        status, payload = self.request(
            "POST",
            "/api/v1/crash-reports",
            body,
            {"Content-Type": "application/json"},
        )
        self.assertEqual(status, 413)
        self.assertEqual(payload["error"], "request_too_large")


if __name__ == "__main__":
    unittest.main()
