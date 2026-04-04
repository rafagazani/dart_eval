import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:test/test.dart';

void main() {
  test('large map literal should execute without frame overflow', () {
    final entries = <String>[];
    for (var i = 0; i < 320; i++) {
      entries.add("'k$i': 'v$i'");
    }

    final source = '''
      String main() {
        final payload = {
          'ds_big': [
            {${entries.join(',')}}
          ]
        };

        final rows = payload['ds_big'] as List;
        final row = rows[0] as Map;
        return row['k255'];
      }
    ''';

    final runtime = Compiler().compileWriteAndLoad({
      'eval_test': {
        'main.dart': source,
      },
    });

    final result = runtime.executeLib('package:eval_test/main.dart', 'main');
    expect(result, $String('v255'));
  });
}
