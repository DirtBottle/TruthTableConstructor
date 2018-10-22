import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO: Fix Saved Preferences

enum Direction { left, right }

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'TTC'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final prefSave = SharedPreferences.getInstance();
  static final EdgeInsets _ALL_INSETS_4 = EdgeInsets.all(4.0),
      _VERT_INSETS_4 = EdgeInsets.symmetric(vertical: 4.0);
  static final RegExp _ALPHABETS = new RegExp('[a-zA-Z]');
  static Map<bool, String> _boolToString = new Map.fromEntries(
    <MapEntry<bool, String>>[
      MapEntry<bool, String>(true, 'T'),
      MapEntry<bool, String>(false, 'F')
    ],
  );
  TextField _statementField;
  final TextEditingController _statementController =
      new TextEditingController();
  List<String> _savedStatements = <String>[];

  @override
  void initState() {
    super.initState();
    _statementField = new TextField(
      controller: _statementController,
      keyboardType: TextInputType.text,
      inputFormatters: [
        new WhitelistingTextInputFormatter(RegExp("[a-zA-Z¬∧∨→↔\(\)]"))
      ],
      autocorrect: false,
      onSubmitted: (String str) => _saveCard(_statementController.text),
    );
    prefSave.then((prefs) {
      _savedStatements = prefs.getStringList('_savedStatements');
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text('Truth Table Constructor'),
        actions: <Widget>[
          // TODO: Options for different boolean representation
        ],
      ),
      body: new Container(
        padding: const EdgeInsets.all(16.0),
        child: new Column(
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Expanded(child: _statementField),
                new IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _saveCard(_statementController.text)),
              ],
            ),
            new Row(
              children: _buildTextButtonExpandedList(
                  <String>['¬', '∧', '∨', '→', '↔', '(', ')']),
            ),
            new Expanded(
              child: new ListView.builder(
                itemCount: _savedStatements.length,
                itemBuilder: (context, index) {
                  if (_savedStatements.length == 0 ||
                      index >= _savedStatements.length) {
                    return null;
                  } else {
                    return new Dismissible(
                      key: Key(_savedStatements[index]),
                      child: new ListTile(
                        contentPadding: const EdgeInsets.all(0.0),
                        title: new Hero(
                          tag: "CARD_" + _savedStatements[index],
                          child: new Card(
                            shape: new RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: new FlatButton(
                              shape: new RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: new Hero(
                                tag: _savedStatements[index],
                                child: new Text(_savedStatements[index]),
                              ),
                              onPressed: () {
                                try {
                                  _getTable(_savedStatements[index]);
                                } catch (e) {
                                  Scaffold.of(context).showSnackBar(
                                    new SnackBar(
                                      // TODO: Test Error Message
                                      content: new Text(e.toString()),
                                    ),
                                  );
                                  setState(() {
                                    _savedStatements.removeAt(index);
                                    prefSave.then((prefs) {
                                      prefs.setStringList(
                                          '_savedStatements', _savedStatements);
                                    });
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      onDismissed: (direction) {
                        debugPrint('Card ${index.toString()} dismissed');
                        setState(() {
                          _savedStatements.removeAt(index);
                          prefSave.then((prefs) {
                            prefs.setStringList(
                                '_savedStatements', _savedStatements);
                          });
                        });
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _getTable(String statement) {
    // TODO: Customize Hero Animation to fix render issues
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (BuildContext context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Hero(
                tag: statement,
                child: new Text(statement),
              ),
            ),
            body: new Container(
              padding: _ALL_INSETS_4,
              child: new ListView(
                children: <Widget>[
                  new ListTile(
                    contentPadding: const EdgeInsets.all(0.0),
                    title: new SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: new Hero(
                        tag: "CARD_" + statement,
                        child: new Card(
                          child: _construct(statement),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DataTable _construct(String statement) {
    List<String> _varList = <String>[];
    const List<String> _blacklist = <String>[
      '',
      'true',
      'false',
      'True',
      'False'
    ];

    bool _evaluate(String subStatement, Map<String, bool> values) {
      String _varOn(Direction dir, String str, int index) {
        int step = (dir == Direction.left) ? -1 : 1;
        int i = index + step;
        while (i >= 0 && i < str.length && str[i].contains(_ALPHABETS)) {
          i += step;
        }
        return (dir == Direction.left)
            ? subStatement.substring(i + 1, index)
            : subStatement.substring(index + 1, i);
      }

      if (subStatement.contains('(') && subStatement.contains(')')) {
        int l = subStatement.indexOf('(');
        int r = -1, i = l + 1;
        while (r == -1) {
          if (subStatement[i] == '(') {
            l = i;
          } else if (subStatement[i] == ')') {
            r = i;
            break;
          }
          i++;
        }
        return _evaluate(
            subStatement.substring(0, l) +
                _evaluate(subStatement.substring(l + 1, r), values).toString() +
                subStatement.substring(r + 1),
            values);
      } else if (subStatement.contains('(') || subStatement.contains(')')) {
        throw FormatException('Bracket');
      } else {
        // Replace All {
        int i = subStatement.indexOf(_ALPHABETS);
        for (i = 0; i < subStatement.length; i++) {
          String v = '';
          while (
              i < subStatement.length && subStatement[i].contains(_ALPHABETS)) {
            v += subStatement[i++];
          }
          if (!_blacklist.contains(v)) {
            i = i - v.length + 1;
            subStatement = subStatement.replaceFirst(v, values[v] ? '+' : '-');
          }
        }
        subStatement =
            subStatement.replaceAll('True', '+').replaceAll('False', '-');
        subStatement =
            subStatement.replaceAll('+', 'true').replaceAll('-', 'false');
        // } Replace All
        debugPrint(subStatement);
        String o;
        String p;
        // NOT
        while (subStatement.contains('¬')) {
          subStatement = subStatement.replaceAll('¬true', 'false');
          subStatement = subStatement.replaceAll('¬false', 'true');
        }
        // AND
        while (subStatement.contains('∧')) {
          i = subStatement.indexOf('∧');
          o = '';
          p = _varOn(Direction.left, subStatement, i) +
              '∧' +
              _varOn(Direction.right, subStatement, i);
          switch (p) {
            case 'true∧true':
              o = 'true';
              break;
            case 'true∧false':
            case 'false∧true':
            case 'false∧false':
              o = 'false';
              break;
            default:
              throw FormatException();
          }
          subStatement = subStatement.replaceFirst(p, o);
        }
        // OR
        while (subStatement.contains('∨')) {
          i = subStatement.indexOf('∨');
          o = '';
          p = _varOn(Direction.left, subStatement, i) +
              '∨' +
              _varOn(Direction.right, subStatement, i);
          switch (p) {
            case 'true∨true':
            case 'true∨false':
            case 'false∨true':
              o = 'true';
              break;
            case 'false∨false':
              o = 'false';
              break;
            default:
              throw FormatException();
          }
          subStatement = subStatement.replaceFirst(p, o);
        }
        // IMPLICATION
        while (subStatement.contains('→')) {
          i = subStatement.indexOf('→');
          o = '';
          p = _varOn(Direction.left, subStatement, i) +
              '→' +
              _varOn(Direction.right, subStatement, i);
          switch (p) {
            case 'true→true':
              o = 'true';
              break;
            case 'true→false':
              o = 'false';
              break;
            case 'false→true':
            case 'false→false':
              o = 'true';
              break;
            default:
              throw FormatException();
          }
          subStatement = subStatement.replaceFirst(p, o);
        }
        // BICONDITIONAL
        while (subStatement.contains('↔')) {
          i = subStatement.indexOf('↔');
          o = (_varOn(Direction.left, subStatement, i) ==
                  _varOn(Direction.right, subStatement, i))
              .toString();
          p = _varOn(Direction.left, subStatement, i) +
              '↔' +
              _varOn(Direction.right, subStatement, i);
          subStatement = subStatement.replaceFirst(p, o);
        }
        debugPrint(subStatement);
        if (<String>['true', 'false'].contains(subStatement)){
          return subStatement == 'true' ? true : false;
        } else {
          throw FormatException();
        }
      }
    }

    DataRow _rowBuilder(Map<String, bool> values, bool result) {
      List<DataCell> varList = <DataCell>[];
      for (bool val in values.values) {
        varList.add(
          new DataCell(
            new Container(
              padding: _VERT_INSETS_4,
              child: new Text(
                _boolToString[val],
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      varList.add(
        new DataCell(
          new Container(
            padding: _VERT_INSETS_4,
            child: new Text(
              _boolToString[result],
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      return new DataRow(cells: varList);
    }

    List<DataRow> _iterate(int index, Map<String, bool> values) {
      List<DataRow> table = <DataRow>[];
      if (index == _varList.length) {
        table.add(_rowBuilder(values, _evaluate(statement, values)));
      } else {
        Map<String, bool> val = values;
        val[_varList[index]] = true;
        table.addAll(_iterate(index + 1, val));
        val[_varList[index]] = false;
        table.addAll(_iterate(index + 1, val));
      }
      return table;
    }

    List<DataColumn> _headerBuilder() {
      List<DataColumn> varList = <DataColumn>[];
      for (String val in _varList) {
        varList.add(
          new DataColumn(
            label: new Text(
              val,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      varList.add(
        new DataColumn(
          label: new Text(
            statement,
            textAlign: TextAlign.center,
          ),
        ),
      );
      return varList;
    }

    // Find all variable names from statement
    int i = -1;
    while (i < statement.lastIndexOf(_ALPHABETS)) {
      i = statement.indexOf(_ALPHABETS, i + 1);
      if (i == -1) {
        break;
      }
      String variable = '';
      while (i < statement.length && statement[i].contains(_ALPHABETS)) {
        variable += statement[i++];
      }
      if (!(_blacklist.contains(variable) || _varList.contains(variable))) {
        _varList.add(variable);
      }
    }
    if (_varList == <String>[]) {
      throw FormatException();
    }

    // Build DataTable for return
    List<DataRow> tableRows = <DataRow>[];
    tableRows.addAll(
      _iterate(
        0,
        new Map.fromIterable(
          _varList,
          key: (item) => item as String,
          value: (item) => false,
        ),
      ),
    );
    return new DataTable(
      rows: tableRows,
      columns: _headerBuilder(),
    );
  }

  void _saveCard(String statement) {
    if (!_savedStatements.contains(statement) && statement != '') {
      setState(() {
        _savedStatements.add(statement);
        prefSave.then((prefs) {
          prefs.setStringList('_savedStatements', _savedStatements);
        });
        debugPrint('$statement added to cards');
        debugPrint(_savedStatements.toString());
      });
    }
  }

  Widget _buildTextButtonExpanded(String buttonText) {
    return new Expanded(
      child: new FlatButton(
        shape: new RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: new Text(
          buttonText,
          textAlign: TextAlign.center,
          style: new TextStyle(
            height: 1.6,
            fontSize: 16.0,
          ),
        ),
        onPressed: () {
          setState(() {
            TextSelection selection = _statementController.selection;
            _statementController.text =
                selection.textBefore(_statementController.text) +
                    buttonText +
                    selection.textAfter(_statementController.text);
            _statementController.selection = new TextSelection(
              baseOffset: selection.baseOffset + 1,
              extentOffset: selection.extentOffset + 1,
            );
          });
        },
      ),
    );
  }

  List<Widget> _buildTextButtonExpandedList(List<String> buttonTexts) {
    List<Widget> list = <Widget>[];
    for (String s in buttonTexts) {
      list.add(_buildTextButtonExpanded(s));
    }
    return list;
  }
}