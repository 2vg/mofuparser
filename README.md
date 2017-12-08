# mofuparser
> hyper minimal ultra fast http parser.
### why fast ?
this parser is a nim implementation of something like [picohttpparser](https://github.com/h2o/picohttpparser)

so, what this parser does is simply return the pointer and length of what you need from the passed in request char[]

Please look at how to usage at the bottom
### Future
- HTTP request parse
- HTTP response parse(not yet)
- HTTP chunk decord (not yet)

`mp_req()` only now.

### need argments
- `req: ptr char`
- `reqMethod: var ptr char`
- `reqMethodLength: var int`
- `reqPath: var ptr char`
- `reqPathLength: var int`
- `minorVersion: var ptr char`
- `header: var ptr T(※array[n, headers])`
- `headerLength: var int`
### Require
- nim (tested 0.17.2)
### Import
- mofuparser

### Todo
- [ ] http request body parse
- [ ] http response parse support
- [ ] http chunk decord support
- [ ] http/2.0 support
- [x] ~~all method support~~
- [ ] multibyte support
- [ ] multiline support
- [ ] more bad request parse
### test
`nim c -r mofuparser`
### Usage
```nim
import mofuparser, times

# GET /test HTTP/1.1\r\L\r\L
var 
  test = "GET /test HTTP/1.1\r\LHost: 127.0.0.1:8080\r\LConnection: keep-alive\r\LCache-Control: max-age=0\r\LAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\LUser-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.56 Safari/537.17\r\LAccept-Encoding: gzip,deflate,sdch\r\LAccept-Language: en-US,en;q=0.8\r\LAccept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\LCookie: name=mofuparser\r\L\r\L"
  # reqMethod, reqPath, minorVersion
  rm, rp, mnv: ptr char

  # reqMethodLength, reqPathLength, header length
  rml, rpl, hdl: int

  # headers
  hd     : array[64, headers]
  hdaddr = hd.addr

# for benchmark (?) lol
var old = epochTime()
for i in 0 .. 100000:
  discard mp_req(test[0].addr, rm, rml, rp, rpl, mnv, hdaddr, hdl)
echo epochTime() - old

proc print(value: string, length: int) =
  echo value[0 .. length]

if mp_req(test[0].addr, rm, rml, rp, rpl, mnv, hdaddr, hdl) == 0:
  print($rm, rml) # GET
  print($rp, rpl) # /test
  print($mnv, 0)  # 1
  for i in 0 .. hdl - 1:
    # header
    print($(hd[i].name), hd[i].namelen)
    print($(hd[i].value), hd[i].valuelen)
else:
  echo "invalid request."
```