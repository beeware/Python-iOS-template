# Python writes all console output to stdout/stderr. However, in production,
# iOS devices don't record stdout/stderr; only the Apple System Log is preserved.
#
# This handler redirects sys.stdout and sys.stderr to the Apple System Log
# by creating a wrapper around NSLog, and monkeypatching that wrapper over
# sys.stdout and sys.stderr

import ctypes
import io
import platform
import struct
import sys


# Name of the UTF-16 encoding with the system byte order.
if sys.byteorder == 'little':
    UTF16_NATIVE = 'utf-16-le'
elif sys.byteorder == 'big':
    UTF16_NATIVE = 'utf-16-be'
else:
    raise AssertionError('Unknown byte order: ' + sys.byteorder)


class CFTypeRef(ctypes.c_void_p):
    pass

CFIndex = ctypes.c_long
UniChar = ctypes.c_uint16

CoreFoundation = ctypes.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
Foundation = ctypes.CDLL('/System/Library/Frameworks/Foundation.framework/Foundation')

# void CFRelease(CFTypeRef arg)
CoreFoundation.CFRelease.restype = None
CoreFoundation.CFRelease.argtypes = [CFTypeRef]

# CFStringRef CFStringCreateWithCharacters(CFAllocatorRef alloc, const UniChar *chars, CFIndex numChars)
CoreFoundation.CFStringCreateWithCharacters.restype = CFTypeRef
CoreFoundation.CFStringCreateWithCharacters.argtypes = [CFTypeRef, ctypes.POINTER(UniChar), CFIndex]

# void NSLog(NSString *format, ...)
Foundation.NSLog.restype = None
Foundation.NSLog.argtypes = [CFTypeRef]


def _cfstr(s):
    """Create a ``CFString`` from the given Python :class:`str`."""
    encoded = s.encode(UTF16_NATIVE)
    assert len(encoded) % 2 == 0
    arr = (UniChar * (len(encoded)//2)).from_buffer_copy(encoded)
    cfstring = CoreFoundation.CFStringCreateWithCharacters(None, arr, len(arr))
    assert cfstring is not None
    return cfstring


# Format string for a single object.
FORMAT = _cfstr('%@')


def nslog(s):
    """Log the given Python :class:`str` to the system log."""
    cfstring = _cfstr(s)
    Foundation.NSLog(FORMAT, cfstring)
    CoreFoundation.CFRelease(cfstring)


class NSLogWriter(io.TextIOBase):
    """An output-only text stream that writes to the system log."""
    def write(self, s):
        if not hasattr(self, 'buf'):
            self.buf = s
        else:
            self.buf += s

        lines = self.buf.split('\n')
        for line in lines[:-1]:
            nslog(line)
        self.buf = lines[-1]
        return len(s)

    @property
    def encoding(self):
        return UTF16_NATIVE


# Replace stdout and stderr with a single NSLogWriter
sys.stdout = sys.stderr = NSLogWriter()
