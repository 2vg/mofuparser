# mofuparser

> hyper minimal ultra fast http parser.

### why fast ?

this parser is a nim implementation of something like [picohttpparser](https://github.com/h2o/picohttpparser), and [httparse](https://github.com/seanmonstar/httparse).

so, what this parser does is simply return the pointer and length of what you need from the passed in request char[].

~~but not support SIMD yet.~~

new version using SIMD 🚀.

1.5 times faster !!!

Please look at how to usage at the bottom.

### Feature
- zero copy, so **fast**
- Accurate error check, so **safety**
- [x] HTTP request parse
- [ ] HTTP response parse
- [x] HTTP chunk decord

and, mofuparser internally stores information about headers in an array of length 64.

it is possible to change the length of the array at compile time, and specify it like this.

`-d:headerSize:128`

### API

- `mpParseRquest(mhr: MPHTTPReq, req: ptr char, reqLen: int): int`

parse http request from client.

returns the length up to the end of the request's header.

the request body can be obtained with the returned length.

- `mpParseChunk(mc: MPChunk, buf: ptr char, bSize: var int): int`

Parsing chunked of Transfer-Encoding.

If it ends in the middle, -2 is returned.

bSize must be a variable that can be changed.

bSize is changed to the length of data after chunk is decoded.

### Require

- nim (tested 0.17.2)

### Todo

- [ ] http request body parse
- [ ] http response parse support
- [x] http chunk decord support
- [ ] http/2.0 support
- [x] all method support
- [ ] multibyte support
- [ ] multiline support
- [x] make something like httpobject(?) to make quantity of more less cords
- [ ] more bad request parse

### test

`nim c -r mofuparser`

### Usage

```nim
import mofuparser, times

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
```
