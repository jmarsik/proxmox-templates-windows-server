#!/usr/bin/env python3
"""Read-only Proxmox VE API client for QEMU VM config and cloud-init dump.

Examples:
    pve_query.py --host pve.example --user 'root@pam!mytoken' \\
        --token-value XXXX config --node pve1 --vmid 100
    pve_query.py --host pve.example --user 'root@pam!mytoken' \\
        --token-value XXXX cloudinit --node pve1 --vmid 100 --type user
"""

from __future__ import annotations

import argparse
import json
import sys

from proxmoxer import ProxmoxAPI


def parse_user(user: str) -> tuple[str, str]:
    """Split 'user@realm!tokenid' into ('user@realm', 'tokenid')."""
    if "!" not in user:
        raise SystemExit(
            "--user must be in form 'user@realm!tokenid' "
            "(e.g. 'root@pam!mytoken')"
        )
    base, token_name = user.rsplit("!", 1)
    return base, token_name


def connect(args: argparse.Namespace) -> ProxmoxAPI:
    user, token_name = parse_user(args.user)
    return ProxmoxAPI(
        args.host,
        port=args.port,
        user=user,
        token_name=token_name,
        token_value=args.token_value,
        verify_ssl=not args.insecure,
    )


def cmd_config(pve: ProxmoxAPI, args: argparse.Namespace) -> None:
    params = {}
    if args.current:
        params["current"] = 1
    if args.snapshot:
        params["snapshot"] = args.snapshot
    data = pve.nodes(args.node).qemu(args.vmid).config.get(**params)
    print(json.dumps(data, indent=2, sort_keys=True))


def cmd_cloudinit(pve: ProxmoxAPI, args: argparse.Namespace) -> None:
    # cloudinit/dump returns raw YAML/text in the 'data' field
    data = (
        pve.nodes(args.node)
        .qemu(args.vmid)
        .cloudinit.dump.get(type=args.type)
    )
    # proxmoxer unwraps 'data'; for this endpoint it's a string
    if isinstance(data, str):
        sys.stdout.write(data)
        if not data.endswith("\n"):
            sys.stdout.write("\n")
    else:
        print(json.dumps(data, indent=2, sort_keys=True))


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--host", required=True, help="Proxmox host (FQDN or IP)")
    p.add_argument("--port", type=int, default=8006)
    p.add_argument("--user", required=True, help="'user@realm!tokenid'")
    p.add_argument("--token-value", required=True, help="API token secret (UUID)")
    p.add_argument("--insecure", action="store_true", help="Skip TLS verify")

    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("config", help="GET /nodes/{node}/qemu/{vmid}/config")
    c.add_argument("--node", required=True)
    c.add_argument("--vmid", required=True, type=int)
    c.add_argument("--current", action="store_true", help="Return current (running) config")
    c.add_argument("--snapshot", help="Fetch config of named snapshot")
    c.set_defaults(func=cmd_config)

    ci = sub.add_parser("cloudinit", help="GET /nodes/{node}/qemu/{vmid}/cloudinit/dump")
    ci.add_argument("--node", required=True)
    ci.add_argument("--vmid", required=True, type=int)
    ci.add_argument(
        "--type",
        choices=["user", "network", "meta"],
        default="user",
        help="Cloud-init section to dump (default: user)",
    )
    ci.set_defaults(func=cmd_cloudinit)

    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    pve = connect(args)
    args.func(pve, args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
