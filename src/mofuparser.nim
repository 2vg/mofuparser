import macros, bitops, httpcore

macro getCPU: untyped =
  let CPU = staticExec(
    "nim c -r --hints:off --verbosity:0 private/SIMD/getCPU")

  if CPU == "SSE41\n" or CPU == "SSE41\n":
    return quote do:
      import private/SIMD/[x86_sse2, x86_sse3, x86_ssse3]
      proc fastURLMatch(buf: ptr char): int =
        let LSH = set1_epi8(0x0F'i8)
        let URI = setr_epi8(
          0xb8'i8, 0xfc'i8, 0xf8'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8,
          0xfc'i8, 0xfc'i8, 0xfc'i8, 0x7c'i8, 0x54'i8, 0x7c'i8, 0xd4'i8, 0x7c'i8,
        )
        let ARF = setr_epi8(
          0x01'i8, 0x02'i8, 0x04'i8, 0x08'i8, 0x10'i8, 0x20'i8, 0x40'i8, 0x80'i8,
          0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8,
        )
        let data = lddqu_si128(cast[ptr m128i](buf))
        let rbms = shuffle_epi8(URI, data)
        let cols = and_si128(LSH, srli_epi16(data, 4))
        let bits = and_si128(shuffle_epi8(ARF, cols), rbms)
        let v = cmpeq_epi8(bits, setzero_si128())
        let r = 0xffff_0000 or movemask_epi8(v)
        return countTrailingZeroBits(r)
      proc fastHeaderMatch(buf: ptr char): int =
        let TAB = set1_epi8(0x09)
        let DEL = set1_epi8(0x7f)
        let LOW = set1_epi8(0x1f)
        let dat = lddqu_si128(cast[ptr m128i](buf))
        let low = cmpgt_epi8(dat, LOW)
        let tab = cmpeq_epi8(dat, TAB)
        let del = cmpeq_epi8(dat, DEL)
        let bit = andnot_si128(del, or_si128(low, tab))
        let rev = cmpeq_epi8(bit, setzero_si128())
        let res = 0xffff_0000 or movemask_epi8(rev)
        return countTrailingZeroBits(res)
      proc urlVector*(buf: var ptr char, bufLen: var int) =
        while bufLen >= 16:
          let ret = fastURLMatch(buf)
          buf += ret
          bufLen -= ret
          if ret != 16: break
      proc headerVector*(buf: var ptr char, bufLen: var int) =
        while bufLen >= 16:
          let ret = fastHeaderMatch(buf)
          buf += ret
          bufLen -= ret
          if ret != 16: break
  elif CPU == "AVX2\n" or CPU == "AVX2":
    return quote do:
      import private/SIMD/[x86_avx, x86_avx2, x86_ssse3]
      proc fastURLMatch(buf: ptr char): int =
        let LSH = set1_epi8(0x0F'i8)
        let URI = setr_epi8(
          0xb8'i8, 0xfc'i8, 0xf8'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8,
          0xfc'i8, 0xfc'i8, 0xfc'i8, 0x7c'i8, 0x54'i8, 0x7c'i8, 0xd4'i8, 0x7c'i8,
          0xb8'i8, 0xfc'i8, 0xf8'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8, 0xfc'i8,
          0xfc'i8, 0xfc'i8, 0xfc'i8, 0x7c'i8, 0x54'i8, 0x7c'i8, 0xd4'i8, 0x7c'i8,
        )
        let ARF = setr_epi8(
          0x01'i8, 0x02'i8, 0x04'i8, 0x08'i8, 0x10'i8, 0x20'i8, 0x40'i8, 0x80'i8,
          0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8,
          0x01'i8, 0x02'i8, 0x04'i8, 0x08'i8, 0x10'i8, 0x20'i8, 0x40'i8, 0x80'i8,
          0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8, 0x00'i8,
        )
        let data = lddqu_si256(cast[ptr m256i](buf))
        let rbms = shuffle_epi8(URI, data)
        let cols = and_si256(LSH, srli_epi16(data, 4))
        let bits = and_si256(shuffle_epi8(ARF, cols), rbms)
        let v = cmpeq_epi8(bits, setzero_si256())
        let r = 0xffff_0000 or movemask_epi8(v)
        return countTrailingZeroBits(r)
      proc fastHeaderMatch(buf: ptr char): int =
        let TAB = set1_epi8(0x09)
        let DEL = set1_epi8(0x7f)
        let LOW = set1_epi8(0x1f)
        let dat = lddqu_si256(cast[ptr m256i](buf))
        let low = cmpgt_epi8(dat, LOW)
        let tab = cmpeq_epi8(dat, TAB)
        let del = cmpeq_epi8(dat, DEL)
        let bit = andnot_si256(del, or_si256(low, tab))
        let rev = cmpeq_epi8(bit, setzero_si256())
        let res = 0xffff_0000 or movemask_epi8(rev)
        return countTrailingZeroBits(res)
      proc urlVector(buf: var ptr char, bufLen: var int) =
        while bufLen >= 32:
          let ret = fastURLMatch(buf)
          buf += ret
          bufLen -= ret
          if ret != 32: break
      proc headerVector(buf: var ptr char, bufLen: var int) =
        while bufLen >= 32:
          let ret = fastHeaderMatch(buf)
          buf += ret
          bufLen -= ret
          if ret != 32: break
  else:
    return quote do:
      proc urlVector(buf: var ptr char, bufLen: var int) =
        discard
      proc headerVector(buf: var ptr char, bufLen: var int) =
        discard

const URI_TOKEN = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1,
  0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0,
  # ====== Extended ASCII (aka. obs-text) ======
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
]

const HEADER_NAME_TOKEN = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
  0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
]

