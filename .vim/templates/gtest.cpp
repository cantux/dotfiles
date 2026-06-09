// Google Test skeleton -- call a function and check its result.
//
// Build (gtest from `brew install googletest`; -lgtest_main gives you main()):
//   g++ -std=c++20 -Wall -Wextra -g THIS_FILE.cpp \
//       -I/opt/homebrew/include -L/opt/homebrew/lib \
//       -lgtest -lgtest_main -pthread -o test && ./test

#include <gtest/gtest.h>

// --- function under test (replace, or #include your solution instead) ---
int add(int a, int b) { return a + b; }

// TEST(Suite, Name) -- one named case. EXPECT_* is non-fatal (keeps going).
TEST(AddTest, Basics) {
    EXPECT_EQ(add(2, 3), 5);
    EXPECT_EQ(add(-1, 1), 0);
}

// ASSERT_* is fatal: stops THIS test on failure (not the whole run).
TEST(AddTest, Negatives) {
    ASSERT_EQ(add(-2, -3), -5);
}

// Common checks:
//   EXPECT_EQ / NE / LT / LE / GT / GE        compare two values
//   EXPECT_TRUE / FALSE                       a bool
//   EXPECT_NEAR(a, b, eps) / FLOAT_EQ / DOUBLE_EQ
//   EXPECT_THROW(stmt, ExType) / EXPECT_NO_THROW(stmt)
//   ASSERT_* = same names, but abort the current test on failure
