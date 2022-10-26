`define TESTINGVARS logic test_fail; int test; int fails

`define BEGINTESTING test = 0; fails = 0

`define TESTBEGIN(name) \
test = test + 1; \
$display("[%7d] Test %0d: %s", $time, test, name); \
test_fail = 0 \

`define ASSERT(cond, message) \
assert(cond) else begin \
  test_fail = 1; \
  if (message != "") begin \
    $display("[%7d] Test %0d: FAIL (%s)", $time, test, message); \
  end else $display("[%7d] Test %0d: FAIL", $time, test); \
end \

`define TESTEND \
if (!test_fail) $display("[%7d] Test %0d: PASS", $time, test); \
else fails = fails + 1 \

`define ENDTESTING \
if (fails != 0) $display("[%7d] %0d tests failed.", $time, fails); \
else $display("[%7d] All tests passed.", $time) \