const HEADER_VALUE_TOKEN = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
]

const headerSize {.intdefine.} = 64

type
  MPHTTPReq* = ref object
    httpMethod*, path*, minor*: ptr char
    httpMethodLen*, pathLen*, headerLen*: int
    headers*: array[headerSize, MPHeader]

  MPHeader* = object
    name*, value: ptr char
    nameLen*, valueLen*: int

  MPChunk* = ref object
    state: ChunkState
    byteLeftChunk, hexCount, consume: int

  ChunkState = enum
    size,
    ext,
    data,
    crlf,
    head,
    middle

template `+`[T](p: ptr T, off: int): ptr T =
    cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

template `+=`[T](p: ptr T, off: int) =
  p = p + off

template `-`[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) -% off * sizeof(p[]))

template `-`[T](p: ptr T, p2: ptr T): int =
  cast[int](p) - cast[int](p2)

template `-=`[T](p: ptr T, off: int) =
  p = p - off

template `[]`[T](p: ptr T, off: int): T =
  (p + off)[]

template `[]=`[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val

getCPU()

proc mpParseHeader(headers: var array[headerSize, MPHeader], buf: var ptr char, bufLen: int): int =
  var bufStart = buf
  var hdrLen = 0

  while true:
    case buf[]:
      of '\0':
        return -1

      of '\r':
        buf += 1
        if buf[] != '\l': return -1
        buf += 1
        if buf[] == '\r':
          buf += 1
          if buf[] == '\l':
            break

      of '\l':
        buf += 1
        if buf[] == '\l':
          break

      else:
        # HEADER NAME CHECK
        if not HEADER_NAME_TOKEN[buf[].int].bool: return -1
        var start = buf
        var bufEnd = buf
        while true:
          if buf[] == ':':
            bufEnd = buf - 1
            buf += 1
            # skip whitespace
            while true:
              if buf[] == ' ' or buf[] == '\t':
                buf += 1
                break
            break
          else:
            if not HEADER_NAME_TOKEN[buf[].int].bool: return -1
          buf += 1

        headers[hdrLen].name = start
        headers[hdrLen].nameLen = bufEnd - start

        # HEADER VALUE CHECK
        var bufLen = bufLen - (buf - bufStart)
        start = buf
        echo "befor: ", bufLen
        headerVector(buf, bufLen)
        echo "after: ", bufLen
        while true:
          if buf[] == '\r' or buf[] == '\l':
            break
          else:
            if not HEADER_VALUE_TOKEN[buf[].int].bool:
              return -1
          buf += 1

        headers[hdrLen].value = start
        headers[hdrLen].valueLen = buf - start - 1

        hdrLen.inc()

  return hdrLen

proc mpParseRequest*(mhr: MPHTTPReq, req: ptr char, reqLen: int): int =
  # argment initialization
  mhr.httpMethod = nil
  mhr.path = nil
  mhr.minor = nil
  mhr.httpMethodLen = 0
  mhr.pathLen = 0
  mhr.headerLen = 0

  var buf = req
  var bufLen = reqLen

  # METHOD CHECK
  var start = buf
  while true:
    if buf[] == ' ':
      # skip whitespace
      buf += 1
      break
    else:
      if not (buf[] > '\x1f' and buf[] < '\x7f'):
        return -1
    buf += 1

  mhr.httpMethod = start
  mhr.httpMethodLen = buf - start - 2

  # PATH CHECK
  start = buf
  bufLen = bufLen - (buf - req)
  echo bufLen
  urlVector(buf, bufLen)
  while true:
    if buf[] == ' ':
      # skip whitespace
      buf += 1
      break
    else:
      if not URI_TOKEN[buf[].int].bool:
        return -1
    buf += 1

  mhr.path = start
  mhr.pathLen = buf - start - 2

  # VERSION CHECK
  bufLen = bufLen - (buf - req)
  if bufLen <= 8: return -1

  if buf[] != 'H': return -1
  buf += 1
  if buf[] != 'T': return -1
  buf += 1
  if buf[] != 'T': return -1
  buf += 1
  if buf[] != 'P': return -1
  buf += 1
  if buf[] != '/': return -1
  buf += 1
  if buf[] != '1': return -1
  buf += 1
  if buf[] != '.': return -1
  buf += 1

  if buf[] == '0' or buf[] == '1':
    mhr.minor = buf
  else:
    return -1

  # skip version
  buf += 1

  # PARSE HEADER
  bufLen = bufLen - (buf - req)
  echo bufLen
  let hdrLen = mhr.headers.mpParseHeader(buf, bufLen)

  if hdrLen != -1:
    mhr.headerLen = hdrLen
  else:
    return -1

  return buf - req + 1

template decodeHex(ch: char): int =
  case ch
  of '0'..'9':
    ch.int - '0'.int
  of 'A'..'F':
    ch.int - 'A'.int + '\xa'.int
  of 'a'..'f':
    ch.int - 'a'.int + '\xa'.int
  else: -1

proc mpParseChunk*(mc: MPChunk, buf: ptr char, bSize: var int): int =
  var dest, src: int
  var bufSize = bSize
  var ret = -2

  template complete =
    ret = bufSize - src

  template chunkExit =
    if dest != src: moveMem(buf + dest, buf + src, bufSize - src)
    bSize = dest
    return ret

  while true:
    case mc.state
    of ChunkState.size:
      while true:
        var v: int
        if src == bufSize: chunkExit()

        if (v = decodeHex(buf[src]); v) == -1:
          if mc.hexCount == 0:
            ret = -1
            chunkExit()
          break

        if mc.hexCount == int.sizeof * 2:
          ret = -1
          chunkExit()

        mc.byteLeftChunk = mc.byteLeftChunk * 16 + v
        mc.hexCount.inc()
        src.inc()

      mc.hexCount = 0
      mc.state = ChunkState.ext

    of ChunkState.ext:
      while true:
        if src == bufSize: chunkExit()
        if buf[src] == '\10': break
        src.inc()
      src.inc()
      if mc.byteLeftChunk == 0:
        if mc.consume != 0: mc.state = ChunkState.head; break
        else: complete()
      mc.state = ChunkState.data

    of ChunkState.data:
      var avail = bufSize - src

      if avail < mc.byteLeftChunk:
        if dest != src: moveMem(buf + dest, buf + src, avail)
        src += avail
        dest += avail
        mc.byteLeftChunk -= avail
        chunkExit()

      if dest != src: moveMem(buf + dest, buf + src, mc.byteLeftChunk)

      src += mc.byteLeftChunk
      dest += mc.byteLeftChunk
      mc.byteLeftChunk = 0
      mc.state = ChunkState.crlf

    of ChunkState.crlf:
      while true:
        if src == bufSize: chunkExit()
        if buf[src] != '\13': break
        src.inc()

      if buf[src] != '\10': ret = -1; chunkExit()
      src.inc()
      mc.state = ChunkState.size

    of ChunkState.head:
      while true:
        if src == bufSize: chunkExit()
        if buf[src] != '\13': break
        src.inc()

      if buf[src+1] != '\10': complete()

      mc.state = ChunkState.middle

    of ChunkState.middle:
      while true:
        if src == bufSize: chunkExit()
        if buf[src] != '\10': break
        src.inc()

      src.inc()
      mc.state = ChunkState.head
    else: assert(false, "error")

  complete()
  chunkExit()

proc getMethod*(req: MPHTTPReq): string {.inline.} =
  result = ($(req.httpMethod))[0 .. req.httpMethodLen]

proc getPath*(req: MPHTTPReq): string {.inline.} =
  result = ($(req.path))[0 .. req.pathLen]

proc getHeader*(req: MPHTTPReq, name: string): string {.inline.} =
  for i in 0 ..< req.headerLen:
    if ($(req.headers[i].name))[0 .. req.headers[i].namelen] == name:
      result = ($(req.headers[i].value))[0 .. req.headers[i].valuelen]
      return
  result = ""

iterator headersPair*(req: MPHTTPReq): tuple[name, value: string] =
  for i in 0 ..< req.headerLen:
    yield (($(req.headers[i].name))[0 .. req.headers[i].namelen],
           ($(req.headers[i].value))[0 .. req.headers[i].valuelen])

proc toHttpHeaders*(mhr: MPHTTPReq): HttpHeaders =
  var hds: seq[tuple[key: string, val: string]] = @[]

  for hd in mhr.headersPair:
    hds.add((hd.name, hd.value))

  return hds.newHttpHeaders

when isMainModule:
  import times

  var buf =
    "GET /test HTTP/1.1\r\l" &
    "Host: 127.0.0.1:8080\r\l" &
    "Connection: keep-alive\r\l" &
    "Cache-Control: max-age=0\r\l" &
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\l" &
    "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) " &
      "AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.56 Safari/537.17\r\l" &
    "Accept-Encoding: gzip,deflate,sdch\r\l" &
    "Accept-Language: en-US,en;q=0.8\r\l" &
    "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\l" &
    "Cookie: name=mofuparser\r\l" &
    "\r\ltest=hoge"

  var mhreq = MPHTTPReq()

  let old = cpuTime()
  for i in 0 .. 100000:
    discard mhreq.mpParseRequest(addr buf[0], buf.len)
  echo cpuTime() - old

  discard mhreq.mpParseRequest(addr buf[0], buf.len)
  echo mhreq.getMethod()
  echo mhreq.getPath()
  for name, value in mhreq.headersPair:
    echo "name: " & name & "|value: " & value