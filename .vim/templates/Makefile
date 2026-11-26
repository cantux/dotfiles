CXX      := g++
CXXFLAGS := -std=c++20 -Wall -Wextra -g -D_GLIBCXX_ASSERTIONS
LDLIBS   := $(shell pkg-config --libs gtest_main) -pthread
TARGET   := main
SRCS     := $(wildcard *.cpp)
HDRS     := $(wildcard *.h)

WARN_LEVEL   := 1
WARN_FLAGS_1 := -Wpedantic -Wshadow -Wnon-virtual-dtor
WARN_FLAGS_2 := $(WARN_FLAGS_1) -Wold-style-cast -Wcast-align \
                -Woverloaded-virtual -Wconversion -Wsign-conversion \
                -Wnull-dereference -Wdouble-promotion -Wformat=2 \
                -Wimplicit-fallthrough
WARN_FLAGS_3 := -Weverything -Wno-c++98-compat -Wno-c++98-compat-pedantic \
                -Wno-padded -Wno-global-constructors
TIDY_CHECKS  := -*,clang-analyzer-*,bugprone-*,performance-*,modernize-*, \
                google-*,cppcoreguidelines-*,misc-include-cleaner, \
                -modernize-use-trailing-return-type,-google-readability-todo, \
                -modernize-use-ranges, \
                -cppcoreguidelines-pro-bounds-avoid-unchecked-container-access

all: $(TARGET)

$(TARGET): $(SRCS) $(HDRS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS) $(LDLIBS)

$(TARGET).asan: SANITIZE := -fsanitize=address,undefined -fno-sanitize-recover=all
$(TARGET).tsan: SANITIZE := -fsanitize=thread
$(TARGET).asan $(TARGET).tsan: $(SRCS) $(HDRS)
	$(CXX) $(CXXFLAGS) -O1 -fno-omit-frame-pointer $(SANITIZE) \
	  -o $@ $(SRCS) $(LDLIBS)

test: $(TARGET)
	timeout 10 ./$(TARGET)

asan: $(TARGET).asan
	timeout 60 ./$(TARGET).asan

tsan: $(TARGET).tsan
	timeout 60 ./$(TARGET).tsan

valgrind: $(TARGET)
	timeout 120 valgrind --quiet --error-exitcode=1 --leak-check=full ./$(TARGET)

helgrind: $(TARGET)
	timeout 300 valgrind --tool=helgrind --quiet --error-exitcode=1 ./$(TARGET)

format-check:
	clang-format --dry-run --Werror $(SRCS) $(HDRS)

warnings:
	$(CXX) $(CXXFLAGS) $(WARN_FLAGS_$(WARN_LEVEL)) -Werror -O2 \
	  -o /dev/null $(SRCS) $(LDLIBS)

clang-tidy:
	clang-tidy -quiet --checks='$(TIDY_CHECKS)' --warnings-as-errors='*' \
	  $(SRCS) -- $(CXXFLAGS)

cppcheck:
	cppcheck --quiet --error-exitcode=1 --inline-suppr --std=c++20 \
	  --enable=warning,style,performance,portability $(SRCS)

cpplint:
	cpplint --quiet --filter=-legal/copyright,-build/include_subdir,-whitespace \
	  $(SRCS) $(HDRS)

check: format-check warnings clang-tidy cppcheck cpplint test asan tsan valgrind

clean:
	rm -f $(TARGET) $(TARGET).asan $(TARGET).tsan

.PHONY: all test asan tsan valgrind helgrind format-check warnings clang-tidy \
        cppcheck cpplint check clean
