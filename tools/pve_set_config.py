#!/usr/bin/env python3
"""Set QEMU VM config via Proxmox VE API (PUT /nodes/{node}/qemu/{vmid}/config).

Currently supports only the 'citype' field (cloud-init type: configdrive2|nocloud|opennebula).

Example:
    pve_set_config.py --host pve.example --user 'root@pam!mytoken' \\
        --token-value XXXX --node pve1 --vmid 100 --citype nocloud
"""

from __future__ import annotations

import argparse
import json

from proxmoxer import ProxmoxAPI


CITYPE_CHOICES = ["configdrive2", "nocloud", "opennebula"]


def parse_user(user: str) -> tuple[str, str]:
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


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--host", required=True, help="Proxmox host (FQDN or IP)")
    p.add_argument("--port", type=int, default=8006)
    p.add_argument("--user", required=True, help="'user@realm!tokenid'")
    p.add_argument("--token-value", required=True, help="API token secret (UUID)")
    p.add_argument("--insecure", action="store_true", help="Skip TLS verify")
    p.add_argument("--node", required=True)
    p.add_argument("--vmid", required=True, type=int)
    p.add_argument(
        "--citype",
        required=True,
        choices=CITYPE_CHOICES,
        help="Cloud-init config format",
    )
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    pve = connect(args)
    result = pve.nodes(args.node).qemu(args.vmid).config.put(citype=args.citype)
    # PUT returns task UPID (string) or None
    if result is not None:
        print(json.dumps(result, indent=2, sort_keys=True) if not isinstance(result, str) else result)
    else:
        print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
