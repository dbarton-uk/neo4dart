import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:unittest/src/utils.dart' as utils;
import 'utils.dart';

class MakedownConfiguration extends SimpleConfiguration {
  
  RandomAccessFile _markdownRAF;
  String failedImg = '![Failed](./failed.png)';
  String passedImg = '![Passed](./passed.png)';
  String notImplImg = '![Passed](./notimpl.png)';
  List<String> _headers;
  String _groupName;
  
  MakedownConfiguration(String markdownFilePath, [List<String> this._headers]) : super() {
    groupSep = ' : ';
    File markdownFile = new File(Platform.pathSeparator + markdownFilePath);
    markdownFile.open(mode: FileMode.WRITE).then((RandomAccessFile f) {
      _markdownRAF = f;
    });
  }

  String formatResult(TestCase testCase) {
    var result = new StringBuffer();
    if (_groupName == null || _groupName != testCase.currentGroup) {
      _groupName = testCase.currentGroup;
      result.write('###$_groupName  \n');
      result.write("  \n");
    }
    if (testCase.message != NOT_YET_IMPLEMENTED) {
      result.write(testCase.passed ? passedImg : failedImg);
      result.write(' ${testCase.description}');
    }
    else {
      result.write(notImplImg);
      result.write(' ${testCase.description}');
    }
    result.write("\n");

    if (testCase.message != '') {
      result.write(utils.indent(testCase.message));
      result.write("\n");
    }

    return result.toString();
  }

  void onInit() {
    super.onInit();
    filterStacks = formatStacks = true;
  }
  
  void onDone(bool success) {
    int status;
    try {
      super.onDone(success);
      status = 0;
    } catch (ex) {
      // A non-zero exit code is used by the test infrastructure to detect
      // failure.
      status = 1;
    }
    Future.wait([_markdownRAF.close(), stdout.close(), stderr.close()]).then((_) {
      exit(status);
    });
  }
  
  void onSummary(int passed, int failed, int errors, List<TestCase> results, String uncaughtError) {
    // Print headers if exist
    if (_headers != null) {
      _headers.forEach((String header) {
        print(header);
        _markdownRAF.writeStringSync(header+'  \n');
      });
    }
    // Print each test's result.
    for (final t in results) {
      String result = formatResult(t).trim()+ '  \n';
      print(result);
      _markdownRAF.writeStringSync(result);
    }

    // Show the summary.
    print('');
    _markdownRAF.writeStringSync('  \n');

    if (passed == 0 && failed == 0 && errors == 0 && uncaughtError == null) {
      print('No tests found.');
      _markdownRAF.writeStringSync('No tests found.  \n');
      // This is considered a failure too.
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      print('All $passed tests passed.');
      _markdownRAF.writeStringSync('All $passed tests passed.  \n');
    } else {
      if (uncaughtError != null) {
        print('Top-level uncaught error: $uncaughtError');
        _markdownRAF.writeStringSync('Top-level uncaught error: $uncaughtError  \n');
      }
      print('$passed PASSED, $failed FAILED, $errors ERRORS');
      _markdownRAF.writeStringSync('$passed PASSED, $failed FAILED, $errors ERRORS  \n');
    }
  }
}