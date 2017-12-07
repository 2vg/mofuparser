const token = [
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,true ,true ,true ,true ,true ,true ,true ,
  false,false,true ,true ,false,true ,true ,false,
  true ,true ,true ,true ,true ,true ,true ,true ,
  true ,true ,false,false,false,false,false,false,
  false,true ,true ,true ,true ,true ,true ,true ,
  true ,true ,true ,true ,true ,true ,true ,true ,
  true ,true ,true ,true ,true ,true ,true ,true ,
  true ,true ,true ,false,false,false,true ,true ,
  true ,true ,true ,true ,true ,true ,true ,true ,
  true ,true ,true ,true ,true ,true ,true ,true ,
  true ,true ,true ,true ,true ,true ,true ,true ,
  true ,true ,true ,false,true ,false,true ,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false,
  false,false,false,false,false,false,false,false
]

type
  headers*   = ref object
    name*    : ptr char
    namelen* : int
    value*   : ptr char
    valuelen*: int

proc mp_req*[T](req: ptr char,
                reqMethod: var ptr char, reqMethodLen: var int,
                reqPath: var ptr char, reqPathLen: var int,
                minorVersion: var ptr char,
                header: var ptr T, headerLen: var int): int =

  # argment initialization
  reqMethod    = nil
  reqPath      = nil
  minorVersion = nil
  reqMethodLen = 0
  reqPathLen   = 0
  headerLen    = 0
  
  # address of first char of request char[]
  var buf = cast[int](req)
  
  # need headers object into array
  var hdlen = 0

  # METHOD check
  var start = buf
  while true:
    let uchar = cast[ptr char](buf)[]
    # nil check
    if uchar == '\0':
      return -1
    # space chck
    elif uchar == '\32':
      buf += 1
      break
    # non printable check
    elif uchar < '\40' or uchar > '\177':
      return -1
    else:
      buf += 1

  reqMethod = cast[ptr char](start)
  reqMethodLen = buf - start - 2

  # PATH check
  start = buf
  while true:
    let uchar = cast[ptr char](buf)[]
    # nil check
    if uchar == '\0':
      return -1
    # space chck
    elif uchar == '\32':
      buf += 1
      break
    # non printable check
    elif uchar < '\40' or uchar > '\177':
      return -1
    else:
      buf += 1

  reqPath = cast[ptr char](start)
  reqPathLen = buf - start - 1

  # HTTP Version check
  # 'H' check
  if not(cast[ptr char](buf)[] == '\72'):
    return -1
  buf += 1

  # 'T' check
  if not(cast[ptr char](buf)[] == '\84'):
    return -1
  buf += 1

  # 'T' check
  if not(cast[ptr char](buf)[] == '\84'):
    return -1
  buf += 1

  # 'P' check
  if not(cast[ptr char](buf)[] == '\80'):
    return -1
  buf += 1

  # '/' check
  if not(cast[ptr char](buf)[] == '\47'):
    return -1
  buf += 1

  # '1' check
  if not(cast[ptr char](buf)[] == '\49'):
    return -1
  buf += 1

  # '.' check
  if not(cast[ptr char](buf)[] == '\46'):
    return -1
  buf += 1

  # numeric check
  if '\47' < cast[ptr char](buf)[] or cast[ptr char](buf)[] < '\58':
    minorVersion = cast[ptr char](buf)
  else:
    return -1

  buf += 1

  # HEADER check
  for i in 0 .. header[].len - 1:
    let uchar = cast[ptr char](buf)[]
    # nil check
    if uchar == '\0':
      return -1
    # CR check
    elif uchar == '\13':
      buf += 1
      # LF check
      if not(cast[ptr char](buf)[] == '\10'):
        return -1
      buf += 1
      # if second CR, request will end
      if cast[ptr char](buf)[] == '\13':
        buf += 1
        # if second LF check is true, request is end or next is body.
        if not(cast[ptr char](buf)[] == '\10'):
          return -1
        break
    # non space and non tab check
    elif not(uchar == '\32') and not(uchar == '\9'):
      # headers object
      var hd  = headers.new()
      # HEADER key check
      start = buf
      hd.name = cast[ptr char](start)

      while true:
        let uchar = cast[ptr char](buf)[]
        # nil check
        if uchar == '\0':
          return -1
        # space check
        elif uchar == '\32':
          return -1
        # colon check
        elif uchar == '\58':
          hd.namelen = buf - start - 1
          buf += 1
          if cast[ptr char](buf)[] == '\32':
            hd.namelen = buf - start - 2
            buf += 1
          break
        # token check
        elif not token[uchar.int]:
          return -1
        else:
          buf += 1

      # HEADER value check
      start = buf
      hd.value = cast[ptr char](start)

      while true:
        let uchar = cast[ptr char](buf)[]
        # nil check
        if uchar == '\0':
          return -1
        # non printable check
        elif (uchar < '\40') and not(uchar == '\11') or uchar == '\177':
          # if CR, header line will end
          if uchar == '\13':
            break
          if uchar == '\32':
            buf += 1
          if uchar == '\37':
            buf += 1
        else:
          buf += 1

      hd.valuelen = buf - start - 1
      header[hdlen] = hd
      hdlen += 1

  headerLen = hdlen
  return 0

# test
when isMainModule:
  import times
  # GET /test HTTP/1.1\r\L\r\L
  var 
    test = """GET / HTTP/1.1
Host: example.com
Connection: keep-alive
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1
Upgrade-Insecure-Requests: 1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
DNT: 1
Accept-Encoding: gzip, deflate, br
Accept-Language: ja,en-US;q=0.9,en;q=0.8
Cookie: wp-settings-1=foo%bar; wp-settings-time-1=123456789

"""
    # reqMethod, reqPath, minorVersion
    rm, rp, mnv: ptr char

    # reqMethodLength, reqPathLength, header length
    rml, rpl, hdl: int

    # headers
    hd     : array[64, headers]
    hdaddr = hd.addr

  # for benchmark (?) lol
  echo epochTime()
  for i in 0 .. 100000:
    discard mp_req(test[0].addr, rm, rml, rp, rpl, mnv, hdaddr, hdl)
  echo epochTime()

  proc print(value: string, length: int) =
    echo value[0 .. length]

  if mp_req(test[0].addr, rm, rml, rp, rpl, mnv, hdaddr, hdl) == 0:
    print($rm, rml) # GET
    print($rp, rpl) # /
    print($mnv, 0)  # 1
    for i in 0 .. hdl - 1:
      # header
      print($(hd[i].name), hd[i].namelen)
      print($(hd[i].value), hd[i].valuelen)
  else:
    echo "invalid request."