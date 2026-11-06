#!/usr/bin/env python3
"""Fetch a complete Patreon snapshot without exposing credentials or member records."""

import argparse
from datetime import datetime, timezone
from http.client import HTTPException
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener


API = "https://www.patreon.com/api/oauth2/v2/"
TOKEN_URL = "https://www.patreon.com/api/oauth2/token"
TOKEN_SECRET = "PATREON_CREATOR_TOKENS"


class SyncError(Exception):
    pass


class HTTPFailure(SyncError):
    def __init__(self, status):
        self.status = status
        super().__init__(f"Patreon request failed (HTTP {status}).")


class NoRedirects(HTTPRedirectHandler):
    # Do not forward a creator credential to a redirect target.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request_json(url, *, token=None, form=None, sleep=time.sleep):
    body = urlencode(form).encode() if form is not None else None
    headers = {"Accept": "application/json", "User-Agent": "iTorrent-supporter-sync/1"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if body is not None:
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    opener = build_opener(NoRedirects())
    for attempt in range(4):
        try:
            with opener.open(Request(url, data=body, headers=headers), timeout=30) as response:
                result = json.load(response)
                if not isinstance(result, dict):
                    raise SyncError("Patreon returned an invalid document.")
                return result
        except HTTPError as error:
            # A token exchange may rotate a refresh token even if its response is
            # lost; never automatically repeat that non-idempotent operation.
            if form is None and (error.code == 429 or 500 <= error.code < 600) and attempt < 3:
                retry_after = error.headers.get("Retry-After", "")
                delay = min(float(retry_after), 60) if retry_after.isdigit() else 2 ** attempt
                sleep(delay)
                continue
            raise HTTPFailure(error.code) from None
        except (URLError, TimeoutError, OSError, HTTPException):
            if form is None and attempt < 3:
                sleep(2 ** attempt)
                continue
            raise SyncError("Patreon could not be reached.") from None
        except (ValueError, UnicodeError):
            raise SyncError("Patreon returned invalid JSON.") from None
    raise SyncError("Patreon retries exhausted.")


def required(name):
    value = os.environ.get(name, "").strip()
    if not value:
        raise SyncError(f"Missing configuration: {name}.")
    return value


def validate_tokens(tokens):
    if not isinstance(tokens, dict) or any(
        not isinstance(tokens.get(key), str) or not tokens[key].strip()
        for key in ("access_token", "refresh_token")
    ):
        raise SyncError(f"{TOKEN_SECRET} must contain access_token and refresh_token strings.")
    return {key: tokens[key] for key in ("access_token", "refresh_token")}


def persist_tokens(tokens):
    repository = required("GITHUB_REPOSITORY")
    if not re.fullmatch(r"[\w.-]+/[\w.-]+", repository):
        raise SyncError("Invalid repository configuration.")
    environment = dict(os.environ, GH_TOKEN=required("PATREON_SECRETS_TOKEN"))
    # Pass the value on stdin, never in process arguments or log output.
    try:
        result = subprocess.run(
            ["gh", "secret", "set", TOKEN_SECRET, "--repo", repository],
            input=json.dumps(tokens), text=True, capture_output=True, env=environment,
            timeout=60,
        )
    except (OSError, subprocess.TimeoutExpired):
        raise SyncError("Could not persist renewed Patreon credentials; reset the token secret before retrying.") from None
    if result.returncode:
        raise SyncError("Could not persist renewed Patreon credentials; reset the token secret before retrying.")


class PatreonClient:
    def __init__(self, tokens, client_id, client_secret, *, transport=request_json, persist=persist_tokens):
        self.tokens = validate_tokens(tokens)
        self.client_id = client_id
        self.client_secret = client_secret
        self.transport = transport
        self.persist = persist
        self.refreshed = False

    def get(self, url):
        try:
            return self.transport(url, token=self.tokens["access_token"])
        except HTTPFailure as error:
            if error.status != 401 or self.refreshed:
                raise
        self.refreshed = True
        renewed = self.transport(TOKEN_URL, form={
            "grant_type": "refresh_token",
            "refresh_token": self.tokens["refresh_token"],
            "client_id": self.client_id,
            "client_secret": self.client_secret,
        })
        renewed = validate_tokens(renewed)
        if os.environ.get("GITHUB_ACTIONS") == "true":
            for value in renewed.values():
                escaped = value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
                print(f"::add-mask::{escaped}", flush=True)
        # Persist immediately, even if a subsequent member request fails.
        self.persist(renewed)
        self.tokens = renewed
        return self.transport(url, token=self.tokens["access_token"])

    def pages(self, path, query):
        endpoint = API + path
        url = endpoint + "?" + urlencode(query)
        seen = set()
        while url:
            parsed = urlsplit(url)
            if (parsed.scheme != "https" or parsed.netloc != "www.patreon.com"
                    or parsed.path != urlsplit(endpoint).path or parsed.fragment):
                raise SyncError("Patreon supplied an unexpected pagination URL.")
            if url in seen or len(seen) >= 10000:
                raise SyncError("Patreon pagination did not terminate.")
            seen.add(url)
            document = self.get(url)
            if not isinstance(document, dict) or document.get("errors") or not isinstance(document.get("data"), list):
                raise SyncError("Patreon returned an invalid page.")
            links = document.get("links", {})
            if not isinstance(links, dict):
                raise SyncError("Patreon returned invalid pagination links.")
            next_url = links.get("next")
            if next_url is not None and (not isinstance(next_url, str) or not next_url):
                raise SyncError("Patreon returned an invalid next-page link.")
            yield document
            url = next_url


def member_name(member, tier_id):
    """Validate the fields needed for eligibility, then the qualifying name.

    Report only fixed field paths and JSON types, never member values. Inactive
    members do not need a name or tier relationship to be excluded safely.
    """
    def field(container, key, path, expected):
        if not isinstance(container, dict) or key not in container:
            raise SyncError(f"Invalid Patreon member field {path}: missing (expected {expected}).")
        return container[key]

    def invalid(path, value, expected):
        raise SyncError(f"Invalid Patreon member field {path}: expected {expected}, received {type(value).__name__}.")

    resource_type = field(member, "type", "type", "member resource")
    if resource_type != "member":
        invalid("type", resource_type, "member resource")
    identifier = field(member, "id", "id", "string")
    if not isinstance(identifier, str):
        invalid("id", identifier, "string")
    attributes = field(member, "attributes", "attributes", "object")
    if not isinstance(attributes, dict):
        invalid("attributes", attributes, "object")
    status = field(attributes, "patron_status", "attributes.patron_status", "string or null")
    if status is not None and not isinstance(status, str):
        invalid("attributes.patron_status", status, "string or null")
    if status != "active_patron":
        return None

    relationships = field(member, "relationships", "relationships", "object")
    if not isinstance(relationships, dict):
        invalid("relationships", relationships, "object")
    entitlement = field(relationships, "currently_entitled_tiers", "relationships.currently_entitled_tiers", "object")
    if not isinstance(entitlement, dict):
        invalid("relationships.currently_entitled_tiers", entitlement, "object")
    tiers = field(entitlement, "data", "relationships.currently_entitled_tiers.data", "array")
    if not isinstance(tiers, list):
        invalid("relationships.currently_entitled_tiers.data", tiers, "array")
    for tier in tiers:
        resource_type = field(tier, "type", "relationships.currently_entitled_tiers.data[].type", "tier resource")
        if resource_type != "tier":
            invalid("relationships.currently_entitled_tiers.data[].type", resource_type, "tier resource")
        identifier = field(tier, "id", "relationships.currently_entitled_tiers.data[].id", "string")
        if not isinstance(identifier, str):
            invalid("relationships.currently_entitled_tiers.data[].id", identifier, "string")
    if not any(tier["id"] == tier_id for tier in tiers):
        return None

    name = field(attributes, "full_name", "attributes.full_name", "string or null")
    if name is not None and not isinstance(name, str):
        invalid("attributes.full_name", name, "string or null")
    if name is None:
        return None
    return name.strip() or None


def supporter_sort_key(supporter):
    return (supporter["since"] or "9999-12-31", supporter["name"].casefold(),
            supporter["name"], supporter["avatar_url"] or "")


def avatar_url(value):
    if not isinstance(value, str) or not value or value != value.strip():
        return None
    try:
        url = urlsplit(value)
        if url.scheme == "https" and url.hostname and not url.username and not url.password and not url.fragment:
            return value
    except ValueError:
        pass
    return None


def pledge_date(value):
    if value is None:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            raise ValueError
        return parsed.astimezone(timezone.utc).date().isoformat()
    except (AttributeError, TypeError, ValueError):
        raise SyncError("Invalid Patreon member field attributes.pledge_relationship_start: expected ISO timestamp or null.") from None


def collect_supporters(client, campaign_id, tier_id):
    if not campaign_id.isdigit() or not tier_id.isdigit():
        raise SyncError("Campaign and tier IDs must be numeric Patreon IDs.")
    # Validate the configured tier even when the campaign has no members. A
    # mistyped ID must not silently erase the published list.
    campaign = client.get(API + f"campaigns/{campaign_id}?" + urlencode({
        "include": "tiers", "fields[tier]": "title",
    }))
    try:
        if campaign.get("errors") or campaign["data"]["id"] != campaign_id or campaign["data"]["type"] != "campaign":
            raise ValueError
        tier_ids = campaign["data"]["relationships"]["tiers"]["data"]
        if not isinstance(tier_ids, list) or not any(
            tier["type"] == "tier" and tier["id"] == tier_id for tier in tier_ids
        ):
            raise ValueError
    except (KeyError, TypeError, ValueError):
        raise SyncError("Configured tier was not found in the configured campaign.") from None

    supporters = {}
    for document in client.pages(f"campaigns/{campaign_id}/members", {
        "include": "currently_entitled_tiers,user",
        "fields[member]": "full_name,patron_status,pledge_relationship_start",
        "fields[user]": "thumb_url",
        "fields[tier]": "title",
        "page[count]": "100",
    }):
        included = document.get("included", [])
        if not isinstance(included, list):
            raise SyncError("Patreon returned invalid included resources.")
        users = {user.get("id"): user for user in included
                 if isinstance(user, dict) and user.get("type") == "user" and isinstance(user.get("id"), str)}
        for member in document["data"]:
            name = member_name(member, tier_id)
            if name:
                relationship = member["relationships"].get("user", {})
                reference = relationship.get("data") if isinstance(relationship, dict) else None
                user_id = reference.get("id") if isinstance(reference, dict) else None
                user = users.get(user_id, {}) if isinstance(user_id, str) else {}
                attributes = user.get("attributes", {})
                image = avatar_url(attributes.get("thumb_url")) if isinstance(attributes, dict) else None
                since = pledge_date(member["attributes"].get("pledge_relationship_start"))
                supporter = {"name": name, "avatar_url": image, "since": since}
                supporters[(name, image, since)] = supporter
    return sorted(supporters.values(), key=supporter_sort_key)


def feed_bytes(supporters):
    document = {"version": 1, "supporters": supporters}
    return (json.dumps(document, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def discover(client):
    # Only campaign/tier metadata is printed; never member records or tokens.
    campaigns = []
    for page in client.pages("campaigns", {"include": "tiers", "fields[tier]": "title"}):
        try:
            included = {tier["id"]: tier["attributes"]["title"]
                        for tier in page.get("included", []) if tier["type"] == "tier"}
            for campaign in page["data"]:
                campaigns.append({"campaign_id": campaign["id"], "tiers": [
                    {"id": tier["id"], "title": included[tier["id"]]}
                    for tier in campaign["relationships"]["tiers"]["data"]
                ]})
        except (KeyError, TypeError):
            raise SyncError("Patreon returned invalid campaign metadata.") from None
    return campaigns


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--discover", action="store_true", help="List campaign and tier IDs, without member data")
    parser.add_argument("--output", type=Path, default=Path("supporters.json"))
    args = parser.parse_args()
    try:
        tokens = json.loads(required(TOKEN_SECRET))
        client = PatreonClient(tokens, required("PATREON_CLIENT_ID"), required("PATREON_CLIENT_SECRET"))
        # Check renewal configuration before contacting Patreon.
        required("PATREON_SECRETS_TOKEN")
        required("GITHUB_REPOSITORY")
        if args.discover:
            print(json.dumps(discover(client), ensure_ascii=False, indent=2))
        else:
            supporters = collect_supporters(client, required("PATREON_CAMPAIGN_ID"), required("PATREON_TIER_ID"))
            args.output.write_bytes(feed_bytes(supporters))
            print(f"Prepared supporter feed ({len(supporters)} supporters).")
    except (SyncError, ValueError, OSError):
        # Exception details from libraries/remote responses may contain secrets.
        # SyncError messages are deliberately constructed without remote content.
        error = sys.exc_info()[1]
        print(str(error) if isinstance(error, SyncError) else "Invalid configuration or output could not be written.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
