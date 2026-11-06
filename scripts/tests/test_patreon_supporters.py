import copy
from io import BytesIO
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from sync_patreon_supporters import (
    API, TOKEN_URL, HTTPFailure, PatreonClient, SyncError, collect_names,
    discover, feed_bytes, main, persist_tokens, request_json,
)
from publish_supporters import publish


TOKENS = {"access_token": "old-access", "refresh_token": "old-refresh"}
RENEWED = {"access_token": "new-access", "refresh_token": "new-refresh"}
CAMPAIGN = {"data": {"id": "1", "type": "campaign", "relationships": {
    "tiers": {"data": [{"type": "tier", "id": "6"}]}
}}}


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.members = json.loads(Path(__file__).with_name("fixtures").joinpath("members.json").read_text())

    def client(self, responses, persist=None):
        return PatreonClient(TOKENS, "client", "secret", transport=Mock(side_effect=responses),
                             persist=persist or Mock())

    def test_filters_hidden_duplicate_inactive_and_other_tiers(self):
        self.assertEqual(collect_names(self.client([CAMPAIGN, self.members]), "1", "6"), ["Alice", "Élodie 🌟"])

    def test_all_pages_are_included_and_order_is_stable(self):
        first = copy.deepcopy(self.members)
        first["data"] = first["data"][::-1]
        first["links"]["next"] = API + "campaigns/1/members?page%5Bcursor%5D=next"
        second = copy.deepcopy(self.members)
        second["data"][0]["attributes"]["full_name"] = "bob"
        names = collect_names(self.client([CAMPAIGN, first, second]), "1", "6")
        self.assertEqual(names, ["Alice", "bob", "Élodie 🌟"])
        self.assertEqual(feed_bytes(names), feed_bytes(collect_names(self.client([CAMPAIGN, second, first | {"links": {}}]), "1", "6")))

    def test_valid_empty_campaign(self):
        self.assertEqual(collect_names(self.client([CAMPAIGN, {"data": []}]), "1", "6"), [])

    def test_invalid_tier_does_not_return_empty_names(self):
        with self.assertRaises(SyncError):
            collect_names(self.client([CAMPAIGN]), "1", "999")

    def test_missing_or_malformed_member_fields_fail_closed(self):
        for mutation in (lambda m: m.pop("attributes"),
                         lambda m: m["relationships"].clear(),
                         lambda m: m["attributes"].update(full_name=42)):
            page = copy.deepcopy(self.members)
            mutation(page["data"][0])
            with self.subTest(mutation=mutation), self.assertRaises(SyncError):
                collect_names(self.client([CAMPAIGN, page]), "1", "6")

    def test_inactive_members_do_not_require_names_or_tiers(self):
        page = {"data": [
            {"type": "member", "id": str(i), "attributes": {"patron_status": status}}
            for i, status in enumerate(("declined_patron", "former_patron", None))
        ]}
        self.assertEqual(collect_names(self.client([CAMPAIGN, page]), "1", "6"), [])

    def test_off_tier_members_do_not_require_names(self):
        member = copy.deepcopy(self.members["data"][4])
        del member["attributes"]["full_name"]
        self.assertEqual(collect_names(self.client([CAMPAIGN, {"data": [member]}]), "1", "6"), [])

    def test_diagnostics_name_the_field_without_member_values(self):
        for mutation, path in (
            (lambda m: m.update(id=12345), "id"),
            (lambda m: m["attributes"].pop("full_name"), "attributes.full_name"),
            (lambda m: m["attributes"].update(full_name={"private": "Must never be logged"}), "attributes.full_name"),
            (lambda m: m["relationships"]["currently_entitled_tiers"].update(data=None), "relationships.currently_entitled_tiers.data"),
        ):
            member = copy.deepcopy(self.members["data"][0])
            mutation(member)
            with self.subTest(path=path), self.assertRaises(SyncError) as error:
                collect_names(self.client([CAMPAIGN, {"data": [member]}]), "1", "6")
            self.assertIn(f"field {path}:", str(error.exception))
            self.assertNotIn("Must never be logged", str(error.exception))
            self.assertNotIn("12345", str(error.exception))

    def test_bad_page_and_links_fail_closed(self):
        for page in ({"data": None}, {"data": [], "errors": [{}]},
                     {"data": [], "links": []}, {"data": [], "links": {"next": ""}}):
            with self.subTest(page=page), self.assertRaises(SyncError):
                collect_names(self.client([CAMPAIGN, page]), "1", "6")

    def test_pagination_loop_and_foreign_urls_rejected(self):
        for next_url in ("https://example.com/steal", "http://www.patreon.com/api/oauth2/v2/campaigns/1/members",
                         API + "campaigns/2/members", API + "campaigns/1/members?loop"):
            page = {"data": [], "links": {"next": next_url}}
            with self.subTest(url=next_url), self.assertRaises(SyncError):
                collect_names(self.client([CAMPAIGN, page, page]), "1", "6")

    def test_failed_later_page_leaves_output_untouched(self):
        page = copy.deepcopy(self.members)
        page["links"]["next"] = API + "campaigns/1/members?next=1"
        client = self.client([CAMPAIGN, page, HTTPFailure(503)])
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory, "supporters.json")
            output.write_bytes(b"existing feed")
            with patch("sync_patreon_supporters.PatreonClient", return_value=client), \
                 patch.dict(os.environ, {"PATREON_CREATOR_TOKENS": json.dumps(TOKENS), "PATREON_CLIENT_ID": "client",
                      "PATREON_CLIENT_SECRET": "secret", "PATREON_SECRETS_TOKEN": "github", "GITHUB_REPOSITORY": "a/b",
                      "PATREON_CAMPAIGN_ID": "1", "PATREON_TIER_ID": "6"}), \
                 patch.object(sys, "argv", ["sync", "--output", str(output)]):
                self.assertEqual(main(), 1)
            self.assertEqual(output.read_bytes(), b"existing feed")

    def test_refresh_is_persisted_before_retry(self):
        events = []
        def transport(url, **kwargs):
            events.append((url, kwargs))
            if url == TOKEN_URL:
                return RENEWED
            if kwargs["token"] == "old-access":
                raise HTTPFailure(401)
            self.assertEqual(events[-2], ("persist", RENEWED))
            return {"data": []}
        client = PatreonClient(TOKENS, "client", "secret", transport=transport,
                               persist=lambda tokens: events.append(("persist", tokens)))
        self.assertEqual(client.get(API + "campaigns"), {"data": []})

    def test_refresh_or_persistence_failures_stop_processing(self):
        for responses, persist in (([HTTPFailure(401), HTTPFailure(400)], Mock()),
                                   ([HTTPFailure(401), {"access_token": "x"}], Mock()),
                                   ([HTTPFailure(401), RENEWED], Mock(side_effect=SyncError("Cannot save")))):
            client = self.client(responses, persist)
            with self.subTest(responses=responses), self.assertRaises(SyncError):
                client.get(API + "campaigns")
            self.assertEqual(client.transport.call_count, 2)

    def test_refresh_only_once_per_run(self):
        client = self.client([HTTPFailure(401), RENEWED, HTTPFailure(401)])
        with self.assertRaises(HTTPFailure):
            client.get(API + "campaigns")
        self.assertEqual(client.transport.call_count, 3)

    def test_persistence_uses_stdin_and_does_not_expose_cli_errors(self):
        with patch.dict(os.environ, {"GITHUB_REPOSITORY": "a/b", "PATREON_SECRETS_TOKEN": "github"}), \
             patch("sync_patreon_supporters.subprocess.run", return_value=Mock(returncode=1)) as run:
            with self.assertRaisesRegex(SyncError, "Could not persist"):
                persist_tokens(RENEWED)
            self.assertNotIn("new-refresh", " ".join(run.call_args.args[0]))
            self.assertEqual(json.loads(run.call_args.kwargs["input"]), RENEWED)

    def test_discovery_lists_tier_metadata(self):
        page = copy.deepcopy(CAMPAIGN)
        page["data"] = [page["data"]]
        page["included"] = [{"type": "tier", "id": "6", "attributes": {"title": "Your name in iTorrent"}}]
        self.assertEqual(discover(self.client([page])), [{"campaign_id": "1", "tiers": [{"id": "6", "title": "Your name in iTorrent"}]}])

    def test_get_retries_transient_failures(self):
        opener = Mock()
        response = BytesIO(b'{"data": []}')
        opener.open.side_effect = [HTTPError(API, 429, "", {"Retry-After": "2"}, None),
                                   HTTPError(API, 503, "", {}, None), response]
        sleep = Mock()
        with patch("sync_patreon_supporters.build_opener", return_value=opener):
            self.assertEqual(request_json(API, token="secret", sleep=sleep), {"data": []})
        self.assertEqual(opener.open.call_count, 3)
        self.assertEqual(sleep.call_count, 2)

    def test_token_exchange_is_not_retried(self):
        opener = Mock()
        opener.open.side_effect = HTTPError(TOKEN_URL, 503, "", {}, None)
        with patch("sync_patreon_supporters.build_opener", return_value=opener), self.assertRaises(HTTPFailure):
            request_json(TOKEN_URL, form={"grant_type": "refresh_token"})
        self.assertEqual(opener.open.call_count, 1)

    def test_exhausted_retries_fail(self):
        opener = Mock()
        opener.open.side_effect = HTTPError(API, 503, "", {}, None)
        with patch("sync_patreon_supporters.build_opener", return_value=opener), self.assertRaises(HTTPFailure):
            request_json(API, sleep=Mock())
        self.assertEqual(opener.open.call_count, 4)

    def test_renewed_tokens_survive_a_later_request_failure(self):
        save = Mock()
        client = self.client([HTTPFailure(401), RENEWED, HTTPFailure(503)], save)
        with self.assertRaises(HTTPFailure):
            client.get(API + "campaigns")
        save.assert_called_once_with(RENEWED)


