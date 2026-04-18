# winpe-drivers

Optional override directory. **Not consumed by the current `sources.pkr.hcl`** — the Autounattend.xml files reference driver paths on the mounted `virtio-win` ISO directly (`D:\vioscsi\2k25\amd64`, etc.).

Populate this directory only if you need to ship pre-extracted drivers inside the `cd_files` ISO (e.g. Secure Boot environments with signed-driver requirements, or custom OEM drivers). To use it:

1. Mount the VirtIO ISO (≥ `virtio-win-0.1.240`).
2. Copy from the ISO into this folder:
   - `NetKVM\w11\amd64\*` (Windows Server 2022/2025 both use the `w11` / `2k22` / `2k25` payload depending on ISO vintage)
   - `vioscsi\w11\amd64\*`
   - `viostor\w11\amd64\*`
3. Add an extra `cd_files` entry referencing `./winpe-drivers/` in `sources.pkr.hcl`.
4. Add `<PathAndCredentials>` entries in the Autounattend `Microsoft-Windows-PnpCustomizationsWinPE` block for the cd_files drive letter.
