import sys
import json
from struct import pack, unpack


def _read_data(length):
    data = b''
    while len(data) != length:
        try:
            buf = sys.stdin.buffer.read(length)
        except IOError as e:
            if e.errno == sys.stderr.EPIPE:
                raise EOFError('read error, EPIPE')
            raise IOError('read error, io error')
        if not buf:
            raise EOFError('read error, buffer')
        data += buf
        return data


def read_message(PACKET_BYTES=4, PACKET_FORMAT=">i"):

    bytes_length = _read_data(PACKET_BYTES)
    length = unpack(PACKET_FORMAT, bytes_length)[0]
    json_message = _read_data(length)
    return json.loads(json_message)


def write_answer(answer, PACKET_BYTES=4, PACKET_FORMAT=">i"):
    data = json.dumps(answer).encode()
    packet = pack(PACKET_FORMAT, len(data)) + data
    # raise Exception(packet)
    sys.stdout.buffer.write(packet)
    sys.stdout.buffer.flush()
    # raise Exception("mandado")
