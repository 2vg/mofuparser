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
  print($rp, rpl) # /test
  print($mnv, 0)  # 1
  for i in 0 .. hdl - 1:
    # header
    print($(hd[i].name), hd[i].namelen)
    print($(hd[i].value), hd[i].valuelen)
else:
  echo "invalid request."
```