class PublishTests(unittest.TestCase):
    def test_branch_creation_noop_updates_and_empty_feed(self):
        with tempfile.TemporaryDirectory() as directory:
            remote = Path(directory, "remote.git")
            subprocess.run(["git", "init", "--bare", "--quiet", str(remote)], check=True)
            feed = Path(directory, "feed.json")
            feed.write_bytes(feed_bytes(["Alice"]))
            self.assertTrue(publish(feed, str(remote)))
            self.assertFalse(publish(feed, str(remote)))
            feed.write_bytes(feed_bytes(["Alice", "Bob"]))
            self.assertTrue(publish(feed, str(remote)))
            feed.write_bytes(feed_bytes([]))
            self.assertTrue(publish(feed, str(remote)))
            def git(*args):
                return subprocess.check_output(["git", "--git-dir", str(remote), *args], text=True).strip()
            self.assertEqual(git("rev-list", "--count", "patreon-data"), "3")
            self.assertEqual(git("ls-tree", "--name-only", "patreon-data"), "supporters.json")
            self.assertEqual(json.loads(git("show", "patreon-data:supporters.json")), {"version": 1, "names": []})
            self.assertEqual(git("rev-list", "--max-parents=0", "--count", "patreon-data"), "1")

    def test_invalid_feed_cannot_create_a_branch(self):
        with tempfile.TemporaryDirectory() as directory:
            feed = Path(directory, "feed.json")
            for payload in (b"{}", b'{"version": 2, "names": []}', b'{"version": 1, "names": [1]}', feed_bytes([" Alice "])):
                feed.write_bytes(payload)
                with self.subTest(payload=payload), self.assertRaises(SyncError):
                    publish(feed, "unused-remote")

    def test_existing_unexpected_files_or_symlinks_are_not_overwritten(self):
        for symlink in (False, True):
            with self.subTest(symlink=symlink), tempfile.TemporaryDirectory() as directory:
                remote = Path(directory, "remote.git")
                work = Path(directory, "work")
                subprocess.run(["git", "init", "--bare", "--quiet", str(remote)], check=True)
                feed = Path(directory, "feed.json")
                feed.write_bytes(feed_bytes(["Alice"]))
                publish(feed, str(remote))
                subprocess.run(["git", "clone", "--quiet", "--branch", "patreon-data", str(remote), str(work)], check=True)
                if symlink:
                    work.joinpath("supporters.json").unlink()
                    work.joinpath("supporters.json").symlink_to(Path(directory, "outside"))
                else:
                    work.joinpath("unexpected.txt").write_text("Preserve me")
                subprocess.run(["git", "-C", str(work), "add", "."], check=True)
                subprocess.run(["git", "-C", str(work), "-c", "user.name=test", "-c", "user.email=test@example.com",
                                "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Unexpected change"], check=True)
                subprocess.run(["git", "-C", str(work), "push", "--quiet"], check=True)
                previous = subprocess.check_output(["git", "--git-dir", str(remote), "rev-parse", "patreon-data"])
                with self.assertRaises(SyncError):
                    publish(feed, str(remote))
                self.assertEqual(subprocess.check_output(["git", "--git-dir", str(remote), "rev-parse", "patreon-data"]), previous)
                self.assertFalse(Path(directory, "outside").exists())


if __name__ == "__main__":
    unittest.main()
