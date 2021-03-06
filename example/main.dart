import 'dart:io';

import 'package:dsb_server/dsb_server.dart';
import 'package:shelf/shelf_io.dart';

void main() => serve(
      dsbHandler(
          generateAuthid: (_, __, ___, ____, _____) async => '000-000',
          getContent: (path, authid) async => path),
      InternetAddress.loopbackIPv6,
      0,
    ).then((server) => print(server.port));
