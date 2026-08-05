#!/usr/bin/python3

import asyncio
import os
import subprocess
import tempfile
from pathlib import Path

from dbus_fast import BusType, Variant
from dbus_fast.aio import MessageBus
from dbus_fast.service import ServiceInterface, method


class FileChooser(ServiceInterface):
    def __init__(self, bus):
        super().__init__("org.freedesktop.impl.portal.FileChooser")
        self.bus = bus

    @staticmethod
    def directory_from_options(options):
        value = options.get("current_folder")
        if value is None:
            return str(Path.home())
        try:
            return bytes(value.value).decode() or str(Path.home())
        except (AttributeError, TypeError, UnicodeDecodeError):
            return str(Path.home())

    @method()
    async def OpenFile(self, handle: "o", app_id: "s", parent_window: "s", title: "s", options: "a{sv}") -> "ua{sv}":
        return await self.open_picker(title or "Open file", options, False)

    @method()
    async def SaveFile(self, handle: "o", app_id: "s", parent_window: "s", title: "s", options: "a{sv}") -> "ua{sv}":
        return await self.open_picker(title or "Save file", options, True)

    @method()
    async def SaveFiles(self, handle: "o", app_id: "s", parent_window: "s", title: "s", options: "a{sv}") -> "ua{sv}":
        return await self.open_picker(title or "Save files", options, True)

    async def open_picker(self, title, options, save_mode):
        selection_fd, selection_file = tempfile.mkstemp(prefix="fuzi-file-selection-")
        done_fd, done_file = tempfile.mkstemp(prefix="fuzi-file-done-")
        os.close(selection_fd)
        os.close(done_fd)
        os.unlink(done_file)

        subprocess.Popen([
            "/usr/bin/quickshell", "ipc", "call", "file-selector", "open",
            self.directory_from_options(options), title, selection_file, done_file,
        ])

        try:
            while not os.path.exists(done_file):
                await asyncio.sleep(0.1)

            selected = ""
            try:
                with open(selection_file, "r", encoding="utf-8") as stream:
                    selected = stream.readline().strip()
            except OSError:
                pass

            results = {}
            response = 0 if selected else 1
            if selected:
                results["uris"] = Variant("as", [Path(selected).resolve().as_uri()])
                if save_mode:
                    results["current_name"] = Variant("s", Path(selected).name)

            return response, results
        finally:
            for filename in (selection_file, done_file):
                try:
                    os.unlink(filename)
                except OSError:
                    pass


async def main():
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    await bus.request_name("org.freedesktop.impl.portal.desktop.fuzi")
    bus.export("/org/freedesktop/portal/desktop", FileChooser(bus))
    await asyncio.Event().wait()


if __name__ == "__main__":
    asyncio.run(main())
