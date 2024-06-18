#!/bin/python
# print with esc pos python library
# https://github.com/python-escpos/python-escpos/
# requires python-escpos library, install with
#  pip install python-escpos[usb]
# usage:
#  python printwescpos.py "file.jpeg" "message"

import sys
import inspect
from escpos.printer import Usb
from escpos.exceptions import USBNotFoundError, DeviceNotFoundError

if len(sys.argv) < 3:
  print("usage: python printwescpos.py 'file.jpeg' 'message...'")
  sys.exit(1)

try:
  p = Usb(0x0416, 0x5011, profile="ZJ-5870")
  p.image(sys.argv[1], impl="bitImageColumn")

  text = sys.argv[2]

  p.text("\n")
  p.text(text)
  p.text("\n\n\n\n")

  p.close()
except (USBNotFoundError, DeviceNotFoundError) as e:
  print("usb not found")
  sys.exit(14)
