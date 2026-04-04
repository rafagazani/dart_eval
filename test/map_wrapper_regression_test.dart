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

  test(
    'regression: map key lookup in typed row loop should not crash BoxString',
    () {
      final source = r'''
      void main() {
        final taxasRows = [
          {
            'numero_venda': 'VD-001',
            'bandeira': 'VISA',
            'taxa_valor': 10.0,
          },
        ];

        final rows = [
          {'numero_venda': 'VD-001', 'valor_em_aberto': 100.0},
        ];

        for (final row in rows) {
          dynamic taxa;
          for (final t in taxasRows) {
            if (row['numero_venda'] == t['numero_venda']) {
              taxa = t;
              break;
            }
          }

          final abertoRaw = row['valor_em_aberto'];
          var valorAberto = 0.0;
          if (abertoRaw is num) {
            valorAberto = abertoRaw.toDouble();
          }

          var taxaValor = 0.0;
          if (taxa != null) {
            final taxaValorRaw = taxa['taxa_valor'];
            if (taxaValorRaw is num) {
              taxaValor = taxaValorRaw.toDouble();
            }

            row['bandeira'] = taxa['bandeira'] ?? 'N/A';
          }

          row['valor_liquido'] = valorAberto - taxaValor;
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
        prints('VISA\n90.0\n'),
      );
    },
  );

  test('regression: simple typed row map lookup should keep slot alignment', () {
    final source = r'''
      void main() {
        final rows = [
          {'valor_em_aberto': 100.0},
        ];

        for (final row in rows) {
          final abertoRaw = row['valor_em_aberto'];
          if (abertoRaw is num) {
            print(abertoRaw.toDouble());
          }
        }
      }
    ''';

    final runtime = Compiler().compileWriteAndLoad({
      'example': {'main.dart': source},
    });

    expect(
      () => runtime.executeLib('package:example/main.dart', 'main'),
      prints('100.0\n'),
    );
  });

  test(
    'regression: nested loop map key comparison should not corrupt index slots',
    () {
      final source = r'''
      void main() {
        final taxasRows = [
          {'numero_venda': 'VD-001'},
        ];

        final rows = [
          {'numero_venda': 'VD-001'},
        ];

        for (final row in rows) {
          for (final t in taxasRows) {
            if (row['numero_venda'] == t['numero_venda']) {
              print('ok');
            }
          }
        }
      }
      ''';

      final runtime = Compiler().compileWriteAndLoad({
        'example': {'main.dart': source},
      });

      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('ok\n'),
      );
    },
  );

  test(
    'regression: nested lookup with dynamic assignment and break keeps slots stable',
    () {
      final source = r'''
      void main() {
        final taxasRows = [
          {'numero_venda': 'VD-001', 'taxa_valor': 10.0},
        ];

        final rows = [
          {'numero_venda': 'VD-001', 'valor_em_aberto': 100.0},
        ];

        for (final row in rows) {
          dynamic taxa;
          for (final t in taxasRows) {
            if (row['numero_venda'] == t['numero_venda']) {
              taxa = t;
              break;
            }
          }

          final abertoRaw = row['valor_em_aberto'];
          if (abertoRaw is num && taxa != null) {
            print(abertoRaw.toDouble());
          }
        }
      }
      ''';

      final runtime = Compiler().compileWriteAndLoad({
        'example': {'main.dart': source},
      });

      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('100.0\n'),
      );
    },
  );

  test(
    'regression: missing map key null should short-circuit safely',
    () {
      final source = r'''
      String main() {
        final json = {'title': 'One Piece Movie 01'};

        final String title;
        final String? englishTitle = json['title_en'];
        if (englishTitle != null && englishTitle.isNotEmpty) {
          title = englishTitle;
        } else {
          title = json['title'];
        }

        return title;
      }
      ''';

      final runtime = Compiler().compileWriteAndLoad({
        'example': {'main.dart': source},
      });

      final value = runtime.executeLib('package:example/main.dart', 'main');
      expect((value as dynamic).$value, 'One Piece Movie 01');
    },
  );

  test(
    'regression: map null-coalescing plus toString should compile in loop',
    () {
      final source = r'''
      void main() {
        dynamic rows = [
          {'faixa_aging': null, 'valor_em_aberto': 10.0},
          {'faixa_aging': '31-60', 'valor_em_aberto': 5.0},
        ];

        for (final row in rows) {
          final faixa = (row['faixa_aging'] ?? 'N/A').toString();
          print(faixa);
        }
      }
      ''';

      final runtime = Compiler().compileWriteAndLoad({
        'example': {'main.dart': source},
      });

      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('N/A\n31-60\n'),
      );
    },
  );

  test(
    'regression: map numeric cast supports toDouble and toStringAsFixed',
    () {
      final source = r'''
      void main() {
        dynamic rows = [
          {'valor_em_aberto': 12.3},
          {'valor_em_aberto': null},
        ];

        for (final row in rows) {
          final val = ((row['valor_em_aberto'] ?? 0) as num).toDouble();
          print(val.toStringAsFixed(2));
        }
      }
      ''';

      final runtime = Compiler().compileWriteAndLoad({
        'example': {'main.dart': source},
      });

      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('12.30\n0.00\n'),
      );
    },
  );
}
