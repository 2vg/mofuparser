# mofuparser
> hyper minimal ultra fast http parser.
### why fast ?
this parser is a nim implementation of something like [picohttpparser](https://github.com/h2o/picohttpparser).

so, what this parser does is simply return the pointer and length of what you need from the passed in request char[].

~~but not support SIMD yet.~~

new version using SIMD 🚀.

1.5 time faster !!!

Please look at how to usage at the bottom.

### Feature
- [x] HTTP request parse
- [ ] HTTP response parse
- [x] HTTP chunk decord

and, mofuparser internally stores information about headers in an array of length 64.

it is possible to change the length of the array at compile time, and specify it like this.

`-d:headerSize:128`

### argument
- `mpParseRquest(req: string, mhr: MPHTTPReq): int`

parse http request from client.

returns the length up to the end of the request's header.

the request body can be obtained with the returned length.

### Require
- nim (tested 0.17.2)

### Import
- mofuparser

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

var 
  test = "GET /test HTTP/1.1\r\LHost: 127.0.0.1:8080\r\LConnection: keep-alive\r\LCache-Control: max-age=0\r\LAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\LUser-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.56 Safari/537.17\r\LAccept-Encoding: gzip,deflate,sdch\r\LAccept-Language: en-US,en;q=0.8\r\LAccept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3\r\LCookie: name=mofuparser\r\L\r\Ltest=hoge"

  mpr = MPHTTPReq()

# for benchmark (?) lol
let old = cpuTime()
for i in 0 .. 100000:
  discard mpParseRequest(test[0].addr, mpr)
echo cpuTime() - old

if mpParseRequest(test[0].addr, mpr) > 0:
  echo mpr.getMethod
  echo mpr.getPath
  echo ($(mpr.minor))[0]
  for name, value in mpr.headersPair:
    echo "name: " & name & " | value: " & value
else:
  echo "invalid request."
```
