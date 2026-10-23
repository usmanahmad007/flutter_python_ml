import 'dart:math' as math;

/// A lightweight, embedded Python interpreter in pure Dart.
///
/// Executes Python scripts, functions, math operations, and statements on-device
/// across all platforms (Android, iOS, Desktop, Web) without requiring native CPython.
class DartPythonInterpreter {
  final void Function(String)? onStdout;
  final void Function(String)? onStderr;

  final Map<String, dynamic> globals = {};

  DartPythonInterpreter({
    this.onStdout,
    this.onStderr,
  }) {
    _initBuiltins();
  }

  void _initBuiltins() {
    globals['True'] = true;
    globals['False'] = false;
    globals['None'] = null;

    // print(*args, sep=' ', end='\n')
    globals['print'] = (List<dynamic> args) {
      final formatted =
          args.map((a) => formatPythonValue(a, topLevel: true)).join(' ');
      if (onStdout != null) {
        onStdout!(formatted);
      }
      return null;
    };

    // len(obj)
    globals['len'] = (List<dynamic> args) {
      if (args.isEmpty) {
        throw ArgumentError('len() requires at least 1 argument');
      }
      final obj = args[0];
      if (obj is List) return obj.length;
      if (obj is Map) return obj.length;
      if (obj is String) return obj.length;
      if (obj is Set) return obj.length;
      throw ArgumentError('Object of type ${obj.runtimeType} has no len()');
    };

    // sum(iterable, start=0)
    globals['sum'] = (List<dynamic> args) {
      if (args.isEmpty) {
        throw ArgumentError('sum() requires at least 1 argument');
      }
      final iterable = args[0];
      num total = (args.length > 1 && args[1] is num) ? args[1] as num : 0;
      if (iterable is Iterable) {
        for (final item in iterable) {
          if (item is num) {
            total += item;
          }
        }
        return total;
      }
      throw ArgumentError('Object ${iterable.runtimeType} is not iterable');
    };

    // max(*args)
    globals['max'] = (List<dynamic> args) {
      if (args.isEmpty) throw ArgumentError('max() requires arguments');
      if (args.length == 1 && args[0] is Iterable) {
        final list = (args[0] as Iterable).whereType<num>().toList();
        if (list.isEmpty) throw ArgumentError('max() arg is an empty sequence');
        return list.reduce(math.max);
      }
      final list = args.whereType<num>().toList();
      return list.reduce(math.max);
    };

    // min(*args)
    globals['min'] = (List<dynamic> args) {
      if (args.isEmpty) throw ArgumentError('min() requires arguments');
      if (args.length == 1 && args[0] is Iterable) {
        final list = (args[0] as Iterable).whereType<num>().toList();
        if (list.isEmpty) throw ArgumentError('min() arg is an empty sequence');
        return list.reduce(math.min);
      }
      final list = args.whereType<num>().toList();
      return list.reduce(math.min);
    };

    // round(number, ndigits=None)
    globals['round'] = (List<dynamic> args) {
      if (args.isEmpty) {
        throw ArgumentError('round() requires at least 1 argument');
      }
      final val = (args[0] as num).toDouble();
      if (args.length > 1 && args[1] is num) {
        final digits = (args[1] as num).toInt();
        final mod = math.pow(10, digits);
        return (val * mod).round() / mod;
      }
      return val.round();
    };

    // abs(x)
    globals['abs'] = (List<dynamic> args) {
      if (args.isEmpty) throw ArgumentError('abs() requires 1 argument');
      final val = args[0] as num;
      return val.abs();
    };

    // range([start], stop, [step])
    globals['range'] = (List<dynamic> args) {
      if (args.isEmpty) {
        throw ArgumentError('range expected at least 1 argument');
      }
      int start = 0;
      int stop = 0;
      int step = 1;

      if (args.length == 1) {
        stop = (args[0] as num).toInt();
      } else if (args.length >= 2) {
        start = (args[0] as num).toInt();
        stop = (args[1] as num).toInt();
        if (args.length >= 3) {
          step = (args[2] as num).toInt();
        }
      }
      if (step == 0) throw ArgumentError('range() arg 3 must not be zero');

      final result = <int>[];
      if (step > 0) {
        for (int i = start; i < stop; i += step) {
          result.add(i);
        }
      } else {
        for (int i = start; i > stop; i += step) {
          result.add(i);
        }
      }
      return result;
    };

    // type conversions
    globals['str'] = (List<dynamic> args) =>
        args.isEmpty ? '' : formatPythonValue(args[0], topLevel: true);
    globals['int'] = (List<dynamic> args) {
      if (args.isEmpty) return 0;
      final a = args[0];
      if (a is num) return a.toInt();
      return int.parse(a.toString());
    };
    globals['float'] = (List<dynamic> args) {
      if (args.isEmpty) return 0.0;
      final a = args[0];
      if (a is num) return a.toDouble();
      return double.parse(a.toString());
    };
    globals['bool'] =
        (List<dynamic> args) => args.isEmpty ? false : _isTruthy(args[0]);
    globals['list'] = (List<dynamic> args) =>
        args.isEmpty ? <dynamic>[] : List<dynamic>.from(args[0] as Iterable);
    globals['dict'] = (List<dynamic> args) => args.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(args[0] as Map);

    // Math module built-in
    globals['math'] = {
      'sqrt': (List<dynamic> args) => math.sqrt((args[0] as num).toDouble()),
      'pow': (List<dynamic> args) => math.pow(args[0] as num, args[1] as num),
      'sin': (List<dynamic> args) => math.sin((args[0] as num).toDouble()),
      'cos': (List<dynamic> args) => math.cos((args[0] as num).toDouble()),
      'tan': (List<dynamic> args) => math.tan((args[0] as num).toDouble()),
      'exp': (List<dynamic> args) => math.exp((args[0] as num).toDouble()),
      'log': (List<dynamic> args) => math.log((args[0] as num).toDouble()),
      'pi': math.pi,
      'e': math.e,
      'floor': (List<dynamic> args) => (args[0] as num).floor(),
      'ceil': (List<dynamic> args) => (args[0] as num).ceil(),
    };
  }

