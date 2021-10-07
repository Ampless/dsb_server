import 'package:shelf/shelf.dart';

Response Function(int, String, [String?]) _resp(
        Map<String, String> customHeaders) =>
    (code, body, [contentType]) => Response(code,
        body: body,
        headers: {
          'Cache-Control': 'no-cache',
          'Content-Type':
              (contentType ?? 'application/json') + '; charset=utf-8',
          'Pragma': 'no-cache',
          'Expires': '-1',
          'Server': 'Microsoft-IIS/8.5',
          'X-AspNet-Version': '4.0.30319',
          'X-Powered-By': 'ASP.NET',
        }..addAll(customHeaders));

Future<Response> Function(Request) dsbHandler({
  String index =
      '<html><head><title>Die Ressource kann nicht gefunden werden.</title><meta name="viewport" content="width=device-width" /><style> body{font-family:Verdana;font-weight:normal;font-size:.7em;color:black;} p{font-family:Verdana;font-weight:normal;color:black;margin-top:-5px} b{font-family:Verdana;font-weight:bold;color:black;margin-top:-5px} H1{font-family:Verdana;font-weight:normal;font-size:18pt;color:red } H2{font-family:Verdana;font-weight:normal;font-size:14pt;color:maroon } pre{font-family:Consolas,"Lucida Console",Monospace;font-size:11pt;margin:0;padding:0.5em;line-height:14pt} .marker {font-weight: bold; color: black;text-decoration: none;} .version {color: gray;} .error {margin-bottom: 10px;} .expandable { text-decoration:underline; font-weight:bold; color:navy; cursor:pointer; } @media screen and (max-width: 639px) { pre { width: 440px; overflow: auto; white-space: pre-wrap; word-wrap: break-word; } } @media screen and (max-width: 479px){pre{width:280px;}} </style></head><body bgcolor="white"><span><H1>Serverfehler in der Anwendung /.<hr width=100% size=1 color=silver></H1><h2> <i>Die Ressource kann nicht gefunden werden.</i> </h2></span><font face="Arial, Helvetica, Geneva, SunSans-Regular, sans-serif "><b> Beschreibung: </b>HTTP 404. Die gesuchte Ressource oder eine ihrer Abh&#228;ngigkeiten wurde m&#246;glicherweise entfernt, umbenannt oder ist vor&#252;bergehend nicht verf&#252;gbar. &#220;berpr&#252;fen Sie folgende URL, und stellen Sie sicher, dass sie richtig geschrieben wurde.<br><br><b> Angeforderter URL: </b>/PATH/<br><br></font></body></html>',
  Map<String, String> customHeaders = const {},
  required Future<String> Function(String user, String pass, String bundleid,
          String appversion, String osversion)
      generateAuthid,
  required Future<String?> Function(String endpoint, String authid) getContent,
}) =>
    (req) async {
      final resp = _resp(customHeaders);
      final path = req.url.path;
      final query = req.url.queryParameters;
      if (path.isEmpty) {
        return resp(404, index.replaceAll('PATH/', req.url.path), 'text/html');
      } else if (path == 'authid') {
        if ([
          'bundleid',
          'appversion',
          'osversion',
          'pushid',
          'user',
          'password'
        ].map(query.containsKey).reduce((a, b) => a && b)) {
          final aid = await generateAuthid(query['user']!, query['password']!,
              query['bundleid']!, query['appversion']!, query['osversion']!);
          return resp(200, '"$aid"');
        }
        // TODO: actually figure out which endpoints exist
      } else if (query.containsKey('authid') && path.startsWith('dsb')) {
        final content = await getContent(path, query['authid']!);
        if (content != null) return resp(200, content);
      }
      return resp(404,
          '{"Message":"No HTTP resource was found that matches the request URI \'${req.requestedUri}\'."}');
    };
