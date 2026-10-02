#!/usr/bin/env python3
"""i3status-rust block: ZMK split keyboard (urchin) half battery levels.

Reads the Battery Service (0x2A19) characteristics exposed by a ZMK split
keyboard over Bluetooth. The central half reports its own level, and ZMK's
`central_bas_proxy.c` adds one auxiliary level per peripheral, tagged with a
Characteristic User Description (0x2901) of "Peripheral N".

Hosts such as upower/BlueZ only surface a single battery per device, so this
script reads the characteristics directly and prints both halves as i3status
JSON.
"""

import argparse
import json
import sys

try:
    import gi

    gi.require_version("Gio", "2.0")
    from gi.repository import Gio, GLib
except (ImportError, ValueError):
    print(json.dumps({"text": ""}))
    sys.exit(0)

BLUEZ = "org.bluez"
BATTERY_UUID = "00002a19-0000-1000-8000-00805f9b34fb"
CUD_UUID = "00002901-0000-1000-8000-00805f9b34fb"

LOW_THRESHOLD = 15
WARN_THRESHOLD = 30


def emit(text, state="Idle"):
    print(json.dumps({"icon": "keyboard", "state": state, "text": text}))


def get_managed_objects(bus):
    reply = bus.call_sync(
        BLUEZ,
        "/",
        "org.freedesktop.DBus.ObjectManager",
        "GetManagedObjects",
        None,
        GLib.VariantType("(a{oa{sa{sv}}})"),
        Gio.DBusCallFlags.NONE,
        -1,
        None,
    )
    return reply.unpack()[0]


def read_value(bus, path, interface):
    reply = bus.call_sync(
        BLUEZ,
        path,
        interface,
        "ReadValue",
        GLib.Variant("(a{sv})", ({},)),
        GLib.VariantType("(ay)"),
        Gio.DBusCallFlags.NONE,
        -1,
        None,
    )
    return bytes(reply.unpack()[0])


def device_matches(objs, device_path, name_filter):
    if not name_filter:
        return True
    props = objs.get(device_path, {}).get("org.bluez.Device1", {})
    return name_filter in {props.get("Alias", ""), props.get("Name", "")}


def device_connected(objs, device_path):
    props = objs.get(device_path, {}).get("org.bluez.Device1")
    if props is None:
        return False
    return bool(props.get("Connected", False))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--device",
        help="Bluetooth device alias/name to read (default: any connected ZMK keyboard)",
    )
    args = parser.parse_args()

    try:
        bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        objs = get_managed_objects(bus)
    except Exception:
        emit("")
        return

    service_device = {}
    for path, ifaces in objs.items():
        service = ifaces.get("org.bluez.GattService1")
        if service:
            service_device[path] = service.get("Device")

    cud_by_char = {}
    for path, ifaces in objs.items():
        desc = ifaces.get("org.bluez.GattDescriptor1")
        if desc and desc.get("UUID", "").lower() == CUD_UUID:
            cud_by_char[desc.get("Characteristic")] = path

    levels = {}
    for path, ifaces in objs.items():
        char = ifaces.get("org.bluez.GattCharacteristic1")
        if not char or char.get("UUID", "").lower() != BATTERY_UUID:
            continue

        device_path = service_device.get(char.get("Service"))
        if device_path is None or not device_connected(objs, device_path):
            continue
        if not device_matches(objs, device_path, args.device):
            continue

        try:
            label = ""
            cud_path = cud_by_char.get(path)
            if cud_path:
                label = read_value(bus, cud_path, "org.bluez.GattDescriptor1").decode(
                    errors="replace"
                )
            value = read_value(bus, path, "org.bluez.GattCharacteristic1")
        except Exception:
            continue

        if not value:
            continue

        role = "peripheral" if label.startswith("Peripheral") else "central"
        levels[role] = value[0]

    if not levels:
        emit("")
        return

    parts = []
    if "central" in levels:
        parts.append("L {}%".format(levels["central"]))
    if "peripheral" in levels:
        parts.append("R {}%".format(levels["peripheral"]))

    worst = min(levels.values())
    if worst < LOW_THRESHOLD:
        state = "Critical"
    elif worst < WARN_THRESHOLD:
        state = "Warning"
    else:
        state = "Good"

    emit(" ".join(parts), state)


if __name__ == "__main__":
    main()