  /// Executes Python source code and returns the last evaluated statement/return value.
  dynamic execute(String code, {Map<String, dynamic>? arguments}) {
    if (arguments != null) {
      globals.addAll(arguments);
      globals['__args__'] = arguments;
    }

    final lines = _splitLines(code);
    return _executeBlock(lines, 0, globals);
  }

  /// Calls a function defined in the interpreter's scope.
  dynamic callFunction(String functionName,
      {List<dynamic>? positionalArgs, Map<String, dynamic>? keywordArgs}) {
    final fn = globals[functionName];
    if (fn == null) {
      throw NoSuchMethodError.withInvocation(
          this, Invocation.method(Symbol(functionName), positionalArgs ?? []));
    }
    if (fn is _PythonFunction) {
      return fn.call(positionalArgs ?? [], keywordArgs ?? {});
    } else if (fn is Function) {
      return Function.apply(fn, [positionalArgs ?? []]);
    }
    throw ArgumentError('$functionName is not callable');
  }

  List<String> _splitLines(String code) {
    // Standardize line endings and preserve blank lines for indentation tracking
    return code.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  }

  dynamic _executeBlock(
      List<String> lines, int baseIndent, Map<String, dynamic> scope) {
    int i = 0;
    dynamic lastResult;

    while (i < lines.length) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      // Skip comments or blank lines
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        i++;
        continue;
      }

      final indent = _getIndent(rawLine);
      if (indent < baseIndent) {
        // Exit current block
        break;
      }

      // 1. Function definition: def fname(args):
      if (trimmed.startsWith('def ')) {
        final defHeader = trimmed.substring(4);
        final colonIdx = defHeader.indexOf(':');
        if (colonIdx == -1) {
          throw FormatException('Missing ":" in def statement: $trimmed');
        }

        final sig = defHeader.substring(0, colonIdx).trim();
        final openParen = sig.indexOf('(');
        final closeParen = sig.lastIndexOf(')');
        final fname = sig.substring(0, openParen).trim();
        final paramsStr = sig.substring(openParen + 1, closeParen).trim();
        final params = paramsStr.isEmpty
            ? <String>[]
            : paramsStr.split(',').map((p) => p.trim()).toList();

        // Capture body lines with higher indentation
        final bodyLines = <String>[];
        i++;
        while (i < lines.length) {
          final nextRaw = lines[i];
          if (nextRaw.trim().isEmpty || nextRaw.trim().startsWith('#')) {
            bodyLines.add(nextRaw);
            i++;
            continue;
          }
          final nextIndent = _getIndent(nextRaw);
          if (nextIndent <= indent) break;
          bodyLines.add(nextRaw);
          i++;
        }

        final pyFunc = _PythonFunction(fname, params, bodyLines, this, scope);
        scope[fname] = pyFunc;
        globals[fname] = pyFunc;
        continue;
      }

      // 2. Return statement: return expr
      if (trimmed.startsWith('return ') || trimmed == 'return') {
        var expr = trimmed.length > 7 ? trimmed.substring(7).trim() : '';
        if (expr.isEmpty) return null;
        if (_isUnbalanced(expr)) {
          final buffer = StringBuffer(expr);
          i++;
          while (i < lines.length && _isUnbalanced(buffer.toString())) {
            buffer.write('\n');
            buffer.write(lines[i].trim());
            i++;
          }
          expr = buffer.toString();
        }
        return _evalExpression(expr, scope);
      }

