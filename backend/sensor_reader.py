"""
Raspberry Pi 5 — Dual RS485 Sensor Reader
==========================================
Sensors (both on same RS485 bus via USB adapter):
  • NPK sensor        — Modbus address 0x01, registers 0x0000–0x0002
  • 4-in-1 sensor     — Modbus address 0x02, registers 0x0000–0x0003
      reg 0: moisture (×0.1 %)
      reg 1: temperature (×0.1 °C)
      reg 2: EC (×10 µS/cm)
      reg 3: pH (×10)

Usage:
    python sensor_reader.py                        # read once, print JSON
    python sensor_reader.py --interval 30          # poll every 30 s
    python sensor_reader.py --host http://localhost:8000  # post to API
"""
from __future__ import annotations
import argparse
import json
import time
import struct
import serial
import requests
from datetime import datetime, timezone


# ── RS485 / Modbus helpers ────────────────────────────────────────────────────

def _crc16(data: bytes) -> int:
    crc = 0xFFFF
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if crc & 1 else crc >> 1
    return crc


def _build_request(address: int, register: int, count: int) -> bytes:
    msg = struct.pack(">BBHH", address, 0x03, register, count)
    crc = _crc16(msg)
    return msg + struct.pack("<H", crc)


def _read_registers(port: serial.Serial, address: int, register: int, count: int) -> list[int]:
    port.reset_input_buffer()
    port.write(_build_request(address, register, count))
    time.sleep(0.1)
    expected = 5 + count * 2          # addr + fn + len + data + 2 CRC
    raw = port.read(expected)
    if len(raw) < expected:
        raise IOError(f"Short response from addr 0x{address:02X}: got {len(raw)}, want {expected}")
    # Verify CRC
    calc = _crc16(raw[:-2])
    recv = struct.unpack_from("<H", raw, len(raw) - 2)[0]
    if calc != recv:
        raise IOError(f"CRC mismatch from addr 0x{address:02X}")
    values = []
    for i in range(count):
        values.append(struct.unpack_from(">H", raw, 3 + i * 2)[0])
    return values


# ── Sensor read functions ─────────────────────────────────────────────────────

NPK_ADDR     = 0x01
QUAD_ADDR    = 0x02


def read_npk(port: serial.Serial) -> dict:
    """Read N, P, K in mg/kg (ppm) from NPK sensor."""
    regs = _read_registers(port, NPK_ADDR, 0x0000, 3)
    return {
        "n": regs[0],   # mg/kg (ppm)
        "p": regs[1],
        "k": regs[2],
    }


def read_4in1(port: serial.Serial) -> dict:
    """Read moisture, temperature, EC, pH from 4-in-1 sensor."""
    regs = _read_registers(port, QUAD_ADDR, 0x0000, 4)
    return {
        "moisture":    regs[0] * 0.1,   # %
        "temperature": regs[1] * 0.1,   # °C
        "ec":          regs[2] * 0.01,  # mS/cm  (raw is µS/cm ÷ 100)
        "ph":          regs[3] * 0.1,   # pH units
    }


def read_all(port: serial.Serial) -> dict:
    """Read all sensors and combine into one payload."""
    npk  = read_npk(port)
    quad = read_4in1(port)
    return {
        **npk,
        **quad,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "source": "hardware",
    }


# ── Post to FastAPI ───────────────────────────────────────────────────────────

def post_reading(host: str, farm_id: str, data: dict) -> dict:
    url = f"{host}/sensor/reading"
    resp = requests.post(url, json={"farm_id": farm_id, **data}, timeout=10)
    resp.raise_for_status()
    return resp.json()


# ── CLI entry point ───────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="CROP+ sensor reader")
    parser.add_argument("--port",     default="/dev/ttyUSB0", help="Serial port")
    parser.add_argument("--baud",     default=9600,  type=int)
    parser.add_argument("--farm-id",  default="demo-farm-1")
    parser.add_argument("--host",     default="http://localhost:8000",
                        help="FastAPI base URL (omit to print only)")
    parser.add_argument("--interval", default=0, type=int,
                        help="Poll interval in seconds (0 = read once)")
    args = parser.parse_args()

    with serial.Serial(args.port, args.baud, timeout=1) as port:
        while True:
            try:
                data = read_all(port)
                print(json.dumps(data, indent=2))
                if args.host:
                    result = post_reading(args.host, args.farm_id, data)
                    print("→ API response:", json.dumps(result, indent=2))
            except Exception as e:
                print(f"[ERROR] {e}")

            if args.interval <= 0:
                break
            time.sleep(args.interval)


if __name__ == "__main__":
    main()
