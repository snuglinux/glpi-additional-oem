# glpi-additional-oem

Generate OEM-based GLPI Agent inventory identity data for systems with invalid DMI serials or UUIDs.

## What it does

`glpi-additional-oem` generates:

```text
/run/glpi-agent/additional-content.json
```

GLPI Agent reads this file via:

```ini
additional-content = /run/glpi-agent/additional-content.json
```

The tool is useful for machines where BIOS/DMI contains values like:

```text
Default string
To be filled by O.E.M.
System Serial Number
00000000
03000200-0400-0500-0006-000700080009
```

If no usable serial is found, it generates a controlled serial:

```text
OEM-GIGABYTE-J3455N-D3H-AABBCC112233
```

from vendor, board model, and a physical MAC address.

## Important GLPI note

If SSDs are moved between computers, consider disabling or lowering the GLPI import rule:

```text
Computer update (by name)
```

Otherwise GLPI may still update the old asset by hostname.


## Install behavior

During package installation or upgrade, `glpi-additional-oem` comments old active
`additional-content = ...` directives found in GLPI Agent configuration files,
except the new managed target:

```text
/run/glpi-agent/additional-content.json
```

Changed files are backed up with suffix:

```text
.glpi-additional-oem.bak-YYYYMMDD-HHMMSS
```

Manual check:

```bash
sudo /usr/lib/glpi-agent/glpi-additional-oem-disable-old --dry-run --debug
```

Since 0.1.3, the systemd drop-in runs the generator with `--only-if-enabled`:

```ini
ExecStartPre=/usr/lib/glpi-agent/glpi-additional-oem --only-if-enabled
```

This means the runtime JSON is generated only when GLPI Agent has an active line:

```ini
additional-content = /run/glpi-agent/additional-content.json
```

If the line is commented, the pre-start helper exits successfully and does nothing:

```ini
# additional-content = /run/glpi-agent/additional-content.json
```

## Manual install

```bash
sudo ./scripts/install-manual.sh
sudo /usr/lib/glpi-agent/glpi-additional-oem --dry-run --debug
sudo systemctl restart glpi-agent
cat /run/glpi-agent/additional-content.json
```

To install and restart agent immediately:

```bash
sudo ./scripts/install-manual.sh --restart-agent
```

## Configuration files

```text
/etc/glpi-additional-oem/bad-uuids.list
/etc/glpi-additional-oem/bad-values.list
```

### bad-uuids.list

One UUID per line:

```text
00000000-0000-0000-0000-000000000000
ffffffff-ffff-ffff-ffff-ffffffffffff
03000200-0400-0500-0006-000700080009
```

### bad-values.list

Supports these formats:

```text
value
field=value
/regex/
field:/regex/
```

Examples:

```text
Default string
product_serial=Default string
board_serial=/^0+$/
product_serial:/^serial number$/
```

Known fields:

```text
sys_vendor
product_name
product_serial
product_uuid
board_vendor
board_name
board_serial
```

## Arch package

Use files in:

```text
packaging/arch/
```

## RPM / ClearOS package

Use:

```text
packaging/rpm/glpi-additional-oem.spec
```

## Paths

```text
/usr/lib/glpi-agent/glpi-additional-oem
/etc/glpi-agent/conf.d/20-additional-oem.cfg
/etc/glpi-additional-oem/bad-uuids.list
/etc/glpi-additional-oem/bad-values.list
/usr/lib/systemd/system/glpi-agent.service.d/10-additional-oem.conf
/run/glpi-agent/additional-content.json
```

### Build RPM

```bash
./packaging/rpm/build-rpm.sh
```

For source RPM only:

```bash
./packaging/rpm/build-rpm.sh --srpm
```