      // 3. For loop: for var in iterable:
      if (trimmed.startsWith('for ')) {
        final colonIdx = trimmed.lastIndexOf(':');
        final header = trimmed.substring(4, colonIdx).trim();
        final inIdx = header.indexOf(' in ');
        final varName = header.substring(0, inIdx).trim();
        final iterExpr = header.substring(inIdx + 4).trim();
        final iterable = _evalExpression(iterExpr, scope);

        final bodyLines = <String>[];
        i++;
        while (i < lines.length) {
          final nextRaw = lines[i];
          if (nextRaw.trim().isEmpty || nextRaw.trim().startsWith('#')) {
            bodyLines.add(nextRaw);
            i++;
            continue;
          }
          if (_getIndent(nextRaw) <= indent) break;
          bodyLines.add(nextRaw);
          i++;
        }

        if (iterable is Iterable) {
          for (final item in iterable) {
            scope[varName] = item;
            final res = _executeBlock(bodyLines, indent + 1, scope);
            if (res != null) lastResult = res;
          }
        }
        continue;
      }

      // 4. While loop: while cond:
      if (trimmed.startsWith('while ')) {
        final colonIdx = trimmed.lastIndexOf(':');
        final condExpr = trimmed.substring(6, colonIdx).trim();

        final bodyLines = <String>[];
        i++;
        while (i < lines.length) {
          final nextRaw = lines[i];
          if (nextRaw.trim().isEmpty || nextRaw.trim().startsWith('#')) {
            bodyLines.add(nextRaw);
            i++;
            continue;
          }
          if (_getIndent(nextRaw) <= indent) break;
          bodyLines.add(nextRaw);
          i++;
        }

        while (_isTruthy(_evalExpression(condExpr, scope))) {
          final res = _executeBlock(bodyLines, indent + 1, scope);
          if (res != null) lastResult = res;
        }
        continue;
      }

      // 5. If / elif / else conditional
      if (trimmed.startsWith('if ')) {
        var matched = false;
        var currentIdx = i;

        while (currentIdx < lines.length) {
          final currentRaw = lines[currentIdx];
          final currentTrimmed = currentRaw.trim();
          if (currentTrimmed.isEmpty || currentTrimmed.startsWith('#')) {
            currentIdx++;
            continue;
          }
          final currentIndent = _getIndent(currentRaw);
          if (currentIndent != indent) break;

          if (currentTrimmed.startsWith('if ') ||
              currentTrimmed.startsWith('elif ')) {
            final isElif = currentTrimmed.startsWith('elif ');
            final cond = currentTrimmed
                .substring(isElif ? 5 : 3, currentTrimmed.lastIndexOf(':'))
                .trim();
            final condVal = _isTruthy(_evalExpression(cond, scope));

            final branchLines = <String>[];
            currentIdx++;
            while (currentIdx < lines.length) {
              final nextRaw = lines[currentIdx];
              if (nextRaw.trim().isEmpty || nextRaw.trim().startsWith('#')) {
                branchLines.add(nextRaw);
                currentIdx++;
                continue;
              }
              if (_getIndent(nextRaw) <= indent) break;
              branchLines.add(nextRaw);
              currentIdx++;
            }

            if (!matched && condVal) {
              matched = true;
              lastResult = _executeBlock(branchLines, indent + 1, scope);
            }
          } else if (currentTrimmed.startsWith('else:')) {
            final branchLines = <String>[];
            currentIdx++;
            while (currentIdx < lines.length) {
              final nextRaw = lines[currentIdx];
              if (nextRaw.trim().isEmpty || nextRaw.trim().startsWith('#')) {
                branchLines.add(nextRaw);
                currentIdx++;
                continue;
              }
              if (_getIndent(nextRaw) <= indent) break;
              branchLines.add(nextRaw);
              currentIdx++;
            }

            if (!matched) {
              matched = true;
              lastResult = _executeBlock(branchLines, indent + 1, scope);
            }
            break;
          } else {
            break;
          }
        }

        i = currentIdx;
        continue;
      }

      // 6. Import statement
      if (trimmed.startsWith('import ') || trimmed.startsWith('from ')) {
        _handleImport(trimmed, scope);
        i++;
        continue;
      }

