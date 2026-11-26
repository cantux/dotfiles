import lzma
import struct
import sys
import zlib

OFFSET_TABLE_ID = b'rDlPtS\xcd\xe6\xd7{\x0b*'
OFFSET_TABLE_FIELDS = '<IIIIIIII'
OFFSET_TABLE_CRC_SPAN = 12 + 4 * 7
BLOCK_HEADER_SIZE = 9
CHUNK_SIZE = 4096
SEARCH_DISTANCE = 64


def crc32(data):
  return zlib.crc32(data) & 0xFFFFFFFF


def find_offset_table(data):
  position = data.find(OFFSET_TABLE_ID)
  while position >= 0:
    fields = struct.unpack_from(OFFSET_TABLE_FIELDS, data, position + 12)
    table_crc = fields[7]
    if crc32(data[position:position + OFFSET_TABLE_CRC_SPAN]) == table_crc:
      return position, list(fields)
    position = data.find(OFFSET_TABLE_ID, position + 1)
  return -1, None


def read_block(data, position):
  if position < 0 or position + BLOCK_HEADER_SIZE > len(data):
    return None
  header_crc = struct.unpack_from('<I', data, position)[0]
  header = data[position + 4:position + BLOCK_HEADER_SIZE]
  if crc32(header) != header_crc:
    return None
  stored_size, compressed = struct.unpack('<IB', header)
  cursor = position + BLOCK_HEADER_SIZE
  end = cursor + stored_size
  if end > len(data):
    return None
  payload = bytearray()
  while cursor < end:
    chunk_crc = struct.unpack_from('<I', data, cursor)[0]
    chunk_length = min(CHUNK_SIZE, end - cursor - 4)
    chunk = data[cursor + 4:cursor + 4 + chunk_length]
    if crc32(chunk) != chunk_crc:
      return None
    payload += chunk
    cursor += 4 + chunk_length
  return bytes(payload), compressed, end


def untransform_call_instructions(buffer):
  size = len(buffer) - 4
  index = 0
  while index < size:
    if buffer[index] not in (0xE8, 0xE9):
      index += 1
      continue
    index += 1
    if buffer[index + 3] in (0x00, 0xFF):
      address = (index + 4) & 0xFFFFFF
      relative = (buffer[index] | (buffer[index + 1] << 8) |
                  (buffer[index + 2] << 16))
      relative = (relative - address) & 0xFFFFFFFF
      if relative & 0x800000:
        buffer[index + 3] ^= 0xFF
      buffer[index] = relative & 0xFF
      buffer[index + 1] = (relative >> 8) & 0xFF
      buffer[index + 2] = (relative >> 16) & 0xFF
    index += 4


def decode_engine(payload, compressed, uncompressed_size):
  if not compressed:
    engine = bytearray(payload[:uncompressed_size])
  else:
    properties = payload[0]
    lzma_filter = {
        'id': lzma.FILTER_LZMA1,
        'dict_size': struct.unpack_from('<I', payload, 1)[0],
        'lc': properties % 9,
        'lp': (properties // 9) % 5,
        'pb': properties // 45,
    }
    decompressor = lzma.LZMADecompressor(format=lzma.FORMAT_RAW,
                                         filters=[lzma_filter])
    engine = bytearray(
        decompressor.decompress(payload[5:], max_length=uncompressed_size))
  untransform_call_instructions(engine)
  return engine


def find_engine(data, offset_exe, uncompressed_size, crc_exe):
  for distance in range(SEARCH_DISTANCE + 1):
    for candidate in sorted({offset_exe - distance, offset_exe + distance}):
      block = read_block(data, candidate)
      if block is None:
        continue
      payload, compressed, end = block
      engine = decode_engine(payload, compressed, uncompressed_size)
      if len(engine) == uncompressed_size and crc32(engine) == crc_exe:
        return candidate, end
  return -1, -1


def main(arguments):
  if len(arguments) != 3:
    print('usage: repair_inno_offsets.py <installer.exe> <output.exe>',
          file=sys.stderr)
    return 2
  input_path, output_path = arguments[1], arguments[2]
  with open(input_path, 'rb') as input_file:
    data = bytearray(input_file.read())
  table_position, fields = find_offset_table(data)
  if table_position < 0:
    print('no Inno Setup loader offset table with a valid CRC',
          file=sys.stderr)
    return 1
  total_size, offset_exe, uncompressed_size, crc_exe = fields[1:5]
  print(f'file_size={len(data)} total_size={total_size} '
        f'offset_exe={offset_exe}')
  engine_offset, engine_end = find_engine(data, offset_exe, uncompressed_size,
                                          crc_exe)
  if engine_offset < 0:
    print(
        'setup.e32: no block within the search distance passes the CRC '
        'checks',
        file=sys.stderr)
    return 1
  if engine_offset == offset_exe and total_size <= len(data):
    print('consistent: setup.e32 passes at the recorded offset')
  else:
    fields[1] = engine_end
    fields[2] = engine_offset
    struct.pack_into(OFFSET_TABLE_FIELDS, data, table_position + 12, *fields)
    fields[7] = crc32(data[table_position:table_position +
                           OFFSET_TABLE_CRC_SPAN])
    struct.pack_into(OFFSET_TABLE_FIELDS, data, table_position + 12, *fields)
    print(f'repaired: offset_exe {offset_exe} -> {engine_offset}, '
          f'total_size {total_size} -> {engine_end}')
  with open(output_path, 'wb') as output_file:
    output_file.write(data)
  print(f'written: {output_path}')
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
