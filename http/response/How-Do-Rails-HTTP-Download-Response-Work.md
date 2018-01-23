# Rails 파일 다운로드 Response 분석

- Ruby On Rails가 파일 다운로드 Response를 어떻게 처리하는지에 대한 분석

## 필요지식

- Rails HTTP Structure
- 미들웨어 (Rack)
- 웹서버 (Nginx 등)
- Ruby File I/O 원리

### Rack Stack

- Rack의 여러 미들웨어들이 Rails에서 기본적으로 사용되고 있다. 이 중 파일 다운로드 Response와 관련된 것들을 알아보면

#### Rack::Sendfile

Rails Controller에서 클라이언트에 파일을 리턴하는 send_file 메서드는 실제로 Rack::Sendfile가 웹 서버로 하여금 파일을 전송하게 한다. Rails는 웹서버에게 파일의 path만 전달한다. 따라서 어플리케이션이 클라이언트에 파일을 전송하는 것보다 훨씬 더 빠르게 파일을 전송할 수 있다. (X-Sendfile 헤더를 이용함)

- [nginx X-Sendfile 헤더 참고 문서](https://www.nginx.com/resources/wiki/start/topics/examples/xsendfile/)

- [Rack::Sendfile 참고문서](http://www.rubydoc.info/github/rack/rack/master/Rack/Sendfile)

##### 웹서버가 정적 파일을 처리하면 더 빠른 이유는?
Nginx를 예를 들면, 원래 빠른 정적파일 리턴을 목표로 두고 설계되었다. 어플리케이션에서도 웹서버 역할을 할 수는 있지만, 이미 어플리케이션은 DB쿼리도 조회하는 등 각종 로직을 수행하느라 WAS에 부하가 가기 때문이다.

#### Rack::Sendfile을 쓸 수 없는 상황 (웹서버에서 제공하지 않을 때)
이럴 땐 루비에서 파일을 열어서 클라이언트로 스트림으로 보낸다.

```ruby
# rails/actionpack/lib/action_dispatch/http/response.rb 330번째 줄
# Stream the file's contents if Rack::Sendfile isn't present.
def each
  File.open(to_path, "rb") do |file|
    while chunk = file.read(16384)
      yield chunk
    end
  end
end
```

## Ruby File I/O 원리

루비에서 파일을 Open을 할 때 이 파일 전체를 메모리에 넣어서 처리하는지 확인해야 함. 만약 그렇게 한다면 이는 매우 비효율적이기 때문

- [루비 File Open](http://ruby-doc.org/core-2.2.0/File.html#method-c-new)
```ruby
# open에 따로 block 설정이 없다면 둘은 동일함
f = File.new("testfile", "r")
f = File.open("testfile", "r")
```

- File Open -> C 코드
```c

static VALUE
rb_file_initialize(int argc, VALUE *argv, VALUE io)
{
  if (RFILE(io)->fptr) {
      rb_raise(rb_eRuntimeError, "reinitializing File");
  }
  if (0 < argc && argc < 3) {
      VALUE fd = rb_check_convert_type(argv[0], T_FIXNUM, "Fixnum", "to_int");

      if (!NIL_P(fd)) {
          argv[0] = fd;
          return rb_io_initialize(argc, argv, io);
      }
  }
  rb_open_file(argc, argv, io);

  return io;
}
```

- rb_open_file 메서드
```c
static VALUE
rb_open_file(int argc, const VALUE *argv, VALUE io)
{
    VALUE fname;
    int oflags, fmode;
    convconfig_t convconfig;
    mode_t perm;

    rb_scan_open_args(argc, argv, &fname, &oflags, &fmode, &convconfig, &perm);
    rb_file_open_generic(io, fname, oflags, fmode, &convconfig, perm);

    return io;
}
```

- rb_file_open_generic 메서드
```c
static VALUE
rb_file_open_generic(VALUE io, VALUE filename, int oflags, int fmode,
		     const convconfig_t *convconfig, mode_t perm)
{
    VALUE pathv;
    rb_io_t *fptr;
    convconfig_t cc;
    if (!convconfig) {
	/* Set to default encodings */
	rb_io_ext_int_to_encs(NULL, NULL, &cc.enc, &cc.enc2, fmode);
        cc.ecflags = 0;
        cc.ecopts = Qnil;
        convconfig = &cc;
    }
    validate_enc_binmode(&fmode, convconfig->ecflags,
			 convconfig->enc, convconfig->enc2);

    MakeOpenFile(io, fptr);
    fptr->mode = fmode;
    fptr->encs = *convconfig;
    pathv = rb_str_new_frozen(filename);
#ifdef O_TMPFILE
    if (!(oflags & O_TMPFILE)) {
        fptr->pathv = pathv;
    }
#else
    fptr->pathv = pathv;
#endif
    fptr->fd = rb_sysopen(pathv, oflags, perm);
    io_check_tty(fptr);
    if (fmode & FMODE_SETENC_BY_BOM) io_set_encoding_by_bom(io);

    return io;
}
```

- rb_scan_open_args 메서드
```c
static void
rb_scan_open_args(int argc, const VALUE *argv,
        VALUE *fname_p, int *oflags_p, int *fmode_p,
        convconfig_t *convconfig_p, mode_t *perm_p)
{
    VALUE opt, fname, vmode, vperm;
    int oflags, fmode;
    mode_t perm;

    argc = rb_scan_args(argc, argv, "12:", &fname, &vmode, &vperm, &opt);
    FilePathValue(fname);

    rb_io_extract_modeenc(&vmode, &vperm, opt, &oflags, &fmode, convconfig_p);

    perm = NIL_P(vperm) ? 0666 :  NUM2MODET(vperm);

    *fname_p = fname;
    *oflags_p = oflags;
    *fmode_p = fmode;
    *perm_p = perm;
}
```