      // 7. Assignment: var = expr, var += expr, var -= expr
      final assignMatch = RegExp(
              r'^([a-zA-Z_][a-zA-Z0-9_]*(\[[^\]]+\])?)\s*(=|\+=|-=|\*=|/=|%=)\s*(.*)$')
          .firstMatch(trimmed);
      if (assignMatch != null) {
        final target = assignMatch.group(1)!;
        final op = assignMatch.group(3)!;
        final expr = assignMatch.group(4)!;

        // Check if multi-line dict/list literal starts here
        var fullExpr = expr;
        if (_isUnbalanced(fullExpr)) {
          final buffer = StringBuffer(fullExpr);
          i++;
          while (i < lines.length && _isUnbalanced(buffer.toString())) {
            buffer.write('\n');
            buffer.write(lines[i].trim());
            i++;
          }
          fullExpr = buffer.toString();
          i--; // counter will increment at bottom
        }

        final val = _evalExpression(fullExpr, scope);
        _applyAssignment(target, op, val, scope);
        lastResult = val;
        i++;
        continue;
      }

      // 8. Expression / Statement (e.g. print(...), function_call(...))
      var fullExpr = trimmed;
      if (_isUnbalanced(fullExpr)) {
        final buffer = StringBuffer(fullExpr);
        i++;
        while (i < lines.length && _isUnbalanced(buffer.toString())) {
          buffer.write('\n');
          buffer.write(lines[i].trim());
          i++;
        }
        fullExpr = buffer.toString();
        i--;
      }

