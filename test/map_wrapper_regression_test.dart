import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'regression: map access and numeric mutation in list loop should not crash',
    () {
      final source = r'''
      void main() {
        final taxasRaw = [
          {
            'numero_venda': 'VD-001',
            'bandeira': 'VISA',
            'modalidade': 'credito',
            'taxa_pct': 2.5,
            'taxa_valor': 10.0,
          },
        ];

        final rows = [
          {'numero_venda': 'VD-001', 'valor_em_aberto': 100.0},
        ];

        for (final row in rows) {
          final rowMap = row as Map;
          final taxa = taxasRaw[0] as Map;
          final valorAbertoRaw = rowMap['valor_em_aberto'] ?? rowMap['valor'] ?? 0;
          final taxaValorRaw = taxa['taxa_valor'] ?? 0;
          final valorAberto = valorAbertoRaw;
          final taxaValor = taxaValorRaw;

          rowMap['bandeira'] = taxa['bandeira'];
          rowMap['modalidade'] = taxa['modalidade'];
          rowMap['taxa_valor'] = taxaValor;
          rowMap['valor_liquido'] = valorAberto - taxaValor;
        }

        print(rows[0]['bandeira']);
        print(rows[0]['valor_liquido']);
      }
    ''';

      final runtime = Compiler().compileWriteAndLoad({
        'example': {'main.dart': source},
      });

      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        returnsNormally,
      );
    },
  );

  test('regression: dynamic map [] and []= should accept primitive args', () {
    final source = r'''
      void main() {
        dynamic m = {'a': 1.0};
        m['b'] = 2.5;
        print(m['a']);
        print(m['b']);
      }
    ''';

    final runtime = Compiler().compileWriteAndLoad({
      'example': {'main.dart': source},
    });

    expect(
      () => runtime.executeLib('package:example/main.dart', 'main'),
      prints('1.0\n2.5\n'),
    );
  });
}
