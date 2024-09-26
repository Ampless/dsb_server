import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shelf/shelf.dart';

String httpDate() =>
    DateFormat('EEE, dd MMM y HH:mm:ss GMT', 'C').format(DateTime.now());

Response Function(int, String, [bool, String]) _resp(
        Map<String, String> customHeaders) =>
    (code, body, [private = false, contentType = 'application/json']) =>
        Response(code, body: body, headers: {
          'Allow': 'GET',
          'Cache-Control': '${private ? 'private' : 'no-cache'},no-cache',
          'Content-Type': '$contentType; charset=utf-8',
          'Date': httpDate(),
          if (!private) 'Pragma': 'no-cache',
          if (!private) 'Expires': '-1',
          'Server': 'Microsoft-IIS/10.0',
          'X-AspNet-Version': '4.0.30319',
          'X-Powered-By': 'ASP.NET',
          ...customHeaders
        });

/// `shelf` handler for a DSB server.
/// [index]: HTML to return for 404s.
/// [customHeaders]: Custom headers to return with every response.
/// [generateAuthid]: <https://github.com/Ampless/Adsignificamus/blob/master/README.md#auth>
/// [getContent]: <https://github.com/Ampless/Adsignificamus/blob/master/README.md#plans-news-documents->
Future<Response> Function(Request) dsbHandler({
  String index =
      '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN""http://www.w3.org/TR/html4/strict.dtd"><HTML><HEAD><TITLE>Not Found</TITLE><META HTTP-EQUIV="Content-Type" Content="text/html; charset=us-ascii"></HEAD><BODY><h2>Not Found</h2><hr><p>HTTP Error 404. The requested resource is not found.</p></BODY></HTML>',
  Map<String, String> customHeaders = const {},
  required Future<String> Function(String user, String pass, String bundleid,
          String appversion, String osversion)
      generateAuthid,
  required Future<String?> Function(String endpoint, String authid) getContent,
}) =>
    (req) async {
      await initializeDateFormatting('C');
      final resp = _resp(customHeaders);
      final path = req.url.path;
      final query = req.url.queryParameters;
      if (path == 'authid') {
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
      } else if (query.containsKey('authid')) {
        final content = await getContent(path, query['authid']!);
        if (content != null) return resp(200, content);
      }
      return resp(404, index, true, "text/html");
    };