      lastResult = _evalExpression(fullExpr, scope);
      i++;
    }

    return lastResult;
  }

  void _applyAssignment(
      String target, String op, dynamic val, Map<String, dynamic> scope) {
    if (target.contains('[')) {
      final openBracket = target.indexOf('[');
      final closeBracket = target.lastIndexOf(']');
      final varName = target.substring(0, openBracket).trim();
      final keyExpr = target.substring(openBracket + 1, closeBracket).trim();
      final key = _evalExpression(keyExpr, scope);
      final container = scope[varName] ?? globals[varName];

      if (container is Map) {
        container[key] = val;
      } else if (container is List) {
        final idx = (key as num).toInt();
        container[idx] = val;
      }
      return;
    }

    if (op == '=') {
      scope[target] = val;
    } else {
      final current = scope[target] ?? globals[target];
      if (op == '+=') scope[target] = (current as num) + (val as num);
      if (op == '-=') scope[target] = (current as num) - (val as num);
      if (op == '*=') scope[target] = (current as num) * (val as num);
      if (op == '/=') scope[target] = (current as num) / (val as num);
    }
  }

  void _handleImport(String trimmed, Map<String, dynamic> scope) {
    if (trimmed.startsWith('import ')) {
      final moduleName = trimmed.substring(7).trim();
      if (moduleName == 'math') {
        scope['math'] = globals['math'];
      } else if (moduleName == 'json') {
        scope['json'] = {
          'dumps': (List<dynamic> a) =>
              a.isEmpty ? '{}' : formatPythonValue(a[0]),
          'loads': (List<dynamic> a) => a.isEmpty ? {} : a[0],
        };
      }
    } else if (trimmed.startsWith('from ')) {
      // from math import sqrt, pi
      final parts = trimmed.split(' import ');
      if (parts.length == 2 && parts[0] == 'from math') {
        final symbols = parts[1].split(',').map((s) => s.trim());
        final mathMap = globals['math'] as Map<String, dynamic>;
        for (final sym in symbols) {
          if (mathMap.containsKey(sym)) {
            scope[sym] = mathMap[sym];
          }
        }
      }
    }
  }

  int _getIndent(String line) {
    int count = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ' ') {
        count++;
      } else if (line[i] == '\t') {
        count += 4;
      } else {
        break;
      }
    }
    return count;
  }

  bool _isUnbalanced(String text) {
    int parens = 0;
    int brackets = 0;
    int braces = 0;
    bool inQuote = false;
    String quoteChar = '';

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inQuote) {
        if (ch == quoteChar && (i == 0 || text[i - 1] != '\\')) {
          inQuote = false;
        }
      } else {
        if (ch == '"' || ch == "'") {
          inQuote = true;
          quoteChar = ch;
        } else if (ch == '(') {
          parens++;
        } else if (ch == ')') {
          parens--;
        } else if (ch == '[') {
          brackets++;
        } else if (ch == ']') {
          brackets--;
        } else if (ch == '{') {
          braces++;
        } else if (ch == '}') {
          braces--;
        }
      }
    }
    return parens > 0 || brackets > 0 || braces > 0 || inQuote;
  }

  bool _isTruthy(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.isNotEmpty;
    if (val is Iterable) return val.isNotEmpty;
    if (val is Map) return val.isNotEmpty;
    return true;
  }

  // --------------------------------------------------------------------------
  // Expression Evaluator
  // --------------------------------------------------------------------------

  dynamic _evalExpression(String expr, Map<String, dynamic> scope) {
    expr = expr.trim();
    if (expr.isEmpty) return null;

    // Check for inline generator / comprehension: expr for var in iterable
    if (_isGeneratorExpression(expr)) {
      return _evalGenerator(expr, scope);
    }

    // 1. Logical OR: expr or expr
    final orIdx = _findTopLevelOp(expr, [' or ']);
    if (orIdx != -1) {
      final left = _evalExpression(expr.substring(0, orIdx), scope);
      if (_isTruthy(left)) return left;
      return _evalExpression(expr.substring(orIdx + 4), scope);
    }

    // 2. Logical AND: expr and expr
    final andIdx = _findTopLevelOp(expr, [' and ']);
    if (andIdx != -1) {
      final left = _evalExpression(expr.substring(0, andIdx), scope);
      if (!_isTruthy(left)) return left;
      return _evalExpression(expr.substring(andIdx + 5), scope);
    }

    // 3. Logical NOT: not expr
    if (expr.startsWith('not ')) {
      return !_isTruthy(_evalExpression(expr.substring(4), scope));
    }

    // 4. Comparison operators: ==, !=, <=, >=, <, >, in, not in
    final compOps = ['==', '!=', '<=', '>=', '<', '>', ' not in ', ' in '];
    final compIdx = _findTopLevelOp(expr, compOps);
    if (compIdx != -1) {
      final matchedOp =
          compOps.firstWhere((op) => expr.startsWith(op, compIdx));
      final left = _evalExpression(expr.substring(0, compIdx), scope);
      final right =
          _evalExpression(expr.substring(compIdx + matchedOp.length), scope);
      return _evalComparison(left, matchedOp.trim(), right);
    }

    // 5. Binary Addition and Subtraction: +, -
    final addSubIdx = _findTopLevelOp(expr, ['+', '-'], reverse: true);
    if (addSubIdx > 0) {
      final op = expr[addSubIdx];
      // Ensure it's not a scientific notation exponent like 1e-5 or unary sign
      final prevChar = expr[addSubIdx - 1];
      if (prevChar != 'e' &&
          prevChar != 'E' &&
          prevChar != '*' &&
          prevChar != '/' &&
          prevChar != '(' &&
          prevChar != '[') {
        final left = _evalExpression(expr.substring(0, addSubIdx), scope);
        final right = _evalExpression(expr.substring(addSubIdx + 1), scope);
        if (op == '+') {
          if (left is String || right is String) {
            return '${formatPythonValue(left, topLevel: true)}${formatPythonValue(right, topLevel: true)}';
          }
          if (left is List && right is List) {
            return [...left, ...right];
          }
          return (left as num) + (right as num);
        } else {
          return (left as num) - (right as num);
        }
      }
    }

    // 6. Multiplication, Division, Modulo: *, /, //, %
    final mulDivIdx =
        _findTopLevelOp(expr, ['//', '*', '/', '%'], reverse: true);
    if (mulDivIdx != -1) {
      final op = expr.startsWith('//', mulDivIdx) ? '//' : expr[mulDivIdx];
      if (!expr.startsWith('**', mulDivIdx)) {
        final left = _evalExpression(expr.substring(0, mulDivIdx), scope);
        final right =
            _evalExpression(expr.substring(mulDivIdx + op.length), scope);
        if (op == '*') {
          if (left is String && right is int) return left * right;
          if (left is List && right is int) {
            return List.generate(right, (_) => left).expand((x) => x).toList();
          }
          return (left as num) * (right as num);
        }
        if (op == '/') return (left as num) / (right as num);
        if (op == '//') return (left as num) ~/ (right as num);
        if (op == '%') return (left as num) % (right as num);
      }
    }

    // 7. Power exponentiation: **
    final powIdx = _findTopLevelOp(expr, ['**']);
    if (powIdx != -1) {
      final left = _evalExpression(expr.substring(0, powIdx), scope);
      final right = _evalExpression(expr.substring(powIdx + 2), scope);
      return math.pow(left as num, right as num);
    }

    // 8. Unary minus: -expr
    if (expr.startsWith('-')) {
      final val = _evalExpression(expr.substring(1), scope);
      return -(val as num);
    }

    // 9. Parentheses group: (expr)
    if (expr.startsWith('(') &&
        expr.endsWith(')') &&
        !_isUnbalanced(expr.substring(1, expr.length - 1))) {
      return _evalExpression(expr.substring(1, expr.length - 1), scope);
    }

    // 10. List literal: [1, 2, 3] or comprehension [x * 2 for x in items]
    if (expr.startsWith('[') && expr.endsWith(']')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return <dynamic>[];
      if (_isGeneratorExpression(inner)) {
        return _evalGenerator(inner, scope);
      }
      final items = _splitArguments(inner);
      return items.map((item) => _evalExpression(item, scope)).toList();
    }

    // 11. Dict literal: {"a": 1, "b": 2}
    if (expr.startsWith('{') && expr.endsWith('}')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return <String, dynamic>{};
      final entries = _splitArguments(inner);
      final dict = <String, dynamic>{};
      for (final entry in entries) {
        final colonIdx = _findTopLevelOp(entry, [':']);
        if (colonIdx == -1) throw FormatException('Invalid dict entry: $entry');
        final k = _evalExpression(entry.substring(0, colonIdx), scope);
        final v = _evalExpression(entry.substring(colonIdx + 1), scope);
        dict[k.toString()] = v;
      }
      return dict;
    }

    // 12. String literals: '...', "...", f"...", f'...'
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return _unescapeString(expr.substring(1, expr.length - 1));
    }
    if ((expr.startsWith('f"') && expr.endsWith('"')) ||
        (expr.startsWith("f'") && expr.endsWith("'"))) {
      final template = expr.substring(2, expr.length - 1);
      return _evalFString(template, scope);
    }

    // 13. Numeric literal
    final numVal = num.tryParse(expr);
    if (numVal != null) return numVal;

    // 14. Function call or indexing or member access: foo(...) or bar[...] or obj.prop
    if (expr.endsWith(')')) {
      final parenIdx = _findMatchingOpenParen(expr);
      if (parenIdx != -1) {
        final targetExpr = expr.substring(0, parenIdx).trim();
        final argsStr = expr.substring(parenIdx + 1, expr.length - 1).trim();
        final target = _evalExpression(targetExpr, scope);

        final args = <dynamic>[];
        final kwargs = <String, dynamic>{};
        if (argsStr.isNotEmpty) {
          final argList = _splitArguments(argsStr);
          for (final a in argList) {
            final eqIdx = _findTopLevelOp(a, ['=']);
            if (eqIdx != -1 && !_isComparison(a, eqIdx)) {
              final k = a.substring(0, eqIdx).trim();
              final v = _evalExpression(a.substring(eqIdx + 1), scope);
              kwargs[k] = v;
            } else {
              args.add(_evalExpression(a, scope));
            }
          }
        }

        if (target is _PythonFunction) {
          return target.call(args, kwargs);
        } else if (target is Function) {
          try {
            return Function.apply(target, [args]);
          } catch (_) {
            return Function.apply(target, args);
          }
        }
      }
    }

    // 15. Subscript access: obj[idx]
    if (expr.endsWith(']')) {
      final bracketIdx = _findMatchingOpenBracket(expr);
      if (bracketIdx != -1) {
        final targetExpr = expr.substring(0, bracketIdx).trim();
        final keyExpr = expr.substring(bracketIdx + 1, expr.length - 1).trim();
        final target = _evalExpression(targetExpr, scope);
        final key = _evalExpression(keyExpr, scope);

        if (target is Map) return target[key];
        if (target is List) {
          final idx = (key as num).toInt();
          return idx < 0 ? target[target.length + idx] : target[idx];
        }
        if (target is String) {
          final idx = (key as num).toInt();
          return target[idx < 0 ? target.length + idx : idx];
        }
      }
    }

    // 16. Member access: obj.prop or obj.method()
    final dotIdx = _findTopLevelOp(expr, ['.'], reverse: true);
    if (dotIdx != -1 && !_isNumericDot(expr, dotIdx)) {
      final objExpr = expr.substring(0, dotIdx).trim();
      final memberName = expr.substring(dotIdx + 1).trim();
      final obj = _evalExpression(objExpr, scope);

      if (obj is Map) {
        if (obj.containsKey(memberName)) return obj[memberName];
        if (memberName == 'keys') return (List<dynamic> a) => obj.keys.toList();
        if (memberName == 'values') {
          return (List<dynamic> a) => obj.values.toList();
        }
        if (memberName == 'items') {
          return (List<dynamic> a) =>
              obj.entries.map((e) => [e.key, e.value]).toList();
        }
        if (memberName == 'get') {
          return (List<dynamic> a) => obj[a[0]] ?? (a.length > 1 ? a[1] : null);
        }
      }
      if (obj is String) {
        if (memberName == 'lower') {
          return (List<dynamic> a) => obj.toLowerCase();
        }
        if (memberName == 'upper') {
          return (List<dynamic> a) => obj.toUpperCase();
        }
        if (memberName == 'split') {
          return (List<dynamic> a) => a.isEmpty
              ? obj.split(RegExp(r'\s+'))
              : obj.split(a[0].toString());
        }
        if (memberName == 'strip') return (List<dynamic> a) => obj.trim();
      }
      if (obj is List) {
        if (memberName == 'append') return (List<dynamic> a) => obj.add(a[0]);
        if (memberName == 'extend') {
          return (List<dynamic> a) => obj.addAll(a[0] as Iterable);
        }
        if (memberName == 'pop') return (List<dynamic> a) => obj.removeLast();
      }
      return null;
    }

    // 17. Identifier / Variable lookup
    if (scope.containsKey(expr)) return scope[expr];
    if (globals.containsKey(expr)) return globals[expr];

    // Fallback: check if boolean or None
    if (expr == 'True') return true;
    if (expr == 'False') return false;
    if (expr == 'None') return null;

    throw ArgumentError("NameError: name '$expr' is not defined");
  }

  bool _isGeneratorExpression(String expr) {
    return _findTopLevelOp(expr, [' for ']) != -1 &&
        _findTopLevelOp(expr, [' in ']) != -1;
  }

  List<dynamic> _evalGenerator(String expr, Map<String, dynamic> scope) {
    // pattern: item_expr for var in iterable [if cond]
    final forIdx = _findTopLevelOp(expr, [' for ']);
    final inIdx = _findTopLevelOp(expr, [' in ']);
    final ifIdx = _findTopLevelOp(expr, [' if ']);

    final itemExpr = expr.substring(0, forIdx).trim();
    final varName = expr.substring(forIdx + 5, inIdx).trim();
    final iterExpr = ifIdx != -1
        ? expr.substring(inIdx + 4, ifIdx).trim()
        : expr.substring(inIdx + 4).trim();
    final condExpr = ifIdx != -1 ? expr.substring(ifIdx + 4).trim() : null;

    final iterable = _evalExpression(iterExpr, scope);
    final results = <dynamic>[];

    if (iterable is Iterable) {
      for (final item in iterable) {
        final localScope = Map<String, dynamic>.from(scope);
        localScope[varName] = item;
        if (condExpr == null ||
            _isTruthy(_evalExpression(condExpr, localScope))) {
          results.add(_evalExpression(itemExpr, localScope));
        }
      }
    }
    return results;
  }

  bool _evalComparison(dynamic left, String op, dynamic right) {
    switch (op) {
      case '==':
        return left == right;
      case '!=':
        return left != right;
      case '<':
        return (left as num) < (right as num);
      case '<=':
        return (left as num) <= (right as num);
      case '>':
        return (left as num) > (right as num);
      case '>=':
        return (left as num) >= (right as num);
      case 'in':
        if (right is Iterable) return right.contains(left);
        if (right is Map) return right.containsKey(left);
        if (right is String) return right.contains(left.toString());
        return false;
      case 'not in':
        return !_evalComparison(left, 'in', right);
      default:
        throw ArgumentError('Unsupported operator: $op');
    }
  }

  String _evalFString(String template, Map<String, dynamic> scope) {
    final buffer = StringBuffer();
    int i = 0;
    while (i < template.length) {
      if (template[i] == '{') {
        final closeIdx = template.indexOf('}', i);
        if (closeIdx != -1) {
          final expr = template.substring(i + 1, closeIdx);
          final val = _evalExpression(expr, scope);
          buffer.write(formatPythonValue(val, topLevel: true));
          i = closeIdx + 1;
          continue;
        }
      }
      buffer.write(template[i]);
      i++;
    }
    return buffer.toString();
  }

  String _unescapeString(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'");
  }

  int _findTopLevelOp(String expr, List<String> ops, {bool reverse = false}) {
    int parens = 0;
    int brackets = 0;
    int braces = 0;
    bool inQuote = false;
    String quoteChar = '';

    final indices = reverse
        ? List.generate(expr.length, (i) => expr.length - 1 - i)
        : List.generate(expr.length, (i) => i);

    for (final i in indices) {
      final ch = expr[i];
      if (inQuote) {
        if (ch == quoteChar && (i == 0 || expr[i - 1] != '\\')) inQuote = false;
        continue;
      }
      if (ch == '"' || ch == "'") {
        inQuote = true;
        quoteChar = ch;
        continue;
      }
      if (ch == '(') parens++;
      if (ch == ')') parens--;
      if (ch == '[') brackets++;
      if (ch == ']') brackets--;
      if (ch == '{') braces++;
      if (ch == '}') braces--;

      if (parens == 0 && brackets == 0 && braces == 0) {
        for (final op in ops) {
          if (expr.startsWith(op, i)) {
            // Guard against operator overlaps:
            if (op == '*' &&
                ((i > 0 && expr[i - 1] == '*') ||
                    (i + 1 < expr.length && expr[i + 1] == '*'))) {
              continue;
            }
            if (op == '/' &&
                ((i > 0 && expr[i - 1] == '/') ||
                    (i + 1 < expr.length && expr[i + 1] == '/'))) {
              continue;
            }
            if ((op == '+' || op == '-') &&
                i + 1 < expr.length &&
                expr[i + 1] == '=') {
              continue;
            }
            if ((op == '<' || op == '>') &&
                i + 1 < expr.length &&
                expr[i + 1] == '=') {
              continue;
            }
            if (op == '=' &&
                ((i > 0 &&
                        (expr[i - 1] == '!' ||
                            expr[i - 1] == '<' ||
                            expr[i - 1] == '>' ||
                            expr[i - 1] == '=')) ||
                    (i + 1 < expr.length && expr[i + 1] == '='))) {
              continue;
            }
            return i;
          }
        }
      }
    }
    return -1;
  }

  int _findMatchingOpenParen(String expr) {
    int parens = 0;
    for (int i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == ')') parens++;
      if (expr[i] == '(') {
        parens--;
        if (parens == 0) return i;
      }
    }
    return -1;
  }

  int _findMatchingOpenBracket(String expr) {
    int brackets = 0;
    for (int i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == ']') brackets++;
      if (expr[i] == '[') {
        brackets--;
        if (brackets == 0) return i;
      }
    }
    return -1;
  }

  bool _isNumericDot(String expr, int dotIdx) {
    if (dotIdx > 0 && dotIdx < expr.length - 1) {
      final before = expr[dotIdx - 1];
      final after = expr[dotIdx + 1];
      if (RegExp(r'[0-9]').hasMatch(before) &&
          RegExp(r'[0-9]').hasMatch(after)) {
        return true;
      }
    }
    return false;
  }

  bool _isComparison(String s, int eqIdx) {
    if (eqIdx > 0 &&
        (s[eqIdx - 1] == '!' ||
            s[eqIdx - 1] == '<' ||
            s[eqIdx - 1] == '>' ||
            s[eqIdx - 1] == '=')) return true;
    if (eqIdx < s.length - 1 && s[eqIdx + 1] == '=') return true;
    return false;
  }

  List<String> _splitArguments(String argsStr) {
    final args = <String>[];
    int parens = 0;
    int brackets = 0;
    int braces = 0;
    bool inQuote = false;
    String quoteChar = '';
    int start = 0;

    for (int i = 0; i < argsStr.length; i++) {
      final ch = argsStr[i];
      if (inQuote) {
        if (ch == quoteChar && (i == 0 || argsStr[i - 1] != '\\')) {
          inQuote = false;
        }
        continue;
      }
      if (ch == '"' || ch == "'") {
        inQuote = true;
        quoteChar = ch;
        continue;
      }
      if (ch == '(') parens++;
      if (ch == ')') parens--;
      if (ch == '[') brackets++;
      if (ch == ']') brackets--;
      if (ch == '{') braces++;
      if (ch == '}') braces--;

      if (ch == ',' && parens == 0 && brackets == 0 && braces == 0) {
        args.add(argsStr.substring(start, i).trim());
        start = i + 1;
      }
    }
    if (start < argsStr.length) {
      args.add(argsStr.substring(start).trim());
    }
    return args;
  }

  /// Formats a Dart object as a Python-compliant string representation.
  static String formatPythonValue(dynamic val, {bool topLevel = false}) {
    if (val == null) return 'None';
    if (val is bool) return val ? 'True' : 'False';
    if (val is String) return topLevel ? val : "'$val'";
    if (val is num) {
      if (val is double &&
          val == val.roundToDouble() &&
          !val.toString().contains('.')) {
        return '${val.toInt()}';
      }
      return val.toString();
    }
    if (val is List) {
      return '[${val.map((e) => formatPythonValue(e, topLevel: false)).join(', ')}]';
    }
    if (val is Map) {
      return '{${val.entries.map((e) => "'${e.key}': ${formatPythonValue(e.value, topLevel: false)}").join(', ')}}';
    }
    return val.toString();
  }
}

class _PythonFunction {
  final String name;
  final List<String> params;
  final List<String> bodyLines;
  final DartPythonInterpreter interpreter;
  final Map<String, dynamic> closureScope;

  _PythonFunction(this.name, this.params, this.bodyLines, this.interpreter,
      this.closureScope);

  dynamic call(List<dynamic> positional, Map<String, dynamic> keywords) {
    final funcScope = Map<String, dynamic>.from(closureScope);

    // Bind positional parameters
    for (int i = 0; i < params.length; i++) {
      final paramName = params[i];
      if (i < positional.length) {
        funcScope[paramName] = positional[i];
      } else if (keywords.containsKey(paramName)) {
        funcScope[paramName] = keywords[paramName];
      }
    }

    // Bind extra kwargs
    funcScope.addAll(keywords);

    return interpreter._executeBlock(bodyLines, 0, funcScope);
  }
}
